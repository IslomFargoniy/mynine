<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\Mock;
use App\Models\MockStudent;
use App\Models\TestType;
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
                'starts_at' => ExamService::apiTime($mock->started_at),
            ]);
        }

        $existing = $student->attempt;
        if ($existing?->finished_at) {
            throw ApiException::conflict('attempt_finished', 'You have already completed this exam.');
        }

        // After the window only a candidate whose exam is still running (e.g. the PC died) may log in again.
        if ($mock->finished_at && now()->gt(Carbon::parse($mock->finished_at)) && ! $existing) {
            throw ApiException::unprocessable('mock_finished', 'This mock exam has already finished.');
        }

        // Another PC is still running this exam: only the invigilator may move it (monitor "Release PC").
        if ($existing && $existing->device_id && (int) $existing->device_id !== (int) $device->id
            && $existing->last_heartbeat_at !== null
            && $existing->last_heartbeat_at->gt(now()->subSeconds((int) config('desktop.active_elsewhere_seconds', 90)))) {
            throw ApiException::conflict(
                'session_active_elsewhere',
                'This exam is running on another PC. Ask the invigilator to release it.',
            );
        }

        $expiresAt = $this->tokenExpiry($student, $mock);

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

            // Any other PC that still points at this attempt loses it (an unlock is never delivered there).
            Device::where('current_attempt_id', $attempt->id)->whereKeyNot($device->id)->update(['current_attempt_id' => null]);

            // One PC at a time: logging in elsewhere invalidates every previous exam token.
            $student->tokens()->delete();
            $token = $student->createToken('exam:device:'.$device->id, ['exam'], $expiresAt);

            return [$attempt, $token];
        });

        return response()->json([
            'token' => $token->plainTextToken,
            'expires_at' => ExamService::apiTime($expiresAt),
            'candidate' => ['id' => $student->id, 'name' => $student->name, 'code' => $student->code],
            'mock' => [
                'id' => $mock->id,
                'name' => $mock->name,
                'starts_at' => ExamService::apiTime($mock->started_at),
                'ends_at' => ExamService::apiTime($mock->finished_at),
            ],
            'attempt_id' => $attempt->id,
            'server_time' => ExamService::apiTime(),
        ]);
    }

    /**
     * Token lifetime: max(mock end, now) + all module durations + 2 h. Extended by /exam/heartbeat.
     */
    private function tokenExpiry(MockStudent $student, Mock $mock): Carbon
    {
        $base = $mock->finished_at ? Carbon::parse($mock->finished_at)->max(now()) : now();

        $durations = $mock->modules()->with(['testType.test', 'testType.type'])->get()
            ->sum(fn ($module) => $module->testType ? $this->exam->moduleDurationSeconds($module->testType) : 0);

        if ($durations === 0 && $mock->test_id) {
            $durations = TestType::with(['test', 'type'])->where('test_id', $mock->test_id)->get()
                ->sum(fn (TestType $tt) => $this->exam->moduleDurationSeconds($tt));
        }

        return $base->copy()->addSeconds((int) $durations)->addHours((int) config('desktop.token_sliding_hours', 2));
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
