<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreAttemptAnswerRequest;
use App\Jobs\EvaluateEssayJob;
use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\AttemptPart;
use App\Models\Option;
use Illuminate\Http\JsonResponse;

class AttemptAnswerController extends Controller
{
    /**
     * Save (or overwrite) the candidate's answer for one question.
     */
    public function store(StoreAttemptAnswerRequest $request): JsonResponse
    {
        $attempt = Attempt::findOrFail($request->attempt_id);
        $this->authorize('participate', $attempt);

        $attemptPart = AttemptPart::with(['part.test_type.type'])
            ->where('part_id', $request->part_id)
            ->where('attempt_id', $attempt->id)
            ->firstOrFail();

        $attemptType = $attempt->attempt_types
            ->firstWhere('type_id', $attemptPart->part->test_type->type_id);

        if ($attemptType && $attemptType->finished_at && $attemptType->finished_at < now()) {
            if (! $attemptType->is_submitted) {
                $attemptType->finish();
                foreach ($attempt->essayAnswersForEvaluation($attemptType->type_id) as $answer) {
                    EvaluateEssayJob::dispatch($answer->id);
                }
            }

            return response()->json([
                'success' => false,
                'error' => 'Time is up for this test type! You cannot submit answers. ⏰',
            ], 422);
        }

        // The question must belong to the part being answered
        $question = \App\Models\Question::with('section.question_type')->findOrFail($request->question_id);
        abort_unless((int) $question->section->part_id === (int) $attemptPart->part_id, 422, 'Question does not belong to this part.');

        $attemptAnswer = AttemptAnswer::updateOrCreate(
            ['attempt_part_id' => $attemptPart->id, 'question_id' => $question->id],
            ['answer_text' => $request->answer_text]
        );

        if (is_array($request->options)) {
            $attemptAnswer->attempt_answer_options()->delete();

            $isMultiple = $question->section->question_type->type === 'multiple_response';
            $optionIds = $isMultiple ? $request->options : array_slice($request->options, 0, 1);

            $options = Option::whereIn('id', $optionIds)->where('question_id', $question->id)->get()->keyBy('id');
            foreach ($optionIds as $optionId) {
                $option = $options->get($optionId);
                if (! $option) {
                    continue;
                }
                $attemptAnswer->attempt_answer_options()->create([
                    'option_id' => $option->id,
                    'is_correct' => $option->is_correct ? 1 : 0,
                ]);
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Attempt answer saved ✅',
            'data' => [
                'attempt_answer_id' => $attemptAnswer->id,
                'question_id' => $attemptAnswer->question_id,
                'answer_text' => $attemptAnswer->answer_text,
            ],
        ]);
    }

    /**
     * Re-trigger AI essay evaluation (teachers / admins).
     */
    public function reEvaluateAi(AttemptAnswer $attemptAnswer)
    {
        $attempt = $attemptAnswer->attempt_part?->attempt;
        abort_unless($attempt, 404);
        $this->authorize('grade', $attempt);

        if (empty($attemptAnswer->answer_text) || mb_strlen($attemptAnswer->answer_text) < 10) {
            return back()->with('error', 'Insho matni yetarli emas.');
        }

        EvaluateEssayJob::dispatch($attemptAnswer->id);

        return back()->with('success', 'AI baholash jarayoni boshlandi! Tez orada natija yangilanadi.');
    }
}
