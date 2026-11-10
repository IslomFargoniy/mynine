<?php

namespace App\Policies;

use App\Models\AppRelease;
use App\Models\User\User;

/**
 * Desktop installer releases are managed by Admins only.
 */
class AppReleasePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasRole('Admin');
    }

    public function create(User $user): bool
    {
        return $user->hasRole('Admin');
    }

    public function update(User $user, AppRelease $release): bool
    {
        return $user->hasRole('Admin');
    }

    public function delete(User $user, AppRelease $release): bool
    {
        return $user->hasRole('Admin');
    }
}
