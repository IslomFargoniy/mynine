<?php

namespace App\Policies;

use App\Models\Test;
use App\Models\User\User;
use App\Policies\Concerns\ChecksContentOwnership;

class TestPolicy
{
    use ChecksContentOwnership;

    public function viewAny(User $user): bool
    {
        return $this->isContentManager($user);
    }

    public function view(User $user, Test $test): bool
    {
        return $this->ownsTest($user, $test);
    }

    public function create(User $user): bool
    {
        return $this->isContentManager($user);
    }

    public function update(User $user, Test $test): bool
    {
        return $this->ownsTest($user, $test);
    }

    public function delete(User $user, Test $test): bool
    {
        return $this->ownsTest($user, $test);
    }

    /**
     * Whether a user may start an attempt on this test outside of a mock.
     */
    public function attempt(User $user, Test $test): bool
    {
        if ($this->ownsTest($user, $test)) {
            return true;
        }

        return (int) $test->active === 1 && (int) $test->open === 1;
    }
}
