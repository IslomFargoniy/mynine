<?php

namespace App\Http\Controllers;

use App\Models\Attempt;
use App\Models\AttemptType;
use App\Models\Part;
use App\Models\TestType;
use App\Services\ExamService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Gate;
use Inertia\Inertia;

class PracticeController extends Controller
{
    public function __construct(private readonly ExamService $exam) {}

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

        if ($error = $this->exam->mockWindowError($attempt)) {
            return back()->with('error', $error);
        }

        $this->exam->autoFinishExpiredTypes($attempt);
        $attempt->load('attempt_types');
        $this->hideResults($attempt);
        $this->useMockModules($attempt);

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

            if ($attempt->paused_at !== null) {
                return back()->with('error', __('exam_paused'));
            }

            $this->exam->finishAttempt($attempt);
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
            if ($attempt->paused_at !== null) {
                return response()->json(['success' => false, 'error' => __('exam_paused')], 409);
            }

            $this->exam->finishTypeWithEvaluation($attempt, $attemptType);
        }

        $fresh = $attemptType->fresh();
        if (! $attempt->fresh()->resultsVisibleTo(Auth::user())) {
            $fresh->hideResults();
        }

        return response()->json([
            'success' => true,
            'message' => 'Test type submitted successfully.',
            'data' => $fresh,
            'server_time' => ExamService::apiTime(),
        ]);
    }

    public function practice_attempt(Attempt $attempt): JsonResponse
    {
        $this->authorize('participate', $attempt);
        $this->exam->autoFinishExpiredTypes($attempt);

        $attempt->load([
            'user:id,name',
            'attempt_types',
            'test' => fn ($q) => $q->with(['types' => fn ($q) => $q->whereHas('parts')]),
        ]);
        $this->hideResults($attempt);
        $this->useMockModules($attempt);

        return response()->json([
            'data' => $attempt,
            'success' => true,
            'message' => 'Attempt retrieved successfully',
            'server_time' => ExamService::apiTime(),
        ]);
    }

    public function practice_test_type(Request $request, TestType $test_type): JsonResponse
    {
        $request->validate(['attempt_id' => 'required|exists:attempts,id']);
        $attempt = Attempt::findOrFail($request->attempt_id);
        $this->authorize('participate', $attempt);
        abort_unless($attempt->allowsTestType($test_type), 403);

        $this->exam->autoFinishExpiredTypes($attempt);

        $test_type->load('parts');
        $test_type->parts->each(fn (Part $part) => $this->exam->hideAnswerKeys($part));

        return response()->json([
            'data' => $test_type,
            'success' => true,
            'message' => 'Test type retrieved successfully',
            'server_time' => ExamService::apiTime(),
        ]);
    }

    public function practice_part(Request $request, Part $part): JsonResponse
    {
        $request->validate(['attempt_id' => 'required|exists:attempts,id']);
        $attempt = Attempt::findOrFail($request->attempt_id);
        $this->authorize('participate', $attempt);

        abort_unless($attempt->allowsPart($part), 403);

        $this->exam->autoFinishExpiredTypes($attempt);

        $attemptPart = $this->exam->startPart($attempt, $part);

        $part = Part::with([
            'test_type',
            'attempt_part' => fn ($q) => $q->where('attempt_id', $attempt->id),
            'sections.questions.options',
            'sections.questions.attempt_answer' => fn ($q) => $q->where('attempt_part_id', $attemptPart->id)->with('attempt_answer_options'),
        ])->findOrFail($part->id);

        $this->exam->hideAnswerKeys($part);

        return response()->json([
            'data' => $part,
            'success' => true,
            'message' => 'Part retrieved successfully',
            'server_time' => ExamService::apiTime(),
        ]);
    }

    /**
     * Scores of finished modules stay hidden while the exam is running (graders excepted).
     */
    private function hideResults(Attempt $attempt): void
    {
        if (! $attempt->resultsVisibleTo(Auth::user())) {
            $attempt->attempt_types->each(fn (AttemptType $type) => $type->hideResults());
        }
    }

    /**
     * Module mocks pick modules from several tests: show those instead of attempts.test_id's modules.
     */
    private function useMockModules(Attempt $attempt): void
    {
        if ($attempt->moduleTestTypeIds() === null || ! $attempt->test) {
            return;
        }

        $attempt->test->setRelation('types', $attempt->moduleTestTypes());
    }
}
