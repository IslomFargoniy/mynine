<?php

namespace App\Policies;

use App\Models\User\User;
use App\Policies\Concerns\ChecksCenter;

/**
 * The website's user list (students) belongs to the platform: SuperAdmin only (Gate::before).
 * A center's Admin manages the Reception staff of their own center.
 */
class UserPolicy
{
    use ChecksCenter;

    public function viewAny(User $user): bool
    {
        return false;
    }

    public function view(User $user, User $model): bool
    {
        return $this->isOwnStaff($user, $model);
    }

    public function create(User $user): bool
    {
        return false;
    }

    public function update(User $user, User $model): bool
    {
        return $this->isOwnStaff($user, $model);
    }

    /**
     * Users are never deleted by center Admins (staff are suspended instead).
     */
    public function delete(User $user, User $model): bool
    {
        return false;
    }

    public function restore(User $user, User $model): bool
    {
        return false;
    }

    public function forceDelete(User $user, User $model): bool
    {
        return false;
    }

    /**
     * Staff page: list, create, edit and suspend the Reception users of the Admin's center.
     */
    public function manageStaff(User $user): bool
    {
        return $user->isCenterAdmin();
    }

    protected function isOwnStaff(User $user, User $model): bool
    {
        return $user->isCenterAdmin()
            && $model->isReception()
            && $this->inCenter($user, $model->owner_id);
    }
}
