<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreAttemptAnswerRequest;
use App\Jobs\EvaluateEssayJob;
use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\AttemptPart;
use App\Models\Question;
use App\Services\ExamService;
use Illuminate\Http\JsonResponse;

class AttemptAnswerController extends Controller
{
    public function __construct(private readonly ExamService $exam) {}

    /**
     * Save (or overwrite) the candidate's answer for one question.
     */
    public function store(StoreAttemptAnswerRequest $request): JsonResponse
    {
        $attempt = Attempt::findOrFail($request->attempt_id);
        $this->authorize('participate', $attempt);

        $attemptPart = AttemptPart::with(['part' => fn ($q) => $q->withoutEagerLoads()->with('test_type')])
            ->where('part_id', $request->part_id)
            ->where('attempt_id', $attempt->id)
            ->firstOrFail();

        abort_unless($attempt->allowsPart($attemptPart->part), 403);

        $question = Question::withoutEagerLoads()->findOrFail($request->question_id);

        $result = $this->exam->saveAnswer(
            $attempt,
            $attemptPart,
            $question,
            $request->answer_text,
            is_array($request->options) ? $request->options : null,
        );

        if ($result['status'] === ExamService::REJECTED) {
            return match ($result['reason']) {
                'invalid_question' => abort(422, 'Question does not belong to this part.'),
                'paused' => response()->json([
                    'success' => false,
                    'error' => 'The exam is paused. Please wait.',
                ], 409),
                default => response()->json([
                    'success' => false,
                    'error' => 'Time is up for this test type! You cannot submit answers. ⏰',
                ], 422),
            };
        }

        $attemptAnswer = $result['answer'];

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
     * Re-trigger AI essay evaluation (admins).
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
