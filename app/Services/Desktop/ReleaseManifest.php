<?php

namespace App\Services\Desktop;

use Illuminate\Support\Facades\Cache;

/**
 * Reads the static desktop update manifest public/desktop/version.json (served as https://<site>/desktop/version.json).
 *
 * Installers are uploaded next to it by hand; the desktop app reads the same file directly from nginx.
 * A missing or invalid file is treated as "no release" (null), never as an error.
 */
class ReleaseManifest
{
    public const RELATIVE_PATH = 'desktop/version.json';

    private const SEMVER = '/^\d+\.\d+\.\d+$/';

    public function __construct(private ?string $path = null) {}

    public function path(): string
    {
        return $this->path ?? public_path(self::RELATIVE_PATH);
    }

    /**
     * Validated manifest, or null when the file is missing/unreadable/invalid.
     *
     * @return array{version: string, file: string, sha256: string, size: int, mandatory: bool, min_version: ?string, notes: string, published_at: ?string}|null
     */
    public function get(): ?array
    {
        $path = $this->path();

        clearstatcache(true, $path);
        if (! is_file($path)) {
            return null;
        }

        $mtime = @filemtime($path) ?: 0;
        $key = 'desktop-release-manifest:'.md5($path).':'.$mtime.':'.(@filesize($path) ?: 0);

        // Wrapped so a cached "invalid" (null) result is distinguishable from a cache miss.
        return Cache::remember($key, now()->addDay(), fn () => ['value' => self::parse(@file_get_contents($path))])['value'];
    }

    public function latestVersion(): ?string
    {
        return $this->get()['version'] ?? null;
    }

    public function minVersion(): ?string
    {
        return $this->get()['min_version'] ?? null;
    }

    /**
     * @return array<string, mixed>|null
     */
    public static function parse(string|false|null $json): ?array
    {
        if (! is_string($json) || $json === '') {
            return null;
        }

        $data = json_decode($json, true);
        if (! is_array($data)) {
            return null;
        }

        $version = $data['version'] ?? null;
        $file = $data['file'] ?? null;
        if (! is_string($version) || preg_match(self::SEMVER, $version) !== 1) {
            return null;
        }
        if (! is_string($file) || preg_match('/^[A-Za-z0-9._-]+\.exe$/', $file) !== 1) {
            return null;
        }

        $minVersion = $data['min_version'] ?? null;
        if (! is_string($minVersion) || preg_match(self::SEMVER, $minVersion) !== 1) {
            $minVersion = null;
        }

        $sha256 = $data['sha256'] ?? '';
        $sha256 = is_string($sha256) && preg_match('/^[0-9a-fA-F]{64}$/', $sha256) === 1 ? strtolower($sha256) : '';

        $size = $data['size'] ?? 0;
        $size = is_int($size) && $size > 0 ? $size : 0;

        return [
            'version' => $version,
            'file' => $file,
            'sha256' => $sha256,
            'size' => $size,
            'mandatory' => ($data['mandatory'] ?? false) === true,
            'min_version' => $minVersion,
            'notes' => is_string($data['notes'] ?? null) ? $data['notes'] : '',
            'published_at' => is_string($data['published_at'] ?? null) ? $data['published_at'] : null,
        ];
    }
}
