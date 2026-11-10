<?php

namespace App\Models;

use Database\Factories\TestFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Test extends Model
{
    use HasFactory;

    public const PURPOSE_PRACTICE = 'practice';

    public const PURPOSE_MOCK = 'mock';

    public const BANK_DRAFT = 'draft';

    public const BANK_READY = 'ready';

    public const BANK_ARCHIVED = 'archived';

    /** @use HasFactory<TestFactory> */
    protected $fillable = [
        'folder_id',
        'name',
        'comment',
        'audio_path',
        'playtime_seconds',
        'active',
        'open',
        'purpose',
        'bank_status',
    ];

    protected $attributes = [
        'purpose' => self::PURPOSE_PRACTICE,
        'bank_status' => self::BANK_DRAFT,
    ];

    /**
     * Tests solvable on the website (never Mock Bank tests).
     */
    public function scopePractice(Builder $query): Builder
    {
        return $query->where('purpose', self::PURPOSE_PRACTICE);
    }

    public function scopeMock(Builder $query): Builder
    {
        return $query->where('purpose', self::PURPOSE_MOCK);
    }

    public function isMock(): bool
    {
        return $this->purpose === self::PURPOSE_MOCK;
    }

    public function folder()
    {
        return $this->belongsTo(Folder::class, 'folder_id');
    }

    public function mocks()
    {
        return $this->hasMany(Mock::class, 'test_id');
    }

    public function attempts()
    {
        return $this->hasMany(Attempt::class, 'test_id');
    }

    public function types()
    {
        return $this->hasMany(TestType::class, 'test_id');
    }

    protected static function booted()
    {
        static::deleting(function ($test) {
            $test->mocks()->delete();
            $test->types->each->delete();
        });
    }
}
