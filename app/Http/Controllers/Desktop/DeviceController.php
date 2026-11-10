<?php

namespace App\Http\Controllers\Desktop;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Services\Desktop\ReleaseManifest;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
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
            ->orderBy('is_approved')
            ->orderBy('name')
            ->get()
            ->map(fn (Device $d) => [
                'id' => $d->id,
                'name' => $d->name,
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

    public function approve(Device $device): RedirectResponse
    {
        $this->authorize('update', $device);

        $device->approve();

        return back()->with('success', "\"{$device->name}\" tasdiqlandi.");
    }

    public function block(Device $device): RedirectResponse
    {
        $this->authorize('update', $device);

        $device->forceFill(['is_blocked' => true])->save();

        return back()->with('success', "\"{$device->name}\" bloklandi.");
    }

    public function unblock(Device $device): RedirectResponse
    {
        $this->authorize('update', $device);

        $device->forceFill(['is_blocked' => false])->save();

        return back()->with('success', "\"{$device->name}\" blokdan chiqarildi.");
    }

    public function update(Request $request, Device $device): RedirectResponse
    {
        $this->authorize('update', $device);

        $data = $request->validate(['name' => ['required', 'string', 'max:100']]);
        $device->forceFill(['name' => $data['name']])->save();

        return back()->with('success', 'Nomi saqlandi.');
    }

    public function destroy(Device $device): RedirectResponse
    {
        $this->authorize('delete', $device);

        $device->delete();

        return back()->with('success', "Kompyuter o'chirildi.");
    }
}
