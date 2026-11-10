<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\Setting;
use App\Services\ExamService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    public function __construct(private readonly ExamService $exam) {}

    /**
     * POST /device/register — create the PC or rotate its token (same machine_id).
     */
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'machine_id' => ['required', 'string', 'max:191'],
            'name' => ['required', 'string', 'max:100'],
            'os_version' => ['nullable', 'string', 'max:191'],
            'app_version' => ['nullable', 'string', 'max:40'],
        ]);

        $device = Device::firstOrNew(['machine_id' => $data['machine_id']]);

        if ($device->exists && $device->is_blocked) {
            throw new ApiException(403, 'device_blocked', 'This PC is blocked. Contact the administrator.');
        }

        $plainToken = $device->rotateToken();
        // A new token means a new holder: whoever re-registers must be approved again,
        // otherwise knowing an approved PC's machine_id would be enough to take its place.
        $device->fill([
            'is_approved' => false,
            'approved_at' => null,
            'name' => $data['name'],
            'os_version' => $data['os_version'] ?? $device->os_version,
            'app_version' => $data['app_version'] ?? $device->app_version,
            'ip' => $request->ip(),
            'last_seen_at' => now(),
        ])->save();

        return response()->json([
            'device_id' => $device->id,
            'device_token' => $plainToken,
            'name' => $device->name,
        ]);
    }

    /**
     * POST /device/heartbeat — code-screen presence; delivers a pending remote unlock.
     */
    public function heartbeat(Request $request): JsonResponse
    {
        $data = $request->validate([
            'app_version' => ['nullable', 'string', 'max:40'],
            'state' => ['nullable', 'string', 'in:idle,updating,exam'],
        ]);

        $device = $this->device($request);
        $device->forceFill([
            'app_version' => $data['app_version'] ?? $device->app_version,
            'ip' => $request->ip(),
            'last_seen_at' => now(),
        ])->save();

        return response()->json([
            'server_time' => now()->toIso8601String(),
            'unlock' => $this->exam->consumeUnlock($device->current_attempt_id),
        ]);
    }

    /**
     * POST /device/unlock — verify the center-wide exit password online.
     */
    public function unlock(Request $request): JsonResponse
    {
        $data = $request->validate([
            'password' => ['required', 'string', 'max:255'],
        ]);

        if (! Setting::checkExitPassword($data['password'])) {
            return response()->json(['ok' => false, 'message' => 'Wrong password.', 'code' => 'invalid_password'], 422);
        }

        return response()->json(['ok' => true]);
    }

    /**
     * GET /device/config
     */
    public function config(Request $request): JsonResponse
    {
        $request->attributes->get('device')->ensureApproved();

        return response()->json([
            'exit_password_offline' => Setting::get(Setting::DESKTOP_EXIT_PASSWORD_OFFLINE),
            'banned_processes' => array_values(config('desktop.banned_processes', [])),
            'heartbeat_seconds' => (int) config('desktop.heartbeat_seconds', 20),
            'violation_batch_seconds' => (int) config('desktop.violation_batch_seconds', 10),
            'server_time' => now()->toIso8601String(),
        ]);
    }

    private function device(Request $request): Device
    {
        return $request->attributes->get('device');
    }
}
