<?php

namespace App\Jobs;

use App\Models\AiUsageLog;
use App\Models\AttemptAnswer;
use App\Models\AttemptType;
use App\Services\OpenAIService;
use App\Support\AiUsage;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class EvaluateEssayJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;

    public int $timeout = 120;

    public array $backoff = [5, 20, 60];

    protected $answerId;

    /** Re-evaluate even when the essay already has a band (Admin "re-run AI"). */
    protected bool $force;

    public function __construct($answerId, bool $force = false)
    {
        $this->answerId = $answerId;
        $this->force = $force;
    }

    /**
     * AI band of an evaluation: a number clamped to 0–9 and rounded to the nearest half band, or null when
     * the value is not a number.
     */
    public static function normalizeBand(mixed $value): ?float
    {
        if (is_string($value)) {
            $value = trim($value);
        }
        if (! is_numeric($value)) {
            return null;
        }

        $band = max(0.0, min(9.0, (float) $value));

        return round($band * 2) / 2;
    }

    public function handle()
    {
        $answer = AttemptAnswer::find($this->answerId);
        if (! $answer) {
            return;
        }

        // Already evaluated (a duplicate job) unless explicitly re-run.
        if (! $this->force && $answer->score !== null) {
            return;
        }

        // Never overwrite a band confirmed (and possibly adjusted) by an Admin.
        if ($this->moduleReviewed($answer)) {
            return;
        }

        try {
            $task = 'Evaluate the essay';
            $question = $answer->question->section->textarea;
            $essay = $answer->answer_text ?? '';

            // Count words
            $wordCount = empty(trim($essay)) ? 0 : count(preg_split('/\s+/', trim($essay)));
            if ($wordCount < 50) {
                $answer->score = 0.0;
                $answer->review_note_ai = "### IELTS Writing Evaluation\n\n**Overall Band Score:** 0.0\n\n#### Individual Criteria Scores:\n- **Task Response:** 0.0\n- **Coherence & Cohesion:** 0.0\n- **Lexical Resource:** 0.0\n- **Grammatical Range & Accuracy:** 0.0\n\n#### Detailed Feedback:\nYour essay contains only {$wordCount} words. Under IELTS criteria, essays with fewer than 50 words are considered too short to be evaluated and will receive a score of 0. Please write at least 150 words for Task 1 and 250 words for Task 2.";
                $answer->save();
                $this->recalculateAttemptTypeScore($answer);

                return;
            }

            $openAIService = app(OpenAIService::class);
            $resultJson = app(AiUsage::class)->during(
                $this->usageContext($answer),
                fn () => $openAIService->evaluateEssay($task, $question, $essay),
            );

            $data = json_decode((string) $resultJson, true);
            $band = is_array($data) ? self::normalizeBand($data['overall'] ?? null) : null;

            if ($band === null) {
                // Unusable AI output: keep the previous band (and feedback) and let the queue retry.
                throw new \RuntimeException('AI evaluation returned no valid overall band.');
            }

            if ($this->moduleReviewed($answer->fresh())) {
                return;
            }

            $answer->score = $band;
            $data['overall'] = $band;

            $scores = $data['scores'] ?? [];
            $feedback = $data['feedback'] ?? '';

            $formattedReview = "### IELTS Writing Evaluation\n\n";
            $formattedReview .= '**Overall Band Score:** '.$data['overall']."\n\n";
            if (! empty($scores)) {
                $formattedReview .= "#### Individual Criteria Scores:\n";
                $formattedReview .= '- **Task Response:** '.($scores['task_response'] ?? 'N/A')."\n";
                $formattedReview .= '- **Coherence & Cohesion:** '.($scores['coherence_cohesion'] ?? 'N/A')."\n";
                $formattedReview .= '- **Lexical Resource:** '.($scores['lexical_resource'] ?? 'N/A')."\n";
                $formattedReview .= '- **Grammatical Range & Accuracy:** '.($scores['grammatical_range_accuracy'] ?? 'N/A')."\n\n";
            }
            $formattedReview .= "#### Detailed Feedback:\n".$feedback;

            $answer->review_note_ai = trim($formattedReview);
            $answer->save();

            // Recalculate is_correct_count for the corresponding attempt_type
            $this->recalculateAttemptTypeScore($answer);

        } catch (\Throwable $e) {
            Log::error("EvaluateEssayJob error for answer {$this->answerId}: ".$e->getMessage());
            if ($answer->score === null) {
                $answer->review_note_ai = 'Baholash jarayonda... (Qayta urinilmoqda: '.$e->getMessage().')';
                $answer->save();
            }
            throw $e;
        }
    }

    /**
     * Handle permanent job failure after maximum retries
     */
    public function failed(\Throwable $exception)
    {
        Log::error("EvaluateEssayJob permanently failed for answer {$this->answerId}: ".$exception->getMessage());
        $answer = AttemptAnswer::find($this->answerId);
        if ($answer && $answer->score === null) {
            $answer->review_note_ai = "Baholashda xatolik yuz berdi (3 marta urinishdan so'ng). Iltimos, qayta baholashni so'rang.";
            $answer->save();
        }
    }

    /**
     * Usage log context: the center of the mock (practice answers: null = Mynine practice).
     *
     * @return array<string, mixed>
     */
    private function usageContext(AttemptAnswer $answer): array
    {
        $attempt = $answer->attempt_part?->attempt()->withoutGlobalScopes()->first();

        return [
            'owner_id' => $attempt?->centerId(),
            'user_id' => $attempt?->user_id,
            'purpose' => AiUsageLog::PURPOSE_WRITING_EVAL,
            'attempt_answer_id' => $answer->id,
        ];
    }

    private function moduleReviewed(?AttemptAnswer $answer): bool
    {
        $attemptPart = $answer?->attempt_part;
        $typeId = $attemptPart?->part?->test_type?->type_id;
        if (! $attemptPart || ! $typeId) {
            return false;
        }

        return AttemptType::where('attempt_id', $attemptPart->attempt_id)
            ->where('type_id', $typeId)
            ->whereNotNull('reviewed_at')
            ->exists();
    }

    /**
     * Essay baholagandan keyin tegishli attempt_type uchun is_correct_count ni yangilash
     */
    private function recalculateAttemptTypeScore(AttemptAnswer $answer)
    {
        $attemptPart = $answer->attempt_part;
        if (! $attemptPart) {
            return;
        }

        $part = $attemptPart->part;
        if (! $part || ! $part->test_type) {
            return;
        }

        $attemptType = AttemptType::where('attempt_id', $attemptPart->attempt_id)
            ->where('type_id', $part->test_type->type_id)
            ->first();

        if ($attemptType) {
            $attemptType->recalculateIsCorrectCount();
        }
    }
}
