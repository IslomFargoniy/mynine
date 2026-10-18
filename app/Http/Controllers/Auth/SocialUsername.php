<?php

namespace App\Http\Controllers\Auth;

use App\Models\User\User;
use Illuminate\Support\Str;

class SocialUsername
{
    /**
     * Build a username that satisfies the unique index on users.username.
     */
    public static function unique(?string $candidate): ?string
    {
        $base = Str::of((string) $candidate)->lower()->replaceMatches('/[^a-z0-9_.-]/', '')->limit(40, '')->toString();
        if ($base === '') {
            return null;
        }

        $username = $base;
        $suffix = 1;
        while (User::where('username', $username)->exists()) {
            $username = $base.'_'.(++$suffix);
        }

        return $username;
    }
}
