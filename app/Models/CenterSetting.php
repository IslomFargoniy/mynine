<?php

namespace App\Models;

use App\Models\User\User;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

/**
 * Settings of one center (a center IS its Admin user: owner_id). Holds the desktop settings that used to be
 * global (center password, exam-app background) plus name, logo, code, status and contract end.
 */
class CenterSetting extends Model
{
    public const STATUS_ACTIVE = 'active';

    public const STATUS_SUSPENDED = 'suspended';

    /** Code of the platform's own center, which owns the practice tests, students and blog. */
    public const MYNINE_CODE = 'MYNINE';

    public const CODE_PATTERN = '/^[A-Z0-9]{3,12}$/';

    public const PBKDF2_ITERATIONS = 120000;

    public const LOGO_DISK = 'public';

    protected $fillable = [
        'owner_id',
        'name',
        'code',
        'logo_path',
        'status',
        'contract_until',
    ];

    protected $hidden = [
        'exit_password',
        'exit_password_offline',
        'background',
    ];

    protected $casts = [
        'contract_until' => 'date:Y-m-d',
        'exit_password_updated_at' => 'datetime',
        'background_updated_at' => 'datetime',
    ];

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public static function normalizeCode(?string $code): string
    {
        return strtoupper(trim((string) $code));
    }

    public static function findByCode(?string $code): ?self
    {
        $code = self::normalizeCode($code);

        return $code === '' ? null : static::query()->where('code', $code)->first();
    }

    /**
     * Suspended by the SuperAdmin, or the contract ended (contract_until is the last allowed day).
     */
    public function isSuspended(): bool
    {
        if ($this->status === self::STATUS_SUSPENDED) {
            return true;
        }

        return $this->contract_until !== null && Carbon::parse($this->contract_until)->endOfDay()->isPast();
    }

    public function isMynine(): bool
    {
        return $this->code === self::MYNINE_CODE;
    }

    /**
     * Center password: bcrypt for online checks and a PBKDF2 string ("pbkdf2_sha256$<iterations>$<salt_b64>$<hash_b64>")
     * the desktop app can verify offline.
     */
    public function setExitPassword(string $plain): void
    {
        $salt = random_bytes(16);
        $hash = hash_pbkdf2('sha256', $plain, $salt, self::PBKDF2_ITERATIONS, 32, true);

        $this->forceFill([
            'exit_password' => Hash::make($plain),
            'exit_password_offline' => sprintf('pbkdf2_sha256$%d$%s$%s', self::PBKDF2_ITERATIONS, base64_encode($salt), base64_encode($hash)),
            'exit_password_updated_at' => now(),
        ])->save();
    }

    public function hasExitPassword(): bool
    {
        return $this->exit_password !== null && $this->exit_password !== '';
    }

    public function checkExitPassword(string $plain): bool
    {
        return $this->hasExitPassword() && Hash::check($plain, $this->exit_password);
    }

    /**
     * The exam app's code-screen background picture, or null.
     *
     * @return array{path: string, sha256: string, updatedAt: ?string}|null
     */
    public function backgroundInfo(): ?array
    {
        $data = $this->background ? json_decode($this->background, true) : null;
        if (! is_array($data) || empty($data['path']) || ! Storage::disk('local')->exists($data['path'])) {
            return null;
        }

        return [
            'path' => $data['path'],
            'sha256' => (string) ($data['sha256'] ?? ''),
            'updatedAt' => $this->background_updated_at?->toIso8601String(),
        ];
    }

    public function setBackground(?string $path, ?string $sha256): void
    {
        $this->forceFill([
            'background' => $path ? json_encode(['path' => $path, 'sha256' => $sha256]) : null,
            'background_updated_at' => now(),
        ])->save();
    }

    public function logoUrl(): ?string
    {
        return $this->logo_path ? Storage::disk(self::LOGO_DISK)->url($this->logo_path) : null;
    }

    /**
     * @return array<string, mixed>
     */
    public function summary(): array
    {
        return [
            'id' => (int) $this->owner_id,
            'name' => $this->name,
            'code' => $this->code,
            'logo_url' => $this->logoUrl(),
            'status' => $this->status,
            'contract_until' => $this->contract_until?->toDateString(),
            'suspended' => $this->isSuspended(),
            'is_mynine' => $this->isMynine(),
        ];
    }
}
