<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Laravel\Socialite\Facades\Socialite;

class GoogleAuthController extends Controller
{
    public function redirect()
    {
        return Socialite::driver('google')->redirect();
    }

    public function callback()
    {
        try {
            $googleUser = Socialite::driver('google')->user();
            $email = $googleUser->getEmail();

            if (! $email) {
                throw new \RuntimeException('Google account has no email');
            }

            $byGoogle = User::where('google_id', $googleUser->getId())->first();
            $byEmail = User::where('email', $email)->first();

            // A center account handed to a new person (Centers → Replace admin) has the new email and no
            // google_id: the person signing in with that email gets it, even if their Google account was linked
            // to another (student) account before; that link moves to the center account.
            if ($byEmail && $byEmail->isStaff() && $byGoogle && (int) $byGoogle->id !== (int) $byEmail->id) {
                $byGoogle->forceFill(['google_id' => null])->saveQuietly();
                $byGoogle = null;
            }

            $user = $byGoogle ?? $byEmail;

            if (! $user) {
                $user = User::create([
                    'name' => $googleUser->getName() ?: 'Google user',
                    'email' => $email,
                    'email_verified_at' => now(),
                    'google_id' => $googleUser->getId(),
                    'avatar' => $googleUser->getAvatar(),
                    'username' => SocialUsername::unique(explode('@', $email)[0]),
                ]);
                $user->assignRole('Student');
            } else {
                $user->forceFill([
                    'google_id' => $googleUser->getId(),
                    'avatar' => $user->avatar ?: $googleUser->getAvatar(),
                    'email_verified_at' => $user->email_verified_at ?? now(),
                ])->saveQuietly();
            }

            Auth::login($user, true);

            return redirect()->route('dashboard');
        } catch (\Throwable $exception) {
            Log::warning('Google login failed: '.$exception->getMessage());

            return redirect()->route('login')->with('error', __('error.social_login_failed'));
        }
    }
}
