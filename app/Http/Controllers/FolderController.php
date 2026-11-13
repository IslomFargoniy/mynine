<?php

namespace App\Http\Controllers;

use App\Support\UserFacingError;
use App\Http\Requests\StoreFolderRequest;
use App\Http\Requests\UpdateFolderRequest;
use App\Models\Folder;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Folder management actions. Folders are listed on the Test Bank page (AllTestController);
 * the old /folder and /folder/{id} URLs redirect there (routes/web.php).
 */
class FolderController extends Controller
{
    public function store(StoreFolderRequest $request)
    {
        $this->authorize('create', Folder::class);

        try {
            Folder::create($request->validated());

            return back()->with('success', __('created_successfully'));
        } catch (\Exception $e) {
            throw ValidationException::withMessages([
                'error' => [UserFacingError::message($e)],
            ]);
        }
    }

    public function update(UpdateFolderRequest $request, Folder $folder)
    {
        $this->authorize('update', $folder);

        try {
            $folder->update($request->validated());

            return back()->with('success', __('updated_successfully'));
        } catch (\Exception $e) {
            throw ValidationException::withMessages([
                'error' => [UserFacingError::message($e)],
            ]);
        }
    }

    public function destroy(Folder $folder)
    {
        $this->authorize('delete', $folder);

        if ($folder->tests()->whereHas('attempts')->exists()) {
            return back()->withErrors(['error' => __('folder_has_attempts')]);
        }

        try {
            DB::transaction(function () use ($folder) {
                foreach ($folder->tests as $test) {
                    $test->delete();
                }
                $folder->delete();
            });

            return back()->with('success', __('deleted_successfully'));
        } catch (\Exception $e) {
            return back()->withErrors(['error' => UserFacingError::message($e)]);
        }
    }
}
