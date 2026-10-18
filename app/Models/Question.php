<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Question extends Model
{
    /** @use HasFactory<\Database\Factories\QuestionFactory> */
    use HasFactory;

    protected $fillable = [
        'section_id',
        'order',
        'textarea',
        'answer_text',
    ];

    protected $with = [
        'options',
    ];

    public function section()
    {
        return $this->belongsTo(Section::class, 'section_id');
    }

    public function images()
    {
        return $this->hasMany(Image::class, 'question_id');
    }

    public function options()
    {
        return $this->hasMany(Option::class, 'question_id');
    }

    public function attempt_answer()
    {
        return $this->hasOne(AttemptAnswer::class, 'question_id');
    }

    public function attempt_answers()
    {
        return $this->hasMany(AttemptAnswer::class, 'question_id');
    }

    protected $appends = ['is_correct_count'];

    /**
     * How many answers this question is worth: 1 for free-text questions,
     * otherwise the number of correct options (e.g. "choose TWO letters").
     * Uses the already-loaded options relation to avoid one query per question.
     */
    public function getIsCorrectCountAttribute(): int
    {
        $options = $this->relationLoaded('options')
            ? $this->options
            : $this->options()->get(['id', 'is_correct']);

        if ($options->isEmpty()) {
            return 1;
        }

        return (int) $options->where('is_correct', true)->count();
    }

    protected static function booted()
    {
        static::deleting(function ($question) {
            $question->options->each->delete();
            \App\Models\Image::where('question_id', $question->id)->delete();
        });
    }
}
