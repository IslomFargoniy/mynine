<?php

namespace App\Observers;

use App\Models\Mock;
use Illuminate\Support\Facades\Auth;

class MockObserver
{
    /**
     * Handle the Mock "created" event.
     */
    public function created(Mock $mock): void
    {
        //
    }

    /**
     * Handle the Mock "updated" event.
     */
    public function updating(Mock $mock): void
    {
        //
    }

    /**
     * Handle the Mock "deleted" event.
     */
    public function deleting(Mock $mock): void
    {

        if ($mock->attempts()->exists()) {
            throw new \Exception('Cannot delete Mock with associated Attempts');
        }

        $authUser = Auth::user();

        // Agar tizim/seeder yoki admin bo'lsa -> ruxsat
        if (! $authUser || $authUser->hasRole('Admin')) {
            return;
        }

        // Admin bo'lmasa faqat o'z yozuvini o'chirishga ruxsat
        if ($authUser->id !== $mock->user_id) {
            throw new \Exception('You are not allowed to access this page');
        }
    }

    /**
     * Handle the Mock "restored" event.
     */
    public function restored(Mock $mock): void
    {
        //
    }

    /**
     * Handle the Mock "force deleted" event.
     */
    public function forceDeleted(Mock $mock): void
    {
        //
    }
}
