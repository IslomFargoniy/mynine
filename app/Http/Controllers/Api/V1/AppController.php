<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Middleware\Desktop\EnsureClientVersion;
use App\Models\AppRelease;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class AppController extends Controller
{
    /**
     * GET /app/version — newest active release and the mandatory minimum.
     */
    public function version(Request $request): JsonResponse
    {
        $request->validate([
            'current' => ['nullable', 'string', 'regex:/^\d+\.\d+\.\d+$/'],
        ]);

        $latest = AppRelease::latestActive();
        $current = $request->query('current') ?: EnsureClientVersion::clientVersion($request);

        return response()->json([
            'latest' => $latest ? [
                'version' => $latest->version,
                'notes' => $latest->notes,
                'mandatory' => $latest->mandatory,
                'url' => route('api.v1.app.download', $latest->version),
                'sha256' => $latest->sha256,
                'size' => $latest->file_size,
                'published_at' => $latest->created_at?->toIso8601String(),
            ] : null,
            'min_version' => AppRelease::minVersion(),
            'update_available' => $latest !== null && ($current === null || version_compare($latest->version, $current, '>')),
            'server_time' => now()->toIso8601String(),
        ]);
    }

    /**
     * GET /app/releases/{version}/download — installer with HTTP Range support (resume).
     */
    public function download(string $version): BinaryFileResponse
    {
        $release = AppRelease::active()->where('version', $version)->first();
        abort_unless($release, 404, 'Release not found.');

        $disk = Storage::disk(AppRelease::DISK);
        abort_unless($release->file_path && $disk->exists($release->file_path), 404, 'Release file not found.');

        return response()->download(
            $disk->path($release->file_path),
            'mynine-setup-'.$release->version.'.exe',
            ['Content-Type' => 'application/octet-stream', 'Cache-Control' => 'private, max-age=0'],
        );
    }
}
