<?php

namespace App\Jobs;

use App\Models\AttemptType;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\DB;

/**
 * An answer key changed (options.is_correct or questions.answer_text): re-score every submitted module
 * that has an answer to the question. Scores are computed from the live keys (AttemptType::calculateIsCorrectCount).
 */
class RescoreQuestionJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable;

    public int $tries = 3;

    public function __construct(public int $questionId) {}

    public function handle(): void
    {
        $typeId = DB::table('questions')
            ->join('sections', 'sections.id', '=', 'questions.section_id')
            ->join('parts', 'parts.id', '=', 'sections.part_id')
            ->join('test_types', 'test_types.id', '=', 'parts.test_type_id')
            ->where('questions.id', $this->questionId)
            ->value('test_types.type_id');

        if (! $typeId) {
            return;
        }

        $attemptIds = DB::table('attempt_answers')
            ->join('attempt_parts', 'attempt_parts.id', '=', 'attempt_answers.attempt_part_id')
            ->where('attempt_answers.question_id', $this->questionId)
            ->distinct()
            ->pluck('attempt_parts.attempt_id');

        AttemptType::withoutEagerLoads()
            ->whereIn('attempt_id', $attemptIds)
            ->where('type_id', $typeId)
            ->where(fn ($q) => $q->where('is_submitted', true)->orWhereHas('attempt', fn ($a) => $a->whereNotNull('finished_at')))
            ->get()
            ->each(fn (AttemptType $type) => $type->recalculateIsCorrectCount());
    }
}
