<?php

namespace App\Http\Controllers\Desktop;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Desktop settings (Admin): the center password of the exam app (registering a PC, leaving the
 * locked exam screen, the app's admin menu). Stored under the setting key desktop_exit_password.
 */
class SettingsController extends Controller
{
    public function index(): Response
    {
        Gate::authorize('manage-desktop-settings');

        $row = Setting::query()->find(Setting::DESKTOP_EXIT_PASSWORD);

        return Inertia::render('desktop/settings', [
            'exitPasswordSet' => $row !== null && $row->value !== null,
            'exitPasswordUpdatedAt' => $row?->updated_at?->toIso8601String(),
        ]);
    }

    public function updateExitPassword(Request $request): RedirectResponse
    {
        Gate::authorize('manage-desktop-settings');

        $data = $request->validate([
            'password' => ['required', 'string', 'min:6', 'max:64', 'confirmed'],
        ]);

        Setting::setExitPassword($data['password']);

        return back()->with('success', 'Markaz paroli saqlandi. Kompyuterlar keyingi ulanishda yangi parolni oladi.');
    }
}
