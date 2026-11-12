<?php

namespace App\Models;

use App\Models\User\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Who changed what about a center (admin replaced, suspended, created ...).
 */
class CenterAuditLog extends Model
{
    public const UPDATED_AT = null;

    protected $fillable = ['actor_id', 'center_id', 'action', 'old_email', 'new_email', 'meta', 'ip'];

    protected $casts = [
        'meta' => 'array',
    ];

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_id');
    }

    public static function record(string $action, ?int $centerId, array $attributes = []): self
    {
        return static::create([
            'actor_id' => auth()->id(),
            'center_id' => $centerId,
            'action' => $action,
            'ip' => request()?->ip(),
            ...$attributes,
        ]);
    }
}
