<?php

namespace App\Models;

use App\Models\User\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Mock extends Model
{
    use HasFactory;

    /** @use HasFactory<\Database\Factories\MockFactory> */
    protected $fillable = [
        'name',
        'comment',
        'finished_at',
        'started_at',
        'test_id',
        'user_id',
        'slug',
        'active',
    ];

    protected $with = [
        'test',
    ];

    protected $appends = [
        'status',
    ];

    public function getStatusAttribute(): string
    {
        if (! $this->active) {
            return 'inactive';
        }
        $now = now();
        if ($this->started_at && $now->lt(\Carbon\Carbon::parse($this->started_at))) {
            return 'scheduled';
        }
        if ($this->finished_at && $now->gt(\Carbon\Carbon::parse($this->finished_at))) {
            return 'expired';
        }

        return 'active';
    }

    public function test()
    {
        return $this->belongsTo(Test::class, 'test_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function attempts()
    {
        return $this->hasMany(Attempt::class, 'mock_id');
    }

    public function students()
    {
        return $this->hasMany(MockStudent::class, 'mock_id');
    }
}
