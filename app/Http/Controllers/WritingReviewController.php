<?php

namespace App\Http\Controllers;

use App\Models\AttemptAnswer;
use App\Models\AttemptType;
use App\Models\Mock;
use App\Services\MockResultService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Writing review queue (Admin): AI band + feedback per task, confirm / adjust / re-run AI.
 */
class WritingReviewController extends Controller
{
    public function __construct(private readonly MockResultService $results) {}

    public function index(Request $request): Response
    {
        $this->authorize('examine', Mock::class);

        $status = in_array($request->query('status'), ['pending', 'reviewed', 'all'], true) ? $request->query('status') : 'pending';
        $mockId = $request->integer('mock_id') ?: null;

        $query = AttemptType::query()
            ->with(['attempt.mockStudent' => fn ($q) => $q->withoutEagerLoads(), 'attempt.mock' => fn ($q) => $q->withoutEagerLoads(), 'reviewer:id,name'])
            ->whereHas('type', fn ($q) => $q->where('name', 'Writing'))
            ->whereHas('attempt', fn ($q) => $q->whereNotNull('mock_id')->when($mockId, fn ($w) => $w->where('mock_id', $mockId)))
            ->where(fn ($q) => $q->where('is_submitted', true)->orWhereHas('attempt', fn ($a) => $a->whereNotNull('finished_at')))
            ->when($status === 'pending', fn ($q) => $q->whereNull('reviewed_at'))
            ->when($status === 'reviewed', fn ($q) => $q->whereNotNull('reviewed_at'))
            ->orderBy($status === 'reviewed' ? 'reviewed_at' : 'finished_at', $status === 'reviewed' ? 'desc' : 'asc');

        $page = $query->paginate(15)->withQueryString();

        $items = collect($page->items())->map(function (AttemptType $type) {
            $essays = $this->essays($type);

            return [
                'id' => $type->id,
                'attempt_id' => $type->attempt_id,
                'candidate' => $type->attempt?->mockStudent?->name ?? $type->attempt?->name,
                'code' => $type->attempt?->mockStudent?->code,
                'mock' => $type->attempt?->mock?->name,
                'finished_at' => $type->finished_at,
                'ai_band' => $this->results->computedWritingBand($type),
                'band' => $type->reviewed_at ? $this->results->writingBand($type) : null,
                'reviewed_at' => $type->reviewed_at,
                'reviewer' => $type->reviewer?->name,
                'ai_pending' => $essays->contains(fn ($e) => $e['ai_pending']),
                'essays' => $essays,
            ];
        });

        return Inertia::render('writing-review/index', [
            'items' => $items,
            'pagination' => [
                'current_page' => $page->currentPage(),
                'last_page' => $page->lastPage(),
                'total' => $page->total(),
                'links' => $page->linkCollection(),
            ],
            'pendingAi' => $this->pendingAiCount(),
            'mocks' => Mock::query()->withoutEagerLoads()->whereHas('attempts')->orderByDesc('started_at')->limit(50)->get(['id', 'name']),
            'filters' => ['status' => $status, 'mock_id' => $mockId],
        ]);
    }

    /**
     * Confirm the Writing band, optionally after adjusting task bands or the module band.
     */
    public function confirm(Request $request, AttemptType $attemptType): RedirectResponse
    {
        $this->authorize('examine', Mock::class);
        abort_unless($attemptType->type?->name === 'Writing', 404);

        $data = $request->validate([
            'scores' => ['nullable', 'array'],
            'scores.*' => ['nullable', 'numeric', 'min:0', 'max:9', 'multiple_of:0.5'],
            'band' => ['nullable', 'numeric', 'min:0', 'max:9', 'multiple_of:0.5'],
        ]);

        // An explicit module band is the Admin's own decision; otherwise the band is computed from the task
        // bands, which needs a submitted module and no essay still waiting for its AI band.
        $manualBand = isset($data['band']) && $data['band'] !== null;
        if (! $manualBand) {
            $submitted = $attemptType->is_submitted || $attemptType->attempt?->finished_at !== null;
            if (! $submitted) {
                return back()->with('error', __('writing_not_submitted'));
            }

            $given = collect((array) ($data['scores'] ?? []))->filter(fn ($score) => $score !== null)->keys()->map(fn ($id) => (int) $id)->all();
            $pending = $this->essayQuery($attemptType)
                ->whereNull('score')
                ->whereRaw('LENGTH(answer_text) > 10')
                ->pluck('attempt_answers.id')
                ->map(fn ($id) => (int) $id)
                ->diff($given);
            if ($pending->isNotEmpty()) {
                return back()->with('error', __('writing_ai_pending'));
            }
        }

        DB::transaction(function () use ($attemptType, $data, $request) {
            $essayIds = $this->essayQuery($attemptType)->pluck('attempt_answers.id')->map(fn ($id) => (int) $id)->all();

            foreach ((array) ($data['scores'] ?? []) as $answerId => $score) {
                if ($score === null || ! in_array((int) $answerId, $essayIds, true)) {
                    continue;
                }
                AttemptAnswer::whereKey($answerId)->update(['score' => $score]);
            }

            $attemptType->recalculateIsCorrectCount();

            $band = isset($data['band']) && $data['band'] !== null
                ? (float) $data['band']
                : $this->results->computedWritingBand($attemptType);

            $attemptType->forceFill([
                'score' => $band,
                'reviewed_at' => now(),
                'reviewed_by' => $request->user()->id,
            ])->save();
        });

        return back()->with('success', __('writing_confirmed'));
    }

    private function essayQuery(AttemptType $type)
    {
        return AttemptAnswer::query()
            ->whereHas('attempt_part', fn ($q) => $q->where('attempt_id', $type->attempt_id)
                ->whereHas('part.test_type', fn ($t) => $t->where('type_id', $type->type_id)))
            ->whereHas('question.section.question_type', fn ($q) => $q->where('type', 'essay'));
    }

    /**
     * @return Collection<int, array<string, mixed>>
     */
    private function essays(AttemptType $type)
    {
        return $this->essayQuery($type)
            ->with(['question' => fn ($q) => $q->withoutEagerLoads()->with(['section' => fn ($s) => $s->withoutEagerLoads()->select('id', 'part_id', 'textarea')])])
            ->orderBy('attempt_part_id')
            ->orderBy('question_id')
            ->get()
            ->values()
            ->map(function (AttemptAnswer $answer, int $i) {
                $text = (string) $answer->answer_text;
                $note = (string) $answer->review_note_ai;

                return [
                    'id' => $answer->id,
                    'task' => $i + 1,
                    'prompt' => $answer->question?->section?->textarea,
                    'text' => $text,
                    'words' => trim($text) === '' ? 0 : count(preg_split('/\s+/u', trim($text))),
                    'score' => $answer->score !== null ? (float) $answer->score : null,
                    'feedback' => $note !== '' ? $note : null,
                    'ai_pending' => $answer->score === null && mb_strlen($text) > 10,
                ];
            });
    }

    private function pendingAiCount(): int
    {
        return AttemptAnswer::query()
            ->whereNull('score')
            ->whereRaw('LENGTH(answer_text) > 10')
            ->whereHas('question.section.question_type', fn ($q) => $q->where('type', 'essay'))
            ->whereHas('attempt_part.attempt', fn ($q) => $q->whereNotNull('mock_id'))
            ->count();
    }
}
