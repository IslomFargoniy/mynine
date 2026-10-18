<?php

namespace App\Observers;

use App\Models\Test;
use Illuminate\Support\Facades\Auth;

class TestObserver
{
    /**
     * Handle the Test "created" event.
     */
    public function created(Test $test): void
    {
        //
    }

    /**
     * Handle the Test "updated" event.
     */
    public function updating(Test $test): void
    {
        //
    }

    /**
     * Handle the Test "deleted" event.
     */
    public function deleting(Test $test): void
    {

        if ($test->mocks()->exists() || $test->attempts()->exists()) {
            throw new \Exception('Cannot delete Test with associated Tests');
        }

        $authUser = Auth::user();

        // Agar tizim/seeder yoki admin bo'lsa -> ruxsat
        if (! $authUser || $authUser->hasRole('Admin')) {
            return;
        }

        // Admin bo'lmasa faqat o'z yozuvini o'chirishga ruxsat
        if ($authUser->id !== $test->folder?->user_id) {
            throw new \Exception('You are not allowed to access this page');
        }

        $test->types()->delete();
    }

    /**
     * Handle the Test "restored" event.
     */
    public function restored(Test $test): void
    {
        //
    }

    /**
     * Handle the Test "force deleted" event.
     */
    public function forceDeleted(Test $test): void
    {
        //
    }
}
