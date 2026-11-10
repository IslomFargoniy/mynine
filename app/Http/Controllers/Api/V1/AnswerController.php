<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\AttemptPart;
use App\Models\Question;
use App\Services\ExamService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AnswerController extends ExamApiController
{
    /**
     * POST /exam/answers — idempotent batch (client_uuid + last-write-wins by changed_at).
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'answers' => ['required', 'array', 'min:1', 'max:200'],
            'answers.*.client_uuid' => ['required', 'string', 'max:64'],
            'answers.*.part_id' => ['required', 'integer'],
            'answers.*.question_id' => ['required', 'integer'],
            'answers.*.text' => ['nullable', 'string', 'max:20000'],
            'answers.*.option_ids' => ['nullable', 'array', 'max:50'],
            'answers.*.option_ids.*' => ['integer'],
            'answers.*.changed_at' => ['required', 'date'],
        ]);

        $attempt = $this->attempt($request);
        $this->ensureNotFinished($attempt);
        $this->exam->autoFinishExpiredTypes($attempt, $this->graceSeconds());

        $items = collect($data['answers']);

        // Only parts of started modules have attempt parts; everything else is an invalid question.
        $attemptParts = AttemptPart::where('attempt_id', $attempt->id)
            ->whereIn('part_id', $items->pluck('part_id')->unique())
            ->with(['part' => fn ($q) => $q->withoutEagerLoads()->with('test_type')])
            ->get()
            ->keyBy('part_id');

        $questions = Question::withoutEagerLoads()
            ->with(['section' => fn ($q) => $q->withoutEagerLoads()->with('question_type')])
            ->whereIn('id', $items->pluck('question_id')->unique())
            ->get()
            ->keyBy('id');

        $examTypeIds = $this->modules($attempt)->pluck('id')->map(fn ($id) => (int) $id)->all();

        $results = [];
        foreach ($items as $item) {
            $attemptPart = $attemptParts->get($item['part_id']);
            $question = $questions->get($item['question_id']);

            if (! $attemptPart || ! $question || ! in_array((int) $attemptPart->part->test_type_id, $examTypeIds, true)) {
                $results[] = ['client_uuid' => $item['client_uuid'], 'status' => ExamService::REJECTED, 'reason' => 'invalid_question'];

                continue;
            }

            $result = $this->exam->saveAnswer(
                $attempt,
                $attemptPart,
                $question,
                $item['text'] ?? null,
                $item['option_ids'] ?? [],
                Carbon::parse($item['changed_at']),
                $item['client_uuid'],
                $this->graceSeconds(),
            );

            $results[] = array_filter([
                'client_uuid' => $item['client_uuid'],
                'status' => $result['status'],
                'reason' => $result['reason'] ?? null,
            ], fn ($value) => $value !== null);
        }

        return response()->json([
            'results' => $results,
            'server_time' => $this->serverTime(),
        ]);
    }
}
