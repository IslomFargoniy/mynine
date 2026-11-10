<?php

namespace App\Models;

use App\Exceptions\ApiException;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Device extends Model
{
    use HasFactory;

    protected $fillable = [
        'machine_id',
        'name',
        'token_hash',
        'app_version',
        'os_version',
        'ip',
        'last_seen_at',
        'is_blocked',
        'is_approved',
        'approved_at',
        'current_attempt_id',
    ];

    protected $hidden = [
        'token_hash',
    ];

    protected $casts = [
        'last_seen_at' => 'datetime',
        'is_blocked' => 'boolean',
        'is_approved' => 'boolean',
        'approved_at' => 'datetime',
    ];

    public static function hashToken(string $plainToken): string
    {
        return hash('sha256', $plainToken);
    }

    public static function findByToken(?string $plainToken): ?self
    {
        if (! $plainToken) {
            return null;
        }

        return static::where('token_hash', static::hashToken($plainToken))->first();
    }

    /**
     * Issue a new token (invalidating the previous one) and return the plain value once.
     */
    public function rotateToken(): string
    {
        $plain = Str::random(64);
        $this->token_hash = static::hashToken($plain);

        return $plain;
    }

    public function approve(): void
    {
        $this->forceFill(['is_approved' => true, 'approved_at' => now()])->save();
    }

    /**
     * Unapproved PCs may register, heartbeat and check for updates, but not run exams.
     */
    public function ensureApproved(): void
    {
        if (! $this->is_approved) {
            throw new ApiException(403, 'device_not_approved', 'This PC is not approved yet. Ask the administrator to approve "'.$this->name.'".');
        }
    }

    public function currentAttempt()
    {
        return $this->belongsTo(Attempt::class, 'current_attempt_id');
    }

    public function attempts()
    {
        return $this->hasMany(Attempt::class, 'device_id');
    }
}
