<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

/**
 * Stores exam audio on the private disk and returns the route path the frontend should use.
 */
class AudioUploadService
{
    public const DISK = 'local';

    public const DIRECTORY = 'audio';

    /**
     * @return array{path: string, playtime: float|null}
     */
    public function store(UploadedFile $file, ?string $oldPath = null): array
    {
        $originalName = pathinfo($file->getClientOriginalName(), PATHINFO_FILENAME);
        $originalName = preg_replace('/[^A-Za-z0-9_-]/', '_', $originalName) ?: 'audio';
        $extension = strtolower($file->getClientOriginalExtension() ?: 'mp3');
        $fileName = time().'_'.$originalName.'.'.$extension;

        $relative = $file->storeAs(self::DIRECTORY, $fileName, self::DISK);

        $info = (new \getID3)->analyze(Storage::disk(self::DISK)->path($relative));
        $playtime = $info['playtime_seconds'] ?? null;

        if ($oldPath) {
            $this->delete($oldPath);
        }

        return [
            'path' => 'media/'.$relative,
            'playtime' => $playtime !== null ? (float) $playtime : null,
        ];
    }

    /**
     * Delete a previously stored audio file whatever prefix it was saved with
     * ("media/audio/x.mp3" for private uploads, "storage/audio/x.mp3" for legacy public ones).
     */
    public function delete(?string $storedPath): void
    {
        if (! $storedPath) {
            return;
        }

        $relative = preg_replace('#^(media|storage)/#', '', $storedPath);

        foreach ([self::DISK, 'public'] as $disk) {
            if (Storage::disk($disk)->exists($relative)) {
                Storage::disk($disk)->delete($relative);
            }
        }
    }
}
