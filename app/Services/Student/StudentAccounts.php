<?php

namespace App\Services\Student;

use App\Http\Controllers\Auth\SocialUsername;
use App\Models\User\User;
use Illuminate\Support\Str;

/**
 * Finds or creates the student account behind a mobile sign-in (Google ID token, Google web sign-in, Apple).
 */
class StudentAccounts
{
    public function create(string $name, ?string $email, array $attributes): User
    {
        $user = User::create([
            'name' => $name,
            'email' => $email,
            'username' => SocialUsername::unique($email ? explode('@', $email)[0] : 'user'.Str::lower(Str::random(6))),
        ]);
        $user->forceFill($attributes + ['email_verified_at' => $email ? now() : null])->saveQuietly();
        $user->assignRole('Student');

        return $user;
    }

    /**
     * The account linked to this Google account, else the one with its email, else a new student.
     */
    public function fromGoogle(string $sub, string $email, ?string $name, ?string $picture): User
    {
        $user = User::where('google_id', $sub)->first() ?? User::where('email', $email)->first();

        if (! $user) {
            return $this->create($name ?: 'Google user', $email, ['google_id' => $sub, 'avatar' => $picture]);
        }

        $user->forceFill([
            'google_id' => $user->google_id ?: $sub,
            'avatar' => $user->avatar ?: $picture,
            'email_verified_at' => $user->email_verified_at ?? now(),
        ])->saveQuietly();

        return $user;
    }
}
