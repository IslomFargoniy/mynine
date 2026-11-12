<?php

namespace App\Http\Controllers\Desktop;

use App\Http\Controllers\Controller;
use App\Models\CenterSetting;
use App\Support\CurrentCenter;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

/**
 * Desktop settings of the current center (its Admin), shown as dialogs on the Exam PCs and Center settings
 * pages: the center password of the exam app (registering a PC, leaving the locked exam screen, the app's
 * admin menu) and the code-screen background. Stored per center in center_settings.
 */
class SettingsController extends Controller
{
    public function __construct(private readonly CurrentCenter $current) {}

    /**
     * The settings live in a dialog on the Exam PCs page; ?settings=1 opens it.
     */
    public function index(): RedirectResponse
    {
        Gate::authorize('manage-desktop-settings');

        return redirect()->route('desktop.devices.index', ['settings' => 1]);
    }

    /**
     * Whether the center password is set and when it last changed.
     *
     * @return array{set: bool, updatedAt: ?string}
     */
    public static function centerPasswordStatus(?CenterSetting $settings): array
    {
        return [
            'set' => (bool) $settings?->hasExitPassword(),
            'updatedAt' => $settings?->exit_password_updated_at?->toIso8601String(),
        ];
    }

    public function updateBackground(Request $request): RedirectResponse
    {
        Gate::authorize('manage-desktop-settings');
        $settings = $this->settings();

        $request->validate([
            'image' => ['required', 'file', 'mimes:jpg,jpeg,png,webp', 'max:8192'],
        ]);

        $file = $request->file('image');
        $sha = hash_file('sha256', $file->getRealPath());
        // Per-center file name: two centers uploading the same picture must not share (and delete) one file.
        $path = $file->storeAs('desktop', 'background-'.$settings->owner_id.'-'.Str::substr($sha, 0, 12).'.'.$file->extension(), 'local');

        $old = $settings->backgroundInfo();
        $settings->setBackground($path, $sha);
        if ($old && $old['path'] !== $path) {
            Storage::disk('local')->delete($old['path']);
        }

        return back()->with('success', __('desktop_background_saved'));
    }

    public function destroyBackground(): RedirectResponse
    {
        Gate::authorize('manage-desktop-settings');
        $settings = $this->settings();

        if ($old = $settings->backgroundInfo()) {
            Storage::disk('local')->delete($old['path']);
        }
        $settings->setBackground(null, null);

        return back()->with('success', __('desktop_background_removed'));
    }

    /** Preview for the Exam PCs page. */
    public function showBackground(): Response
    {
        Gate::authorize('manage-desktop-settings');
        $bg = $this->settings()->backgroundInfo() ?? abort(404);

        return response()->file(Storage::disk('local')->path($bg['path']), ['Cache-Control' => 'private, no-cache']);
    }

    public function updateExitPassword(Request $request): RedirectResponse
    {
        Gate::authorize('manage-desktop-settings');
        $settings = $this->settings();

        $data = $request->validate([
            'password' => ['required', 'string', 'min:6', 'max:64', 'confirmed'],
        ]);

        $settings->setExitPassword($data['password']);

        return back()->with('success', __('center_password_saved'));
    }

    private function settings(): CenterSetting
    {
        return $this->current->settings() ?? abort(404);
    }
}
