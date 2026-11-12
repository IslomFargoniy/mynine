<?php

namespace App\Http\Controllers\Settings;

use App\Http\Controllers\Controller;
use App\Http\Requests\Settings\ProfileUpdateRequest;
use App\Models\User\User;
use App\Services\Telegram\TelegramLoginVerifier;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Inertia\Inertia;
use Inertia\Response;

class ProfileController extends Controller
{
    /**
     * Show the user's profile settings page.
     */
    public function edit(Request $request): Response
    {
        return Inertia::render('settings/profile', [
            'mustVerifyEmail' => $request->user() instanceof MustVerifyEmail,
            'status' => $request->session()->get('status'),
            'telegramConnected' => $request->user()->telegram_id !== null,
            'telegramBot' => config('services.telegram.mynine_bot_username'),
        ]);
    }

    /**
     * Update the user's profile settings.
     */
    public function update(ProfileUpdateRequest $request): RedirectResponse
    {
        $request->user()->fill($request->validated());

        if ($request->user()->isDirty('email')) {
            $request->user()->email_verified_at = null;
        }

        $request->user()->save();

        return to_route('profile.edit');
    }

    /**
     * "Connect Telegram": the Telegram Login Widget's signed data sets telegram_id of the current user, so they
     * can sign in with Telegram afterwards. A Telegram account already linked to another user is refused (no
     * merging of accounts).
     */
    public function connectTelegram(Request $request, TelegramLoginVerifier $verifier): RedirectResponse
    {
        $data = $request->only(['id', 'first_name', 'last_name', 'username', 'photo_url', 'auth_date', 'hash']);
        $data = array_filter($data, fn ($value) => $value !== null);

        if (! isset($data['id']) || ! $verifier->verifyWidget($data)) {
            return back()->with('error', __('error.invalid_telegram_login'));
        }

        $user = $request->user();
        $telegramId = (string) $data['id'];

        $owner = User::query()->where('telegram_id', $telegramId)->first();
        if ($owner && (int) $owner->id !== (int) $user->id) {
            return back()->with('error', __('telegram_already_linked'));
        }

        $user->forceFill(['telegram_id' => $telegramId])->saveQuietly();

        return back()->with('success', __('telegram_connected'));
    }

    /**
     * Delete the user's account.
     */
    public function destroy(Request $request): RedirectResponse
    {
        $request->validate([
            'password' => ['required', 'current_password'],
        ]);

        $user = $request->user();

        if ($user->isStaff()) {
            return back()->with('error', __('staff_cannot_delete_account'));
        }

        Auth::logout();

        $user->delete();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect('/');
    }
}
