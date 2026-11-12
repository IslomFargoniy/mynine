<?php

namespace App\Models;

use App\Jobs\RescoreQuestionJob;
use App\Models\Concerns\SanitizesContentHtml;
use Database\Factories\OptionFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Option extends Model
{
    /** @use HasFactory<OptionFactory> */
    use HasFactory;

    use SanitizesContentHtml;

    protected $fillable = [
        'section_id',
        'question_id',
        'textarea',
        'is_correct',
    ];

    protected $casts = [
        'is_correct' => 'boolean',
    ];

    protected static function booted()
    {
        // Answer-key fix: re-score the submitted modules that answered this question.
        static::updated(function (Option $option) {
            if ($option->question_id && $option->wasChanged('is_correct')) {
                RescoreQuestionJob::dispatch((int) $option->question_id)->afterCommit();
            }
        });
    }

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
