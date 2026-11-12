<?php

namespace App\Support;

use App\Models\CenterSetting;
use Illuminate\Support\Facades\Storage;

/**
 * Branding of a partner center's printouts and pages: its name and logo (center_settings) plus a small
 * "Powered by Mynine". The Mynine center (and records without a center) have no branding: their
 * printouts and pages stay as they always were.
 */
final class CenterBranding
{
    /** Logos above this size are not embedded in PDFs (the name alone is printed). */
    private const MAX_EMBED_BYTES = 2 * 1024 * 1024;

    private const MIME = ['png' => 'image/png', 'jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg', 'webp' => 'image/webp', 'gif' => 'image/gif'];

    private ?string $dataUri = null;

    private bool $dataUriResolved = false;

    public function __construct(
        public readonly string $name,
        public readonly string $code,
        public readonly ?string $logoPath,
    ) {}

    /**
     * Branding of a center, or null for the Mynine center / no center.
     */
    public static function forCenter(?int $centerId): ?self
    {
        if (! $centerId) {
            return null;
        }

        $settings = CenterSetting::query()->where('owner_id', $centerId)->first();

        return $settings && ! $settings->isMynine()
            ? new self((string) $settings->name, (string) $settings->code, $settings->logo_path ?: null)
            : null;
    }

    /**
     * Public URL of the logo (web pages, browser print), or null when there is none.
     */
    public function logoUrl(): ?string
    {
        return $this->logoPath && Storage::disk(CenterSetting::LOGO_DISK)->exists($this->logoPath)
            ? Storage::disk(CenterSetting::LOGO_DISK)->url($this->logoPath)
            : null;
    }

    /**
     * The logo as a data: URI for dompdf (no remote fetches), or null when missing / too big / not an image.
     */
    public function logoDataUri(): ?string
    {
        if ($this->dataUriResolved) {
            return $this->dataUri;
        }
        $this->dataUriResolved = true;

        $disk = Storage::disk(CenterSetting::LOGO_DISK);
        $mime = self::MIME[strtolower(pathinfo((string) $this->logoPath, PATHINFO_EXTENSION))] ?? null;
        if (! $this->logoPath || ! $mime || ! $disk->exists($this->logoPath) || $disk->size($this->logoPath) > self::MAX_EMBED_BYTES) {
            return null;
        }

        return $this->dataUri = 'data:'.$mime.';base64,'.base64_encode((string) $disk->get($this->logoPath));
    }
}
