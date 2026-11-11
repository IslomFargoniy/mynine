<?php

namespace App\Models;

use Database\Factories\QuestionTypeFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class QuestionType extends Model
{
    /** @use HasFactory<QuestionTypeFactory> */
    use HasFactory;

    protected $fillable = [
        'name',
        'type',
        'input_type',
    ];

    public function section()
    {
        return $this->hasMany(Section::class, 'question_type_id');
    }
}
