<?php

namespace App\Jobs;

use App\Models\AttemptAnswer;
use App\Models\AttemptType;
use App\Services\OpenAIService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class EvaluateEssayJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;

    public int $timeout = 120;

    public array $backoff = [5, 20, 60];

    protected $answerId;

    public function __construct($answerId)
    {
        $this->answerId = $answerId;
    }

    public function handle()
    {
        $answer = AttemptAnswer::find($this->answerId);
        if (! $answer) {
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

            $openAIService = new OpenAIService;
            $resultJson = $openAIService->evaluateEssay($task, $question, $essay);

            $data = json_decode($resultJson, true);
            $answer->score = null;

            if ($data && isset($data['overall'])) {
                $answer->score = $data['overall'];

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
            } else {
                $answer->review_note_ai = $resultJson;
            }
            $answer->save();

            // Recalculate is_correct_count for the corresponding attempt_type
            $this->recalculateAttemptTypeScore($answer);

        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error("EvaluateEssayJob error for answer {$this->answerId}: ".$e->getMessage());
            $answer->review_note_ai = 'Baholash jarayonda... (Qayta urinilmoqda: '.$e->getMessage().')';
            $answer->save();
            throw $e;
        }
    }

    /**
     * Handle permanent job failure after maximum retries
     */
    public function failed(\Throwable $exception)
    {
        \Illuminate\Support\Facades\Log::error("EvaluateEssayJob permanently failed for answer {$this->answerId}: ".$exception->getMessage());
        $answer = AttemptAnswer::find($this->answerId);
        if ($answer) {
            $answer->review_note_ai = "Baholashda xatolik yuz berdi (3 marta urinishdan so'ng). Iltimos, qayta baholashni so'rang.";
            $answer->save();
        }
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
