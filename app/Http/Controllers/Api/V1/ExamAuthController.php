<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\MockStudent;
use App\Services\ExamService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

class ExamAuthController extends Controller
{
    public function __construct(private readonly ExamService $exam) {}

    /**
     * POST /exam/login — candidate code → exam token bound to this PC.
     */
    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'code' => ['required', 'string', 'max:64'],
        ]);

        /** @var Device $device */
        $device = $request->attributes->get('device');
        $device->ensureApproved();
        $code = strtoupper(trim($data['code']));

        $student = MockStudent::with('mock')->where('code', $code)->first();
        if (! $student) {
            throw ApiException::unprocessable('invalid_code', 'This code was not found.');
        }

        $mock = $student->mock;
        if (! $mock || (int) $mock->active !== 1) {
            throw ApiException::unprocessable('mock_not_active', 'This mock exam is not active.');
        }

        if ($mock->started_at && now()->lt(Carbon::parse($mock->started_at))) {
            throw ApiException::unprocessable('mock_not_started', 'This mock exam has not started yet.', [
                'starts_at' => Carbon::parse($mock->started_at)->toIso8601String(),
            ]);
        }

        if ($mock->finished_at && now()->gt(Carbon::parse($mock->finished_at))) {
            throw ApiException::unprocessable('mock_finished', 'This mock exam has already finished.');
        }

        if ($student->attempt?->finished_at) {
            throw ApiException::conflict('attempt_finished', 'You have already completed this exam.');
        }

        $expiresAt = $mock->finished_at
            ? Carbon::parse($mock->finished_at)->addHour()
            : now()->addHours((int) config('desktop.token_fallback_hours', 6));

        [$attempt, $token] = DB::transaction(function () use ($student, $device, $expiresAt) {
            $student->forceFill([
                'attended' => true,
                'checked_in_at' => $student->checked_in_at ?? now(),
            ])->save();

            $attempt = $this->exam->findOrCreateMockAttempt($student, ['device_id' => $device->id]);
            if (! $attempt) {
                throw ApiException::unprocessable('mock_not_active', 'This mock exam has no modules.');
            }

            $attempt->forceFill(['device_id' => $device->id])->save();
            $device->forceFill(['current_attempt_id' => $attempt->id, 'last_seen_at' => now()])->save();

            // One PC at a time: logging in elsewhere invalidates every previous exam token.
            $student->tokens()->delete();
            $token = $student->createToken('exam:device:'.$device->id, ['exam'], $expiresAt);

            return [$attempt, $token];
        });

        return response()->json([
            'token' => $token->plainTextToken,
            'expires_at' => $expiresAt->toIso8601String(),
            'candidate' => ['id' => $student->id, 'name' => $student->name, 'code' => $student->code],
            'mock' => [
                'id' => $mock->id,
                'name' => $mock->name,
                'starts_at' => $mock->started_at ? Carbon::parse($mock->started_at)->toIso8601String() : null,
                'ends_at' => $mock->finished_at ? Carbon::parse($mock->finished_at)->toIso8601String() : null,
            ],
            'attempt_id' => $attempt->id,
            'server_time' => now()->toIso8601String(),
        ]);
    }

    /**
     * POST /exam/logout — revoke the current exam token.
     */
    public function logout(Request $request): Response
    {
        $request->attributes->get('candidate')->currentAccessToken()?->delete();

        return response()->noContent();
    }
}
