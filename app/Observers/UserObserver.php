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
            if (! $authUser->hasRole('Admin') && $authUser->telegram_id !== $user->ref_telegram_id) {
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

        // Agar tizim/seeder yoki admin bo'lsa -> ruxsat
        if (! $authUser || $authUser->hasRole('Admin')) {
            return;
        }

        // Admin bo'lmasa faqat o'z yozuvini yoki o'ziga biriktirilgan talabani o'chirishga ruxsat
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
