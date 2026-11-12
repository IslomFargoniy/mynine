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

        if ($test->usingMocks()->exists() || $test->attempts()->exists()) {
            throw new \Exception('Cannot delete Test with associated Tests');
        }

        $authUser = Auth::user();

        // System / seeder: allowed; web requests: the policy (center of the record).
        if ($authUser && ! $authUser->can('delete', $test)) {
            throw new \Exception('You are not allowed to access this page');
        }
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
