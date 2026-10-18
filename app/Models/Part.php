<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class Part extends Model
{
    /** @use HasFactory<\Database\Factories\PartFactory> */
    use HasFactory;

    protected $fillable = [
        'test_type_id',
        'name',
        'textarea',
        'audio_path',
        'minute',
        'comment',
    ];

    protected $with = [
        'sections',
    ];

    public function test_type()
    {
        return $this->belongsTo(TestType::class, 'test_type_id');
    }

    public function sections()
    {
        return $this->hasMany(Section::class, 'part_id');
    }

    public function images()
    {
        return $this->hasMany(Image::class, 'part_id');
    }

    protected static function booted()
    {
        static::deleting(function ($part) {
            $part->sections->each->delete();
            \App\Models\Image::where('part_id', $part->id)->delete();
        });
    }

    public function attempt_parts()
    {
        return $this->hasMany(AttemptPart::class, 'part_id');
    }

    public function attempt_part()
    {
        return $this->hasOne(AttemptPart::class, 'part_id');
    }

    protected $appends = ['order'];

    public function getOrderAttribute()
    {

        $part_start_number = DB::table(DB::raw('(
                SELECT q.id,
                       COUNT(o.id)                                       AS option_count,
                       SUM(CASE WHEN o.is_correct = 1 THEN 1 ELSE 0 END) AS correct_count
                FROM questions q
                         LEFT JOIN options o ON q.id = o.question_id
                         JOIN sections s ON q.section_id = s.id
                         JOIN parts p ON s.part_id = p.id
                         JOIN test_types tt ON p.test_type_id = tt.id
                WHERE tt.id = ?
                  AND p.id < ?
                GROUP BY q.id
            ) as t'))
            ->setBindings([(int) $this->test_type_id, (int) $this->id])
            ->selectRaw('COALESCE(SUM(CASE WHEN t.option_count = 0 THEN 1 ELSE t.correct_count END), 0) as result')
            ->value('result');

        return (int) $part_start_number;

    }
}
