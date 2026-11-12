<?php

namespace App\Policies\Concerns;

use App\Models\User\User;
use App\Support\CurrentCenter;

/**
 * Record-level center checks. The SuperAdmin passes every ability in Gate::before (AppServiceProvider).
 */
trait ChecksCenter
{
    /**
     * Whether the record's center ($ownerId) is the center the user works for.
     */
    protected function inCenter(User $user, int|string|null $ownerId): bool
    {
        $center = $user->centerId();

        return $ownerId !== null && $center !== null && $center !== CurrentCenter::NONE && (int) $ownerId === $center;
    }

    protected function adminOf(User $user, int|string|null $ownerId): bool
    {
        return $user->isCenterAdmin() && $this->inCenter($user, $ownerId);
    }

    protected function staffOf(User $user, int|string|null $ownerId): bool
    {
        return $user->isStaff() && $this->inCenter($user, $ownerId);
    }
}
