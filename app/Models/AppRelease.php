<?php

namespace App\Models;

use App\Models\User\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AppRelease extends Model
{
    use HasFactory;

    /** Installers live on the private local disk under this directory. */
    public const DIRECTORY = 'desktop-releases';

    public const DISK = 'local';

    protected $fillable = [
        'version',
        'notes',
        'mandatory',
        'file_path',
        'file_size',
        'sha256',
        'is_active',
        'published_by',
    ];

    protected $casts = [
        'mandatory' => 'boolean',
        'is_active' => 'boolean',
        'file_size' => 'integer',
    ];

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('is_active', true);
    }

    public function publisher()
    {
        return $this->belongsTo(User::class, 'published_by');
    }

    /**
     * Highest active release by semantic version.
     */
    public static function latestActive(): ?self
    {
        return static::active()->get()
            ->sort(fn (self $a, self $b) => version_compare($b->version, $a->version))
            ->first();
    }

    /**
     * Highest active mandatory version, i.e. the minimum version clients must run.
     */
    public static function minVersion(): ?string
    {
        return static::active()->where('mandatory', true)->pluck('version')
            ->sort(fn ($a, $b) => version_compare($b, $a))
            ->first();
    }

    public static function isValidVersion(?string $version): bool
    {
        return is_string($version) && preg_match('/^\d+\.\d+\.\d+$/', $version) === 1;
    }
}
