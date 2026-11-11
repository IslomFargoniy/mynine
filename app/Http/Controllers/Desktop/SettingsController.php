<?php

namespace App\Http\Controllers\Desktop;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

/**
 * Desktop settings (Admin), shown as the "Center password" dialog of the Exam PCs page: the center password of the exam app (registering a PC, leaving the
 * locked exam screen, the app's admin menu). Stored under the setting key desktop_exit_password.
 */
class SettingsController extends Controller
{
    /**
     * The settings live in a dialog on the Exam PCs page; ?settings=1 opens it.
     */
    public function index(): RedirectResponse
    {
        Gate::authorize('manage-desktop-settings');

        return redirect()->route('desktop.devices.index', ['settings' => 1]);
    }

    /**
     * Whether the center password is set and when it last changed (for the Exam PCs page).
     *
     * @return array{set: bool, updatedAt: ?string}
     */
    public static function centerPasswordStatus(): array
    {
        $row = Setting::query()->find(Setting::DESKTOP_EXIT_PASSWORD);

        return [
            'set' => $row !== null && $row->value !== null,
            'updatedAt' => $row?->updated_at?->toIso8601String(),
        ];
    }

    public function updateExitPassword(Request $request): RedirectResponse
    {
        Gate::authorize('manage-desktop-settings');

        $data = $request->validate([
            'password' => ['required', 'string', 'min:6', 'max:64', 'confirmed'],
        ]);

        Setting::setExitPassword($data['password']);

        return back()->with('success', __('center_password_saved'));
    }
}
