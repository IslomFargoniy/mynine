<?php

namespace App\Http\Controllers;

use App\Jobs\EvaluateEssayJob;
use App\Models\Attempt;
use App\Models\AttemptPart;
use App\Models\AttemptType;
use App\Models\Part;
use App\Models\TestType;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Gate;
use Inertia\Inertia;

class PracticeController extends Controller
{
    /**
     * Exam room page.
     */
    public function index(Request $request)
    {
        $request->validate([
            'attempt_id' => 'required|exists:attempts,id',
        ]);

        $attempt = Attempt::with(['user', 'test.types', 'attempt_types', 'mock'])->findOrFail($request->attempt_id);

        if ($attempt->finished_at !== null) {
            return back()->with('error', __('error.attempt_already_finished'));
        }

        if (! Gate::allows('participate', $attempt)) {
            return back()->with('error', __('error.unauthorized_attempt'));
        }

        if ($error = $this->mockWindowError($attempt)) {
            return back()->with('error', $error);
        }

        $this->autoFinishExpiredTypes($attempt->id);
        $attempt->load('attempt_types');

        return Inertia::render('practice/index', [
            'attempt' => $attempt,
        ]);
    }

    /**
     * Finish the whole attempt.
     */
    public function submit(Attempt $attempt)
    {
        $this->authorize('view', $attempt);

        if (! $attempt->finished_at) {
            $this->authorize('participate', $attempt);
            $attempt->finish();
        }

        $isCandidate = session()->has('mock_student_id') || ! Auth::check();
        if ($isCandidate) {
            session()->forget(['mock_student_id', 'mock_attempt_id']);

            return redirect('/')->with('success', __('success.test_submitted'));
        }

        return redirect()->route('attempt.index')->with('success', __('success.test_submitted'));
    }

    /**
     * Tab-switch / focus-loss counter. The client cannot choose the increment.
     */
    public function recordViolation(Attempt $attempt): JsonResponse
    {
        $this->authorize('participate', $attempt);

        $attempt->increment('tab_switch_count');

        return response()->json([
            'success' => true,
            'tab_switch_count' => $attempt->fresh()->tab_switch_count,
        ]);
    }

    /**
     * Finish one module (Listening / Reading / Writing) early.
     */
    public function submit_test_type(Attempt $attempt, int $type_id): JsonResponse
    {
        $this->authorize('participate', $attempt);

        $attemptType = AttemptType::where('attempt_id', $attempt->id)
            ->where('type_id', $type_id)
            ->firstOrFail();

        if (! $attemptType->is_submitted) {
            $this->finishTypeWithEvaluation($attempt, $attemptType);
        }

        return response()->json([
            'success' => true,
            'message' => 'Test type submitted successfully.',
            'data' => $attemptType->fresh(),
            'server_time' => now()->toIso8601String(),
        ]);
    }

    public function practice_attempt(Attempt $attempt): JsonResponse
    {
        $this->authorize('participate', $attempt);
        $this->autoFinishExpiredTypes($attempt->id);

        $attempt->load([
            'user:id,name',
            'attempt_types',
            'test' => fn ($q) => $q->with(['types' => fn ($q) => $q->whereHas('parts')]),
        ]);

        return response()->json([
            'data' => $attempt,
            'success' => true,
            'message' => 'Attempt retrieved successfully',
            'server_time' => now()->toIso8601String(),
        ]);
    }

    public function practice_test_type(Request $request, TestType $test_type): JsonResponse
    {
        $request->validate(['attempt_id' => 'required|exists:attempts,id']);
        $attempt = Attempt::findOrFail($request->attempt_id);
        $this->authorize('participate', $attempt);
        abort_unless((int) $test_type->test_id === (int) $attempt->test_id, 403);

        $this->autoFinishExpiredTypes($attempt->id);

        $test_type->load('parts');
        $test_type->parts->each(fn (Part $part) => $this->hideAnswerKeys($part));

        return response()->json([
            'data' => $test_type,
            'success' => true,
            'message' => 'Test type retrieved successfully',
            'server_time' => now()->toIso8601String(),
        ]);
    }

    public function practice_part(Request $request, Part $part): JsonResponse
    {
        $request->validate(['attempt_id' => 'required|exists:attempts,id']);
        $attempt = Attempt::findOrFail($request->attempt_id);
        $this->authorize('participate', $attempt);

        $part->load(['test_type.test', 'test_type.type']);
        abort_unless((int) $part->test_type->test_id === (int) $attempt->test_id, 403);

        $this->autoFinishExpiredTypes($attempt->id);

        $type = $part->test_type->type;
        if ($type->name === 'Listening' && $part->test_type->test->playtime_seconds) {
            $typeFinishedAt = now()->addSeconds((int) $part->test_type->test->playtime_seconds + 5);
        } else {
            $typeFinishedAt = now()->addMinutes((int) $type->minute);
        }

        $attemptPart = AttemptPart::firstOrCreate(
            ['attempt_id' => $attempt->id, 'part_id' => $part->id],
            ['started_at' => now(), 'finished_at' => now()->addMinutes((int) ($part->minute ?: $type->minute))]
        );

        AttemptType::firstOrCreate(
            ['attempt_id' => $attempt->id, 'type_id' => $part->test_type->type_id],
            ['started_at' => now(), 'finished_at' => $typeFinishedAt]
        );

        $part = Part::with([
            'test_type',
            'attempt_part' => fn ($q) => $q->where('attempt_id', $attempt->id),
            'sections.questions.options',
            'sections.questions.attempt_answer' => fn ($q) => $q->where('attempt_part_id', $attemptPart->id)->with('attempt_answer_options'),
        ])->findOrFail($part->id);

        $this->hideAnswerKeys($part);

        return response()->json([
            'data' => $part,
            'success' => true,
            'message' => 'Part retrieved successfully',
            'server_time' => now()->toIso8601String(),
        ]);
    }

    /**
     * Strip everything a candidate could use to cheat from a part payload and
     * build a neutral, pre-sorted option list for drag-and-drop sections.
     */
    private function hideAnswerKeys(Part $part): void
    {
        foreach ($part->sections as $section) {
            $section->options->each->makeHidden('is_correct');

            if ($section->question_type?->type === 'drag_and_drop') {
                $labels = $section->questions->pluck('answer_text')
                    ->merge($section->options->pluck('textarea'))
                    ->map(fn ($label) => trim((string) $label))
                    ->filter()
                    ->unique(fn ($label) => mb_strtolower($label))
                    ->sort(fn ($a, $b) => strcasecmp($a, $b))
                    ->values();

                $section->setAttribute('drag_options', $labels->map(fn ($label, $i) => [
                    'id' => 'd'.($i + 1),
                    'label' => $label,
                ])->all());
            }

            foreach ($section->questions as $question) {
                $question->makeHidden('answer_text');
                $question->options->each->makeHidden('is_correct');

                if ($question->attempt_answer) {
                    $question->attempt_answer->makeHidden(['is_correct', 'score', 'review_note', 'review_note_ai']);
                    $question->attempt_answer->attempt_answer_options->each(function ($answerOption) {
                        $answerOption->makeHidden('is_correct');
                        $answerOption->option?->makeHidden('is_correct');
                    });
                }
            }
        }
    }

    private function mockWindowError(Attempt $attempt): ?string
    {
        $mock = $attempt->mock;
        if (! $mock) {
            return null;
        }

        return match ($mock->status) {
            'inactive' => 'Ushbu Mock test hozirda faol emas!',
            'scheduled' => 'Ushbu Mock test hali boshlanmagan! Boshlanish vaqti: '.\Carbon\Carbon::parse($mock->started_at)->format('d.m.Y H:i'),
            'expired' => 'Ushbu Mock test vaqti tugagan! Yakunlangan vaqti: '.\Carbon\Carbon::parse($mock->finished_at)->format('d.m.Y H:i'),
            default => null,
        };
    }

    /**
     * Close every module whose timer ran out and queue AI evaluation for its essays.
     */
    private function autoFinishExpiredTypes(int $attemptId): void
    {
        $expired = AttemptType::where('attempt_id', $attemptId)
            ->where('is_submitted', false)
            ->whereNotNull('finished_at')
            ->where('finished_at', '<', now())
            ->get();

        if ($expired->isEmpty()) {
            return;
        }

        $attempt = Attempt::findOrFail($attemptId);
        foreach ($expired as $attemptType) {
            $this->finishTypeWithEvaluation($attempt, $attemptType);
        }
    }

    private function finishTypeWithEvaluation(Attempt $attempt, AttemptType $attemptType): void
    {
        $attemptType->finish();

        foreach ($attempt->essayAnswersForEvaluation($attemptType->type_id) as $answer) {
            EvaluateEssayJob::dispatch($answer->id);
        }
    }
}
