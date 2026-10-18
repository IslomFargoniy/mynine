<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Test extends Model
{
    use HasFactory;

    /** @use HasFactory<\Database\Factories\TestFactory> */
    protected $fillable = [
        'folder_id',
        'name',
        'comment',
        'audio_path',
        'playtime_seconds',
        'active',
        'open',
    ];

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
