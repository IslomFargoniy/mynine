<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Section extends Model
{
    /** @use HasFactory<\Database\Factories\SectionFactory> */
    use HasFactory;

    protected $fillable = [
        'part_id',
        'question_type_id',
        'textarea',
        'from_option',
        'to_option',
    ];

    protected $with = [
        'questions',
        'question_type',
        'options',
    ];

    public function part()
    {
        return $this->belongsTo(Part::class, 'part_id');
    }

    public function question_type()
    {
        return $this->belongsTo(QuestionType::class, 'question_type_id');
    }

    public function questions()
    {
        return $this->hasMany(Question::class, 'section_id');
    }

    public function options()
    {
        return $this->hasMany(Option::class, 'section_id');
    }

    protected static function booted()
    {
        static::deleting(function ($section) {
            $section->questions->each->delete();
            $section->options->each->delete();
            \App\Models\Image::where('section_id', $section->id)->delete();
        });
    }
}
