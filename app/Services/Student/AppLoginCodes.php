<?php

namespace App\Services\Student;

use App\Models\User\User;
use Illuminate\Support\Facades\Cache;

/**
 * One-time 6-digit codes the @MynineUzBot sends for signing in to the mobile app. Kept in the cache (no table):
 * a code is valid for TTL seconds, works once, and a new code replaces the user's previous one.
 */
class AppLoginCodes
{
    public const TTL_SECONDS = 300;

    private const CODE_KEY = 'app-login-code:';

    private const USER_KEY = 'app-login-user:';

    public function issue(User $user): string
    {
        $previous = Cache::get(self::USER_KEY.$user->id);
        if ($previous) {
            Cache::forget(self::CODE_KEY.$previous);
        }

        do {
            $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        } while (! Cache::add(self::CODE_KEY.$code, (int) $user->id, self::TTL_SECONDS));

        Cache::put(self::USER_KEY.$user->id, $code, self::TTL_SECONDS);

        return $code;
    }

    /**
     * The user the code belongs to; the code is used up.
     */
    public function consume(string $code): ?User
    {
        if (! preg_match('/^\d{6}$/', $code)) {
            return null;
        }

        $userId = Cache::pull(self::CODE_KEY.$code);
        if (! $userId) {
            return null;
        }

        Cache::forget(self::USER_KEY.$userId);

        return User::find($userId);
    }
}
