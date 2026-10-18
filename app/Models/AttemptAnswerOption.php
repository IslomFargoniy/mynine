<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AttemptAnswerOption extends Model
{
    /** @use HasFactory<\Database\Factories\AttemptAnswerOptionFactory> */
    use HasFactory;

    protected $fillable = [
        'attempt_answer_id',
        'option_id',
        'is_correct',
    ];

    protected $with = [
        'option',
    ];

    public function attempt_answer()
    {
        return $this->belongsTo(AttemptAnswer::class, 'attempt_answer_id');
    }

    public function option()
    {
        return $this->belongsTo(Option::class, 'option_id');
    }
}
