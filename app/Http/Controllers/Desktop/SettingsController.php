<?php

namespace App\Http\Controllers\Desktop;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

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

    /**
     * The exam app's background picture (code screen), or null.
     *
     * @return array{path: string, sha256: string, updatedAt: ?string}|null
     */
    public static function background(): ?array
    {
        $row = Setting::query()->find(Setting::DESKTOP_BACKGROUND);
        $data = $row?->value ? json_decode($row->value, true) : null;
        if (! is_array($data) || empty($data['path']) || ! Storage::disk('local')->exists($data['path'])) {
            return null;
        }

        return ['path' => $data['path'], 'sha256' => (string) ($data['sha256'] ?? ''), 'updatedAt' => $row->updated_at?->toIso8601String()];
    }

    public function updateBackground(Request $request): RedirectResponse
    {
        Gate::authorize('manage-desktop-settings');

        $request->validate([
            'image' => ['required', 'file', 'mimes:jpg,jpeg,png,webp', 'max:8192'],
        ]);

        $file = $request->file('image');
        $sha = hash_file('sha256', $file->getRealPath());
        $path = $file->storeAs('desktop', 'background-'.Str::substr($sha, 0, 12).'.'.$file->extension(), 'local');

        $old = self::background();
        Setting::set(Setting::DESKTOP_BACKGROUND, json_encode(['path' => $path, 'sha256' => $sha]));
        if ($old && $old['path'] !== $path) {
            Storage::disk('local')->delete($old['path']);
        }

        return back()->with('success', __('desktop_background_saved'));
    }

    public function destroyBackground(): RedirectResponse
    {
        Gate::authorize('manage-desktop-settings');

        if ($old = self::background()) {
            Storage::disk('local')->delete($old['path']);
        }
        Setting::set(Setting::DESKTOP_BACKGROUND, null);

        return back()->with('success', __('desktop_background_removed'));
    }

    /** Preview for the Exam PCs page. */
    public function showBackground(): Response
    {
        Gate::authorize('manage-desktop-settings');
        $bg = self::background() ?? abort(404);

        return response()->file(Storage::disk('local')->path($bg['path']), ['Cache-Control' => 'private, no-cache']);
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
