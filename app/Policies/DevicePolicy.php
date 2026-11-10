<?php

namespace App\Policies;

use App\Models\Device;
use App\Models\User\User;

/**
 * Exam PCs are managed by Admins only.
 */
class DevicePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasRole('Admin');
    }

    public function update(User $user, Device $device): bool
    {
        return $user->hasRole('Admin');
    }

    public function delete(User $user, Device $device): bool
    {
        return $user->hasRole('Admin');
    }
}
