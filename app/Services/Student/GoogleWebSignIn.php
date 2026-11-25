<?php

namespace App\Services\Student;

use App\Models\User\User;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

/**
 * Google sign-in for the apps through the browser (fallback when the Android account sheet fails, e.g. an
 * OAuth client / signing key mismatch): the website signs in with Google and hands the app a one-time token
 * in mynine://auth, which the app swaps for an API token (POST /student/auth/google/exchange).
 */
class GoogleWebSignIn
{
    public const TTL_SECONDS = 300;

    private const KEY = 'app-google-token:';

    public function issue(User $user): string
    {
        $token = Str::random(48);
        Cache::put(self::KEY.$token, (int) $user->id, self::TTL_SECONDS);

        return $token;
    }

    /**
     * The user the token belongs to; the token is used up.
     */
    public function consume(string $token): ?User
    {
        if (! preg_match('/^[A-Za-z0-9]{48}$/', $token)) {
            return null;
        }

        $userId = Cache::pull(self::KEY.$token);

        return $userId ? User::find($userId) : null;
    }
}
