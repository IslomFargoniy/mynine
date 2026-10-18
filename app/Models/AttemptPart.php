<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AttemptPart extends Model
{
    /** @use HasFactory<\Database\Factories\AttemptPartFactory> */
    use HasFactory;

    protected $fillable = [
        'attempt_id',
        'part_id',
        'started_at',
        'finished_at',
    ];

    public function attempt()
    {
        return $this->belongsTo(Attempt::class, 'attempt_id');
    }

    public function part()
    {
        return $this->belongsTo(Part::class, 'part_id');
    }

    public function attempt_answers()
    {
        return $this->hasMany(AttemptAnswer::class, 'attempt_part_id');
    }
}
