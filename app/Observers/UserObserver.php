<?php

namespace App\Observers;

use App\Models\User\User;
use Illuminate\Support\Facades\Auth;

class UserObserver
{
    /**
     * Handle the User "created" event.
     */
    public function created(User $user): void
    {
        //
    }

    /**
     * Handle the User "updated" event.
     */
    public function updating(User $user): void
    {
        $authUser = Auth::user();

        if ($authUser && $authUser->id != $user->id) {
            $isReferrer = $authUser->telegram_id !== null && $authUser->telegram_id === $user->ref_telegram_id;
            if (! $authUser->can('update', $user) && ! $isReferrer) {
                throw new \Exception('You are not allowed to access this page');
            }
        }
    }

    /**
     * Handle the User "deleted" event.
     */
    public function deleting(User $user): void
    {
        $authUser = Auth::user();

        // Centers (Admin users) are never deleted, by anyone.
        if ($user->isCenterAdmin()) {
            throw new \Exception('A center admin cannot be deleted.');
        }

        // System / seeder or the platform owner: allowed
        if (! $authUser || $authUser->isSuperAdmin()) {
            return;
        }

        // Otherwise only one's own record or a student assigned to oneself
        if ($authUser->id !== $user->user_id && $authUser->id !== $user->id) {
            throw new \Exception('You are not allowed to access this page');
        }
    }

    /**
     * Handle the User "restored" event.
     */
    public function restored(User $user): void
    {
        //
    }

    /**
     * Handle the User "force deleted" event.
     */
    public function forceDeleted(User $user): void
    {
        //
    }
}
