<?php

namespace App\Policies;

use App\Models\Mock;
use App\Models\User\User;
use App\Policies\Concerns\ChecksCenter;

/**
 * Mocks belong to a center (mocks.owner_id). Admin manages the center's mocks; Reception runs the exam day.
 */
class MockPolicy
{
    use ChecksCenter;

    public function viewAny(User $user): bool
    {
        return $user->isCenterAdmin();
    }

    /**
     * The mock detail page lists every candidate code: the center's Admin only.
     */
    public function view(User $user, Mock $mock): bool
    {
        return $this->adminOf($user, $mock->owner_id);
    }

    public function create(User $user): bool
    {
        return $user->isCenterAdmin();
    }

    public function update(User $user, Mock $mock): bool
    {
        return $this->adminOf($user, $mock->owner_id);
    }

    public function delete(User $user, Mock $mock): bool
    {
        return $this->adminOf($user, $mock->owner_id);
    }

    /**
     * Adding candidates, printing code cards and checking them in (Admin + Reception of the mock's center).
     */
    public function manageStudents(User $user, Mock $mock): bool
    {
        return $this->staffOf($user, $mock->owner_id);
    }

    /**
     * Removing a candidate (the center's Admin).
     */
    public function deleteStudents(User $user, Mock $mock): bool
    {
        return $this->adminOf($user, $mock->owner_id);
    }

    /**
     * Reception desk and live monitor (view), result sheets and delivery (Admin + Reception).
     * Without a mock: the page itself (its lists are scoped to the user's center).
     */
    public function operate(User $user, ?Mock $mock = null): bool
    {
        return $mock === null ? $user->isStaff() : $this->staffOf($user, $mock->owner_id);
    }

    /**
     * Monitor actions other than remote unlock, speaking slots and scores, Writing confirmation (Admin).
     */
    public function examine(User $user, ?Mock $mock = null): bool
    {
        return $mock === null ? $user->isCenterAdmin() : $this->adminOf($user, $mock->owner_id);
    }
}
