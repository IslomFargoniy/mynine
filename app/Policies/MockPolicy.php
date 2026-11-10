<?php

namespace App\Policies;

use App\Models\Mock;
use App\Models\User\User;
use App\Policies\Concerns\ChecksContentOwnership;

class MockPolicy
{
    use ChecksContentOwnership;

    public function viewAny(User $user): bool
    {
        return $this->isContentManager($user);
    }

    /**
     * The mock detail page lists every candidate code, so only the owner (or an admin) may open it.
     */
    public function view(User $user, Mock $mock): bool
    {
        return $this->owns($user, $mock);
    }

    public function create(User $user): bool
    {
        return $this->isContentManager($user);
    }

    public function update(User $user, Mock $mock): bool
    {
        return $this->owns($user, $mock);
    }

    public function delete(User $user, Mock $mock): bool
    {
        return $this->owns($user, $mock);
    }

    /**
     * Adding candidates, printing code cards and checking them in (Admin + Reception).
     */
    public function manageStudents(User $user, Mock $mock): bool
    {
        return $this->isStaff($user);
    }

    /**
     * Removing a candidate (Admin only).
     */
    public function deleteStudents(User $user, Mock $mock): bool
    {
        return $user->hasRole('Admin');
    }

    /**
     * Reception desk and live monitor (view), result sheets and delivery (Admin + Reception).
     */
    public function operate(User $user, ?Mock $mock = null): bool
    {
        return $this->isStaff($user);
    }

    /**
     * Monitor actions other than remote unlock, speaking slots and scores, Writing confirmation (Admin).
     */
    public function examine(User $user, ?Mock $mock = null): bool
    {
        return $user->hasRole('Admin');
    }

    protected function isStaff(User $user): bool
    {
        return $user->hasAnyRole(['Admin', 'Reception']);
    }

    protected function owns(User $user, Mock $mock): bool
    {
        return $user->hasRole('Admin') || (int) $mock->user_id === (int) $user->id;
    }
}
