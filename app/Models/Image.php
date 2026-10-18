<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Image extends Model
{
    /** @use HasFactory<\Database\Factories\ImageFactory> */
    use HasFactory;

    protected $fillable = [
        'part_id',
        'section_id',
        'question_id',
        'image_path',
    ];

    public function part()
    {
        return $this->belongsTo(Part::class, 'part_id');
    }

    public function section()
    {
        return $this->belongsTo(Section::class, 'section_id');
    }

    public function question()
    {
        return $this->belongsTo(Question::class, 'question_id');
    }
}
