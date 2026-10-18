<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AttemptAnswer extends Model
{
    /** @use HasFactory<\Database\Factories\AttemptAnswerFactory> */
    use HasFactory;

    protected $fillable = [
        'attempt_part_id',
        'question_id',
        'answer_text',
        'audio_path',
        'transcript',
        'review_note',
        'review_note_ai',
        'is_correct',
        'score',
    ];

    public function attempt_part()
    {
        return $this->belongsTo(AttemptPart::class, 'attempt_part_id');
    }

    public function question()
    {
        return $this->belongsTo(Question::class, 'question_id');
    }

    public function attempt_answer_options()
    {
        return $this->hasMany(AttemptAnswerOption::class, 'attempt_answer_id');
    }
}
