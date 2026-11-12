<?php

namespace App\Support;

use App\Models\User\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Signs a user out everywhere: web sessions (database session driver) and "remember me" cookies.
 */
class UserSessions
{
    public static function invalidate(User $user): void
    {
        if (config('session.driver') === 'database') {
            DB::connection(config('session.connection'))
                ->table(config('session.table', 'sessions'))
                ->where('user_id', $user->id)
                ->delete();
        }

        // A new remember_token makes every "remember me" cookie of the old one invalid.
        $user->forceFill(['remember_token' => Str::random(60)])->saveQuietly();
    }
}
