<?php

namespace App\Observers;

use App\Models\Folder;
use Illuminate\Support\Facades\Auth;

class FolderObserver
{
    /**
     * Handle the Folder "created" event.
     */
    public function created(Folder $folder): void
    {
        //
    }

    /**
     * Handle the Folder "updated" event.
     */
    public function updating(Folder $folder): void
    {
        //
    }

    /**
     * Handle the Folder "deleted" event.
     */
    public function deleting(Folder $folder): void
    {

        if ($folder->tests()->exists()) {
            throw new \Exception('Cannot delete Folder with associated Tests');
        }

        $authUser = Auth::user();

        // Agar tizim/seeder yoki admin bo'lsa -> ruxsat
        if (! $authUser || $authUser->hasRole('Admin')) {
            return;
        }

        if ($authUser->id !== $folder->user_id) {
            throw new \Exception('You are not allowed to access this page');
        }
    }

    /**
     * Handle the Folder "restored" event.
     */
    public function restored(Folder $folder): void
    {
        //
    }

    /**
     * Handle the Folder "force deleted" event.
     */
    public function forceDeleted(Folder $folder): void
    {
        //
    }
}
