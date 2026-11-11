<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\Response;

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

    /**
     * Absolute filesystem path of a stored audio file ("media/audio/x.mp3" on the private disk or legacy
     * "storage/audio/x.mp3" on the public disk), or null when the file is missing.
     */
    public function absolutePath(?string $storedPath): ?string
    {
        if (! $storedPath) {
            return null;
        }

        $relative = preg_replace('#^/?(media|storage)/#', '', $storedPath);
        if (! str_starts_with($relative, self::DIRECTORY.'/') || str_contains($relative, '..')) {
            return null;
        }

        foreach ([self::DISK, 'public'] as $disk) {
            if (Storage::disk($disk)->exists($relative)) {
                return Storage::disk($disk)->path($relative);
            }
        }

        return null;
    }

    /**
     * Response for a stored audio file. With config desktop.x_accel_audio, files on the private disk are
     * handed to nginx (X-Accel-Redirect to the internal location, nginx answers Range requests itself);
     * otherwise, and for legacy public-disk files, PHP streams the file (BinaryFileResponse supports Range).
     *
     * nginx: location /_protected_audio/ { internal; alias <storage/app/private>/audio/; }
     */
    public function response(string $absolutePath, ?string $contentType = null): Response
    {
        $headers = [
            'Content-Type' => $contentType ?: (mime_content_type($absolutePath) ?: 'audio/mpeg'),
            'Cache-Control' => 'private, max-age=86400',
        ];

        $privateRoot = rtrim(Storage::disk(self::DISK)->path(self::DIRECTORY), '/').'/';
        if (config('desktop.x_accel_audio') && str_starts_with($absolutePath, $privateRoot)) {
            $relative = substr($absolutePath, strlen($privateRoot));
            $location = '/'.trim((string) config('desktop.x_accel_audio_location', '/_protected_audio/'), '/').'/';
            $encoded = implode('/', array_map('rawurlencode', explode('/', $relative)));

            return response('', 200, $headers + ['X-Accel-Redirect' => $location.$encoded]);
        }

        return response()->file($absolutePath, $headers);
    }
}
