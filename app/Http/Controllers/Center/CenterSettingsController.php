<?php

namespace App\Http\Controllers\Center;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Desktop\SettingsController;
use App\Models\CenterAuditLog;
use App\Models\CenterSetting;
use App\Support\CurrentCenter;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Center settings (the center's Admin): name and logo; the code is read-only (set by the SuperAdmin) because
 * exam PCs register with it. The center password and the exam-app background are edited in dialogs here and
 * on the Exam PCs page (desktop.settings.*).
 */
class CenterSettingsController extends Controller
{
    public function __construct(private readonly CurrentCenter $current) {}

    public function edit(): Response
    {
        Gate::authorize('manage-center-settings');
        $settings = $this->settings();

        return Inertia::render('center/settings', [
            'center' => $settings->summary(),
            'centerPassword' => SettingsController::centerPasswordStatus($settings),
            'background' => ($bg = $settings->backgroundInfo()) ? ['sha256' => $bg['sha256'], 'updatedAt' => $bg['updatedAt']] : null,
        ]);
    }

    public function update(Request $request): RedirectResponse
    {
        Gate::authorize('manage-center-settings');
        $settings = $this->settings();

        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'logo' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
        ]);

        $settings->forceFill(['name' => $data['name']]);

        if ($request->hasFile('logo')) {
            $old = $settings->logo_path;
            $settings->logo_path = $request->file('logo')->store('centers/logos', CenterSetting::LOGO_DISK);
            if ($old) {
                Storage::disk(CenterSetting::LOGO_DISK)->delete($old);
            }
        }

        $settings->save();
        CenterAuditLog::record('settings_updated', (int) $settings->owner_id);

        return back()->with('success', __('center_settings_saved'));
    }

    public function destroyLogo(): RedirectResponse
    {
        Gate::authorize('manage-center-settings');
        $settings = $this->settings();

        if ($settings->logo_path) {
            Storage::disk(CenterSetting::LOGO_DISK)->delete($settings->logo_path);
            $settings->forceFill(['logo_path' => null])->save();
        }

        return back()->with('success', __('center_logo_removed'));
    }

    private function settings(): CenterSetting
    {
        return $this->current->settings() ?? abort(404);
    }
}
