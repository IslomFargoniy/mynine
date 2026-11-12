<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\ApiException;
use App\Models\AttemptType;
use App\Services\Desktop\ExamPayloadBuilder;
use App\Services\ExamService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ModuleController extends ExamApiController
{
    public function __construct(ExamService $exam, private readonly ExamPayloadBuilder $payload)
    {
        parent::__construct($exam);
    }

    /**
     * POST /exam/modules/{type_id}/start — idempotent; modules must be taken in order.
     */
    public function start(Request $request, int $typeId): JsonResponse
    {
        $attempt = $this->attempt($request);
        $module = $this->findModule($attempt, $typeId);

        $existing = AttemptType::where('attempt_id', $attempt->id)->where('type_id', $typeId)->first();
        if ($existing) {
            return response()->json($this->payload->moduleTimer($existing) + ['server_time' => $this->serverTime()]);
        }

        $this->ensureNotFinished($attempt);
        $this->ensureNotPaused($attempt);
        $this->exam->autoFinishExpiredTypes($attempt, $this->graceSeconds());

        $submittedTypeIds = AttemptType::where('attempt_id', $attempt->id)->where('is_submitted', true)->pluck('type_id')
            ->map(fn ($id) => (int) $id)->all();

        foreach ($this->modules($attempt) as $earlier) {
            if ((int) $earlier->type_id === $typeId) {
                break;
            }
            if (! in_array((int) $earlier->type_id, $submittedTypeIds, true)) {
                throw ApiException::conflict('module_locked', 'Finish '.$earlier->type->name.' first.');
            }
        }

        $attemptType = $this->exam->startModule($attempt, $module);

        return response()->json($this->payload->moduleTimer($attemptType) + ['server_time' => $this->serverTime()]);
    }

    /**
     * POST /exam/modules/{type_id}/audio-lag {lag_seconds} — Listening audio missed while the app was closed;
     * the app resumes the recording where it stopped and the module ends that much later (total, idempotent).
     */
    public function audioLag(Request $request, int $typeId): JsonResponse
    {
        $data = $request->validate(['lag_seconds' => ['required', 'integer', 'min:0', 'max:7200']]);
        $attempt = $this->attempt($request);
        $module = $this->findModule($attempt, $typeId);
        if ($module->type?->name !== 'Listening') {
            throw ApiException::conflict('not_listening', 'Only the Listening module has an audio recording.');
        }

        $attemptType = AttemptType::where('attempt_id', $attempt->id)->where('type_id', $typeId)->first();
        if (! $attemptType) {
            throw ApiException::conflict('module_locked', 'This module has not been started.');
        }
        $this->ensureNotFinished($attempt);

        $attemptType = $this->exam->extendForAudioLag($attemptType, (int) $data['lag_seconds'], $this->exam->moduleDurationSeconds($module));

        return response()->json($this->payload->moduleTimer($attemptType) + ['server_time' => $this->serverTime()]);
    }

    /**
     * POST /exam/modules/{type_id}/submit — finish the module (queues Writing AI evaluation).
     */
    public function submit(Request $request, int $typeId): JsonResponse
    {
        $attempt = $this->attempt($request);
        $this->findModule($attempt, $typeId);

        $attemptType = AttemptType::where('attempt_id', $attempt->id)->where('type_id', $typeId)->first();
        if (! $attemptType) {
            throw ApiException::conflict('module_locked', 'This module has not been started.');
        }

        if (! $attemptType->is_submitted) {
            $this->ensureNotFinished($attempt);
            $this->ensureNotPaused($attempt);
            $this->exam->finishTypeWithEvaluation($attempt, $attemptType);
        }

        return response()->json([
            'type_id' => $typeId,
            'status' => 'submitted',
            'server_time' => $this->serverTime(),
        ]);
    }
}
