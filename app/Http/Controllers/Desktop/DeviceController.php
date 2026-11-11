<?php

namespace App\Http\Controllers\Desktop;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Services\Desktop\ReleaseManifest;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Exam PCs (Admin): approve, block/unblock, rename, delete.
 */
class DeviceController extends Controller
{
    public function index(ReleaseManifest $manifest): Response
    {
        $this->authorize('viewAny', Device::class);

        $online = (int) config('desktop.online_seconds', 60);
        $latest = $manifest->latestVersion();
        $release = $manifest->get();
        $installerPath = $release ? public_path('desktop/'.$release['file']) : null;

        $devices = Device::query()
            ->with(['currentAttempt' => fn ($q) => $q->select('id', 'name', 'mock_id', 'mock_student_id', 'finished_at')->with('mock:id,name')])
            // Pending PCs first, then by exam-room number (unnumbered last), then by name.
            ->orderBy('is_approved')
            ->orderByRaw('number is null')
            ->orderBy('number')
            ->orderBy('name')
            ->get()
            ->map(fn (Device $d) => [
                'id' => $d->id,
                'name' => $d->name,
                'number' => $d->number,
                'machine_id' => $d->machine_id,
                'is_approved' => $d->is_approved,
                'approved_at' => $d->approved_at?->toIso8601String(),
                'is_blocked' => $d->is_blocked,
                'app_version' => $d->app_version,
                'outdated' => $latest && $d->app_version && version_compare($d->app_version, $latest, '<'),
                'os_version' => $d->os_version,
                'ip' => $d->ip,
                'last_seen_at' => $d->last_seen_at?->toIso8601String(),
                'online' => $d->last_seen_at !== null && $d->last_seen_at->gt(now()->subSeconds($online)),
                'current_attempt' => $d->currentAttempt && $d->currentAttempt->finished_at === null ? [
                    'id' => $d->currentAttempt->id,
                    'name' => $d->currentAttempt->name,
                    'mock' => $d->currentAttempt->mock?->name,
                ] : null,
                'created_at' => $d->created_at?->toIso8601String(),
            ]);

        return Inertia::render('desktop/devices', [
            'devices' => $devices,
            'latestVersion' => $latest,
            'nextNumber' => Device::nextFreeNumber(),
            'centerPassword' => Gate::allows('manage-desktop-settings') ? SettingsController::centerPasswordStatus() : null,
            'canManageSettings' => Gate::allows('manage-desktop-settings'),
            'background' => Gate::allows('manage-desktop-settings') && ($bg = SettingsController::background())
                ? ['sha256' => $bg['sha256'], 'updatedAt' => $bg['updatedAt']]
                : null,
            // Installer published in public/desktop (served as a static file by nginx).
            'installer' => $release ? [
                'version' => $release['version'],
                'file' => $release['file'],
                'url' => asset('desktop/'.$release['file']),
                'size' => $release['size'],
                'sha256' => $release['sha256'],
                'available' => $installerPath !== null && is_file($installerPath),
            ] : null,
        ]);
    }

    public function approve(Request $request, Device $device): RedirectResponse
    {
        $this->authorize('update', $device);

        $data = $request->validate(['number' => $this->numberRules($device)]);

        $device->approve((int) $data['number']);

        return back()->with('success', __('device_approved', ['name' => $device->name, 'number' => $device->number]));
    }

    public function block(Device $device): RedirectResponse
    {
        $this->authorize('update', $device);

        $device->forceFill(['is_blocked' => true])->save();

        return back()->with('success', __('device_blocked', ['name' => $device->name]));
    }

    public function unblock(Device $device): RedirectResponse
    {
        $this->authorize('update', $device);

        $device->forceFill(['is_blocked' => false])->save();

        return back()->with('success', __('device_unblocked', ['name' => $device->name]));
    }

    public function update(Request $request, Device $device): RedirectResponse
    {
        $this->authorize('update', $device);

        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:100'],
            'number' => ['sometimes', ...$this->numberRules($device)],
        ]);
        $device->forceFill($data)->save();

        return back()->with('success', __('saved'));
    }

    /**
     * Exam-room number: 1..999, unique among all PCs (approved or not).
     *
     * @return array<int, mixed>
     */
    private function numberRules(Device $device): array
    {
        return ['required', 'integer', 'between:1,'.Device::MAX_NUMBER, Rule::unique('devices', 'number')->ignore($device->id)];
    }

    public function destroy(Device $device): RedirectResponse
    {
        $this->authorize('delete', $device);

        $device->delete();

        return back()->with('success', __('device_deleted'));
    }
}
