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
     * Adding/removing candidates for a mock.
     */
    public function manageStudents(User $user, Mock $mock): bool
    {
        return $this->owns($user, $mock);
    }

    protected function owns(User $user, Mock $mock): bool
    {
        return $user->hasRole('Admin') || (int) $mock->user_id === (int) $user->id;
    }
}
