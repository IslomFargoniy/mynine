<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Http\Controllers\Desktop\SettingsController;
use App\Models\Device;
use App\Models\Setting;
use App\Services\ExamService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class DeviceController extends Controller
{
    public function __construct(private readonly ExamService $exam) {}

    /**
     * POST /device/register — create the PC or rotate its token (same machine_id).
     * Only someone who knows the center-wide desktop password can register a PC.
     */
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'machine_id' => ['required', 'string', 'max:191'],
            'password' => ['nullable', 'string', 'max:255'],
            'name' => ['nullable', 'string', 'max:100'],
            'os_version' => ['nullable', 'string', 'max:191'],
            'app_version' => ['nullable', 'string', 'max:40'],
        ]);

        if (Setting::get(Setting::DESKTOP_EXIT_PASSWORD) === null) {
            throw ApiException::conflict('setup_password_missing', 'The center password is not set yet. Set the center password in Desktop settings first.');
        }

        if (! Setting::checkExitPassword((string) ($data['password'] ?? ''))) {
            throw ApiException::unprocessable('invalid_password', 'Wrong center password.');
        }

        $device = Device::firstOrNew(['machine_id' => $data['machine_id']]);

        if ($device->exists && $device->is_blocked) {
            throw new ApiException(403, 'device_blocked', 'This PC is blocked. Contact the administrator.');
        }

        $name = trim((string) ($data['name'] ?? ''));

        $plainToken = $device->rotateToken();
        // A new token means a new holder: whoever re-registers must be approved again,
        // otherwise knowing an approved PC's machine_id would be enough to take its place.
        // The exam-room number is kept so the admin only has to confirm it.
        $device->fill([
            'is_approved' => false,
            'approved_at' => null,
            'name' => $name !== '' ? $name : ($device->name ?: Device::defaultName($data['machine_id'])),
            'os_version' => $data['os_version'] ?? $device->os_version,
            'app_version' => $data['app_version'] ?? $device->app_version,
            'ip' => $request->ip(),
            'last_seen_at' => now(),
        ])->save();

        return response()->json([
            'device_id' => $device->id,
            'device_token' => $plainToken,
            'name' => $device->name,
            'number' => null,
            'approved' => false,
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
            'server_time' => ExamService::apiTime(),
            'unlock' => $this->exam->consumeUnlock($device->current_attempt_id),
        ] + $device->publicInfo());
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
        $device = $this->device($request);
        $device->ensureApproved();

        return response()->json($device->publicInfo() + [
            'exit_password_offline' => Setting::get(Setting::DESKTOP_EXIT_PASSWORD_OFFLINE),
            'banned_processes' => array_values(config('desktop.banned_processes', [])),
            'heartbeat_seconds' => (int) config('desktop.heartbeat_seconds', 20),
            'violation_batch_seconds' => (int) config('desktop.violation_batch_seconds', 10),
            'server_time' => ExamService::apiTime(),
            // Code-screen background picture (null: the plain default).
            'background_url' => ($bg = SettingsController::background()) ? route('api.v1.device.background') : null,
            'background_sha256' => $bg['sha256'] ?? null,
        ]);
    }

    /**
     * GET /device/background — the code-screen background picture.
     */
    public function background(Request $request): BinaryFileResponse
    {
        $this->device($request);
        $bg = SettingsController::background() ?? throw ApiException::notFound('No background picture is set.');

        return response()->file(Storage::disk('local')->path($bg['path']));
    }

    private function device(Request $request): Device
    {
        return $request->attributes->get('device');
    }
}
