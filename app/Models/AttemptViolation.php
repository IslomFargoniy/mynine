<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AttemptViolation extends Model
{
    public const TYPES = [
        'focus_lost',
        'second_monitor',
        'banned_process',
        'screen_capture_attempt',
        'app_restarted',
        'network_lost',
        'clipboard',
        'vm_detected',
    ];

    protected $fillable = [
        'attempt_id',
        'device_id',
        'client_uuid',
        'type',
        'detail',
        'occurred_at',
    ];

    protected $casts = [
        'detail' => 'array',
        'occurred_at' => 'datetime',
    ];

    public function attempt()
    {
        return $this->belongsTo(Attempt::class, 'attempt_id');
    }

    public function device()
    {
        return $this->belongsTo(Device::class, 'device_id');
    }
}
