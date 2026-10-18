<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Laravel\Socialite\Facades\Socialite;

class GithubAuthController extends Controller
{
    public function redirect()
    {
        return Socialite::driver('github')->redirect();
    }

    public function callback()
    {
        try {
            $githubUser = Socialite::driver('github')->user();
            $email = $githubUser->getEmail();

            // Never match on a null email: that would log the visitor into the first
            // account without an email (e.g. a Telegram-only user).
            $user = User::where('github_id', $githubUser->getId())->first();
            if (! $user && $email) {
                $user = User::where('email', $email)->first();
            }

            if (! $user) {
                $user = User::create([
                    'name' => $githubUser->getName() ?? $githubUser->getNickname() ?? 'GitHub user',
                    'email' => $email,
                    'github_id' => $githubUser->getId(),
                    'avatar' => $githubUser->getAvatar(),
                    'username' => SocialUsername::unique($githubUser->getNickname()),
                ]);
                $user->assignRole('Student');
            } else {
                $user->forceFill([
                    'github_id' => $githubUser->getId(),
                    'avatar' => $user->avatar ?: $githubUser->getAvatar(),
                ])->saveQuietly();
            }

            Auth::login($user, true);

            return redirect()->route('dashboard');
        } catch (\Throwable $exception) {
            Log::warning('GitHub login failed: '.$exception->getMessage());

            return redirect()->route('login')->with('error', __('error.social_login_failed'));
        }
    }
}
