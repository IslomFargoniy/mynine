<?php

namespace App\Observers;

use App\Models\Section;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class SectionObserver
{
    /**
     * Handle the Section "created" event.
     */
    public function created(Section $section): void
    {
        //
    }

    /**
     * Handle the Section "updated" event.
     */
    public function updating(Section $section): void {}

    /**
     * Handle the Section "deleted" event.
     */
    public function deleting(Section $section): void
    {
        $user = Auth::user();
        if ($user && ! $user->hasRole('Admin')) {
            throw new \Exception('Only admins can delete sections.');
        }

        DB::beginTransaction();

        $section->questions()->each(function ($question) {
            // Delete related options first
            $question->options()->delete();

            // Then delete the question itself
            $question->delete();
        });

        DB::commit();

    }

    /**
     * Handle the Section "restored" event.
     */
    public function restored(Section $section): void
    {
        //
    }

    /**
     * Handle the Section "force deleted" event.
     */
    public function forceDeleted(Section $section): void
    {
        //
    }
}
