<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\ApiException;
use App\Services\Desktop\ExamPayloadBuilder;
use App\Services\ExamService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ExamController extends ExamApiController
{
    public function __construct(ExamService $exam, private readonly ExamPayloadBuilder $payload)
    {
        parent::__construct($exam);
    }

    /**
     * GET /exam — attempt state and modules (Listening, Reading, Writing).
     */
    public function show(Request $request): JsonResponse
    {
        $attempt = $this->attempt($request);
        $this->exam->autoFinishExpiredTypes($attempt, $this->graceSeconds());

        return response()->json([
            'attempt' => [
                'id' => $attempt->id,
                'status' => $attempt->finished_at ? 'completed' : 'in_progress',
                'paused' => $attempt->paused_at !== null,
                'finished' => $attempt->finished_at !== null,
            ],
            'modules' => $this->payload->modules($attempt, $this->modules($attempt)),
            'server_time' => $this->serverTime(),
        ]);
    }

    /**
     * GET /exam/prefetch — everything needed offline; starts no timer.
     */
    public function prefetch(Request $request): JsonResponse
    {
        $attempt = $this->attempt($request);
        $this->ensureNotFinished($attempt);

        return response()->json(
            $this->payload->prefetch($attempt, $this->modules($attempt)) + ['server_time' => $this->serverTime()]
        );
    }

    /**
     * GET /exam/parts/{part}
     */
    public function part(Request $request, int $part): JsonResponse
    {
        $attempt = $this->attempt($request);
        $payload = $this->payload->part($attempt, $part, $this->modules($attempt));

        if ($payload === null) {
            throw ApiException::forbidden('This part is not part of your exam.');
        }

        return response()->json($payload + ['server_time' => $this->serverTime()]);
    }

    /**
     * POST /exam/submit — finish the whole attempt and revoke the exam token. Never returns scores.
     */
    public function submit(Request $request): JsonResponse
    {
        $attempt = $this->attempt($request);

        if ($attempt->finished_at === null) {
            $this->ensureNotPaused($attempt);
            $this->exam->finishAttempt($attempt);
        }

        $request->attributes->get('candidate')->tokens()->delete();

        return response()->json([
            'status' => 'completed',
            'server_time' => $this->serverTime(),
        ]);
    }

    private function extendToken(Request $request): void
    {
        $token = $request->attributes->get('candidate')?->currentAccessToken();
        if (! $token || ! method_exists($token, 'forceFill')) {
            return;
        }

        $until = now()->addHours((int) config('desktop.token_sliding_hours', 2));
        if ($token->expires_at === null || $token->expires_at->lt($until)) {
            $token->forceFill(['expires_at' => $until])->save();
        }
    }

    /**
     * POST /exam/heartbeat — liveness + pause / force-submit / remote-unlock / timer changes.
     */
    public function heartbeat(Request $request): JsonResponse
    {
        $request->validate([
            'type_id' => ['nullable', 'integer'],
            'part_id' => ['nullable', 'integer'],
            'queued_answers' => ['nullable', 'integer', 'min:0'],
            'queued_violations' => ['nullable', 'integer', 'min:0'],
            'online_since' => ['nullable', 'date'],
        ]);

        $attempt = $this->attempt($request);
        $device = $this->device($request);

        // Before the heartbeat moves forward: remember which modules ended while this PC was offline.
        $this->exam->snapshotOfflineAtEnd($attempt);

        $attempt->forceFill(['last_heartbeat_at' => now()])->save();

        // Sliding exam token: keep it valid while the attempt is running.
        if ($attempt->finished_at === null) {
            $this->extendToken($request);
        }
        $device->forceFill(['last_seen_at' => now(), 'ip' => $request->ip()])->save();

        $this->exam->autoFinishExpiredTypes($attempt, $this->graceSeconds());

        return response()->json([
            'server_time' => $this->serverTime(),
            'paused' => $attempt->paused_at !== null,
            'finished' => $attempt->finished_at !== null,
            'unlock' => $this->exam->consumeUnlock($attempt->id),
            'modules' => $this->payload->moduleTimers($attempt, $this->modules($attempt)),
        ]);
    }
}
