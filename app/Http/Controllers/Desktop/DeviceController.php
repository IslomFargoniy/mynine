<?php

namespace App\Http\Controllers\Desktop;

use App\Http\Controllers\Controller;
use App\Models\AppRelease;
use App\Models\Device;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Exam PCs (Admin): approve, block/unblock, rename, delete.
 */
class DeviceController extends Controller
{
    public function index(): Response
    {
        $this->authorize('viewAny', Device::class);

        $online = (int) config('desktop.online_seconds', 60);
        $latest = AppRelease::latestActive()?->version;

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
