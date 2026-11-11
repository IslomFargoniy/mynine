<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\AttemptPart;
use App\Models\Question;
use App\Services\ExamService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AnswerController extends ExamApiController
{
    /**
     * POST /exam/answers — idempotent batch (client_uuid + last-write-wins by seq / changed_at).
     *
     * v1.1: only a malformed envelope is a 422; every item problem is a per-item `rejected` result.
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'answers' => ['required', 'array', 'min:1', 'max:200'],
            'answers.*' => ['array'],
            'answers.*.client_uuid' => ['required', 'string', 'max:64'],
        ]);

        $attempt = $this->attempt($request);

        // Modules that ended while the PC was offline are recorded before anything else moves.
        $this->exam->snapshotOfflineAtEnd($attempt);

        if ($attempt->finished_at !== null && ! $this->exam->acceptsLateAnswers($attempt)) {
            $this->ensureNotFinished($attempt);
        }

        if ($attempt->finished_at === null) {
            $this->exam->autoFinishExpiredTypes($attempt, $this->graceSeconds());
        }

        // validate() would keep only client_uuid of each item; the items are checked one by one below.
        $items = collect($request->input('answers'))->values();

        // Only parts of started modules have attempt parts; everything else is an invalid question.
        $attemptParts = AttemptPart::where('attempt_id', $attempt->id)
            ->whereIn('part_id', $items->pluck('part_id')->filter(fn ($id) => is_int($id) || ctype_digit((string) $id))->unique())
            ->with(['part' => fn ($q) => $q->withoutEagerLoads()->with('test_type')])
            ->get()
            ->keyBy('part_id');

        $questions = Question::withoutEagerLoads()
            ->with(['section' => fn ($q) => $q->withoutEagerLoads()->with('question_type')])
            ->whereIn('id', $items->pluck('question_id')->filter(fn ($id) => is_int($id) || ctype_digit((string) $id))->unique())
            ->get()
            ->keyBy('id');

        $examTypeIds = $this->modules($attempt)->pluck('id')->map(fn ($id) => (int) $id)->all();

        $results = [];
        $late = [];
        foreach ($items as $item) {
            $uuid = $item['client_uuid'];

            $reason = $this->itemError($item);
            if ($reason !== null) {
                $results[] = ['client_uuid' => $uuid, 'status' => ExamService::REJECTED, 'reason' => $reason];

                continue;
            }

            $attemptPart = $attemptParts->get($item['part_id']);
            $question = $questions->get($item['question_id']);

            if (! $attemptPart || ! $question || ! in_array((int) $attemptPart->part->test_type_id, $examTypeIds, true)) {
                $results[] = ['client_uuid' => $uuid, 'status' => ExamService::REJECTED, 'reason' => 'invalid_question'];

                continue;
            }

            $result = $this->exam->saveAnswer(
                $attempt,
                $attemptPart,
                $question,
                $item['text'] ?? null,
                $item['option_ids'] ?? [],
                Carbon::parse($item['changed_at']),
                $uuid,
                $this->graceSeconds(),
                isset($item['seq']) ? (int) $item['seq'] : null,
            );

            if (! empty($result['late'])) {
                $late[] = $result;
            }

            $results[] = array_filter([
                'client_uuid' => $uuid,
                'status' => $result['status'],
                'reason' => $result['reason'] ?? null,
                'late' => ! empty($result['late']) ? true : null,
            ], fn ($value) => $value !== null);
        }

        if ($late !== []) {
            $this->exam->afterLateSync($late);
        }

        return response()->json([
            'results' => $results,
            'server_time' => $this->serverTime(),
        ]);
    }

    /**
     * Per-item validation: "too_many_options" for an oversized option list, "invalid" for anything else.
     */
    private function itemError(array $item): ?string
    {
        if (isset($item['option_ids']) && is_array($item['option_ids']) && count($item['option_ids']) > 50) {
            return 'too_many_options';
        }

        $validator = Validator::make($item, [
            'part_id' => ['required', 'integer'],
            'question_id' => ['required', 'integer'],
            'text' => ['nullable', 'string', 'max:20000'],
            'option_ids' => ['nullable', 'array'],
            'option_ids.*' => ['integer'],
            'changed_at' => ['required', 'date'],
            'seq' => ['nullable', 'integer', 'min:0'],
        ]);

        return $validator->fails() ? 'invalid' : null;
    }
}
