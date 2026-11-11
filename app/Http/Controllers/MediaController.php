<?php

namespace App\Http\Controllers;

use App\Services\AudioUploadService;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\Response;

class MediaController extends Controller
{
    /**
     * Stream exam audio to authenticated users / candidates only.
     * New uploads live on the private "local" disk; files uploaded before the
     * switch may still sit on the public disk, so both are checked.
     */
    public function audio(string $filename, AudioUploadService $audio): Response
    {
        foreach (['local', 'public'] as $disk) {
            $relative = 'audio/'.$filename;
            if (Storage::disk($disk)->exists($relative)) {
                $path = Storage::disk($disk)->path($relative);

                return $audio->response($path, Storage::disk($disk)->mimeType($relative) ?: 'audio/mpeg');
            }
        }

        abort(404);
    }
}
