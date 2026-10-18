<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TestType extends Model
{
    /** @use HasFactory<\Database\Factories\TestTypeFactory> */
    use HasFactory;

    protected $fillable = [
        'test_id',
        'type_id',
    ];

    protected $with = ['test', 'type'];

    public function test()
    {
        return $this->belongsTo(Test::class, 'test_id');
    }

    public function type()
    {
        return $this->belongsTo(Type::class, 'type_id');
    }

    public function parts()
    {
        return $this->hasMany(Part::class, 'test_type_id');
    }

    protected static function booted()
    {
        static::deleting(function ($testType) {
            $testType->parts->each->delete();
        });
    }
}
