<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Models\CenterSetting;
use App\Models\Device;
use App\Models\Scopes\CenterScope;
use App\Services\ExamService;
use App\Support\CurrentCenter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class DeviceController extends Controller
{
    public function __construct(
        private readonly ExamService $exam,
        private readonly CurrentCenter $center,
    ) {}

    /**
     * POST /device/register — create the PC or rotate its token (same machine_id).
     * Only someone who knows the center password can register a PC. `center_code` picks the center; without
     * it (clients before multi-center) the PC registers to the Mynine center.
     */
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'machine_id' => ['required', 'string', 'max:191'],
            'center_code' => ['nullable', 'string', 'max:32'],
            'password' => ['nullable', 'string', 'max:255'],
            'name' => ['nullable', 'string', 'max:100'],
            'os_version' => ['nullable', 'string', 'max:191'],
            'app_version' => ['nullable', 'string', 'max:40'],
        ]);

        $settings = filled($data['center_code'] ?? null)
            ? CenterSetting::findByCode($data['center_code'])
            : $this->center->settings($this->center->mynineId());

        if (! $settings) {
            throw ApiException::unprocessable('invalid_center_code', 'Unknown center code.');
        }

        if (! $settings->hasExitPassword()) {
            throw ApiException::conflict('setup_password_missing', 'The center password is not set yet. Set the center password in Desktop settings first.');
        }

        if (! $settings->checkExitPassword((string) ($data['password'] ?? ''))) {
            throw ApiException::unprocessable('invalid_password', 'Wrong center password.');
        }

        if ($settings->isSuspended()) {
            throw new ApiException(403, 'center_suspended', 'This center is suspended. Contact the platform administrator.');
        }

        // machine_id is unique across centers: a PC moving to another center keeps its row.
        $device = Device::withoutGlobalScope(CenterScope::class)->firstOrNew(['machine_id' => $data['machine_id']]);

        if ($device->exists && $device->is_blocked) {
            throw new ApiException(403, 'device_blocked', 'This PC is blocked. Contact the administrator.');
        }

        $name = trim((string) ($data['name'] ?? ''));

        if ($device->exists && (int) $device->owner_id !== (int) $settings->owner_id) {
            // Moved to another center: its number and running exam belonged to the old one.
            $device->forceFill(['number' => null, 'current_attempt_id' => null]);
        }
        $device->forceFill(['owner_id' => $settings->owner_id]);

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
            // Lets a not-yet-approved (or later blocked) PC still verify the center password offline.
            'exit_password_offline' => $settings->exit_password_offline,
            'center' => $this->centerInfo($settings),
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

        if (! $this->settingsOf($this->device($request))?->checkExitPassword($data['password'])) {
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
        $settings = $this->settingsOf($device);
        $bg = $settings?->backgroundInfo();

        return response()->json($device->publicInfo() + [
            'exit_password_offline' => $settings?->exit_password_offline,
            'banned_processes' => array_values(config('desktop.banned_processes', [])),
            'heartbeat_seconds' => (int) config('desktop.heartbeat_seconds', 20),
            'violation_batch_seconds' => (int) config('desktop.violation_batch_seconds', 10),
            'server_time' => ExamService::apiTime(),
            // Code-screen background picture (null: the plain default).
            'background_url' => $bg ? route('api.v1.device.background') : null,
            'background_sha256' => $bg['sha256'] ?? null,
            // The PC's center (name and logo for the code screen).
            'center' => $settings ? $this->centerInfo($settings) : null,
        ]);
    }

    /**
     * GET /device/background — the code-screen background picture.
     */
    public function background(Request $request): BinaryFileResponse
    {
        $bg = $this->settingsOf($this->device($request))?->backgroundInfo() ?? throw ApiException::notFound('No background picture is set.');

        return response()->file(Storage::disk('local')->path($bg['path']));
    }

    private function device(Request $request): Device
    {
        return $request->attributes->get('device');
    }

    private function settingsOf(Device $device): ?CenterSetting
    {
        return $device->owner_id ? $this->center->settings((int) $device->owner_id) : null;
    }

    /**
     * @return array{code: string, name: string, logo_url: ?string, suspended: bool}
     */
    private function centerInfo(CenterSetting $settings): array
    {
        return [
            'code' => $settings->code,
            'name' => $settings->name,
            'logo_url' => $settings->logoUrl(),
            'suspended' => $settings->isSuspended(),
        ];
    }
}
