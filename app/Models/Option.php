<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Option extends Model
{
    /** @use HasFactory<\Database\Factories\OptionFactory> */
    use HasFactory;

    protected $fillable = [
        'section_id',
        'question_id',
        'textarea',
        'is_correct',
    ];

    protected $casts = [
        'is_correct' => 'boolean',
    ];

    public function section()
    {
        return $this->belongsTo(Section::class, 'section_id');
    }

    public function question()
    {
        return $this->belongsTo(Question::class, 'question_id');
    }

    public function attempt_answer_options()
    {
        return $this->hasMany(AttemptAnswerOption::class, 'option_id');
    }
}
