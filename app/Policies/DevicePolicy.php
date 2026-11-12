<?php

namespace App\Policies;

use App\Models\Device;
use App\Models\User\User;
use App\Policies\Concerns\ChecksCenter;

/**
 * Exam PCs are managed by the Admin of the center they are registered to.
 */
class DevicePolicy
{
    use ChecksCenter;

    public function viewAny(User $user): bool
    {
        return $user->isCenterAdmin();
    }

    public function update(User $user, Device $device): bool
    {
        return $this->adminOf($user, $device->owner_id);
    }

    public function delete(User $user, Device $device): bool
    {
        return $this->adminOf($user, $device->owner_id);
    }
}
