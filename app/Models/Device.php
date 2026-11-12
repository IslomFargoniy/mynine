<?php

namespace App\Models;

use App\Exceptions\ApiException;
use App\Models\Concerns\BelongsToCenter;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Device extends Model
{
    use BelongsToCenter, HasFactory;

    protected $fillable = [
        'machine_id',
        'name',
        'number',
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
        'number' => 'integer',
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

        return static::withoutGlobalScope(Scopes\CenterScope::class)->where('token_hash', static::hashToken($plainToken))->first();
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

    public const MAX_NUMBER = 999;

    /**
     * Approve the PC and (optionally) give it its exam-room number. Without a number the
     * current one is kept, or the next free one is assigned.
     */
    public function approve(?int $number = null): void
    {
        $this->forceFill([
            'is_approved' => true,
            'approved_at' => now(),
            'number' => $number ?? $this->number ?? static::nextFreeNumber($this->owner_id ? (int) $this->owner_id : null),
        ])->save();
    }

    /**
     * Lowest exam-room number (1..MAX_NUMBER) not used by any PC of the center (default: the current one).
     */
    public static function nextFreeNumber(?int $centerId = null): ?int
    {
        $query = $centerId !== null ? static::query()->ofCenter($centerId) : static::query();
        $used = $query->whereNotNull('number')->orderBy('number')->pluck('number')->all();
        $next = 1;
        foreach ($used as $n) {
            if ((int) $n > $next) {
                break;
            }
            $next = max($next, (int) $n + 1);
        }

        return $next <= self::MAX_NUMBER ? $next : null;
    }

    /**
     * Default name of a PC that registered without one: "PC-<last 4 characters of the machine id>".
     */
    public static function defaultName(string $machineId): string
    {
        $tail = strtoupper(substr(preg_replace('/[^A-Za-z0-9]/', '', $machineId) ?: $machineId, -4));

        return 'PC-'.$tail;
    }

    /**
     * Fields the app shows about itself (number is null until the PC is approved).
     *
     * @return array{name: string, number: int|null, approved: bool}
     */
    public function publicInfo(): array
    {
        return [
            'name' => $this->name,
            'number' => $this->is_approved ? $this->number : null,
            'approved' => (bool) $this->is_approved,
        ];
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

    /**
     * An exam is running on this PC right now: its current attempt is unfinished and the PC sent an exam
     * heartbeat recently (same window as "session active elsewhere" on login).
     */
    public function hasRunningAttempt(): bool
    {
        if (! $this->current_attempt_id) {
            return false;
        }

        return Attempt::withoutEagerLoads()
            ->whereKey($this->current_attempt_id)
            ->whereNull('finished_at')
            ->whereNotNull('last_heartbeat_at')
            ->where('last_heartbeat_at', '>', now()->subSeconds((int) config('desktop.active_elsewhere_seconds', 90)))
            ->exists();
    }
}
