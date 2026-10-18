<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class MediaController extends Controller
{
    /**
     * Stream exam audio to authenticated users / candidates only.
     * New uploads live on the private "local" disk; files uploaded before the
     * switch may still sit on the public disk, so both are checked.
     */
    public function audio(string $filename): BinaryFileResponse
    {
        foreach (['local', 'public'] as $disk) {
            $relative = 'audio/'.$filename;
            if (Storage::disk($disk)->exists($relative)) {
                $path = Storage::disk($disk)->path($relative);

                return response()->file($path, [
                    'Content-Type' => Storage::disk($disk)->mimeType($relative) ?: 'audio/mpeg',
                    'Cache-Control' => 'private, max-age=86400',
                ]);
            }
        }

        abort(404);
    }
}
