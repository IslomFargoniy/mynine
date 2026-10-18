<?php

namespace App\Models;

use App\Jobs\EvaluateEssayJob;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class Attempt extends Model
{
    /** @use HasFactory<\Database\Factories\AttemptsFactory> */
    use HasFactory;

    protected $fillable = [
        'name',
        'mock_id',
        'mock_student_id',
        'user_id',
        'test_id',
        'started_at',
        'finished_at',
        'status',
        'tab_switch_count',
    ];

    public function mockStudent()
    {
        return $this->belongsTo(MockStudent::class, 'mock_student_id');
    }

    public function mock()
    {
        return $this->belongsTo(Mock::class, 'mock_id');
    }

    public function user()
    {
        return $this->belongsTo(User\User::class, 'user_id');
    }

    public function test()
    {
        return $this->belongsTo(Test::class, 'test_id');
    }

    public function attempt_parts()
    {
        return $this->hasMany(AttemptPart::class, 'attempt_id');
    }

    public function attempt_types()
    {
        return $this->hasMany(AttemptType::class, 'attempt_id');
    }

    public function attempt_answers()
    {
        return $this->hasManyThrough(AttemptAnswer::class, AttemptPart::class, 'attempt_id', 'attempt_part_id');
    }

    /**
     * Essay answers of this attempt that are long enough to be worth an AI evaluation.
     */
    public function essayAnswersForEvaluation(?int $typeId = null)
    {
        return AttemptAnswer::query()
            ->whereHas('attempt_part', function ($query) use ($typeId) {
                $query->where('attempt_id', $this->id);
                if ($typeId) {
                    $query->whereHas('part.test_type', fn ($q) => $q->where('type_id', $typeId));
                }
            })
            ->whereHas('question.section.question_type', fn ($q) => $q->where('type', 'essay'))
            ->whereRaw('LENGTH(answer_text) > 10')
            ->get();
    }

    public function finish()
    {
        if ($this->finished_at) {
            return $this;
        }

        DB::beginTransaction();
        try {
            // Mark the attempt as finished
            $this->finished_at = now();
            $this->save();

            // Mark all attempt parts as finished
            foreach ($this->attempt_parts as $attempt_part) {
                if (! $attempt_part->finished_at) {
                    $attempt_part->finished_at = now();
                    $attempt_part->save();
                }
            }

            // Calculate and store is_correct_count for all attempt_types
            foreach ($this->attempt_types as $attemptType) {
                $attemptType->recalculateIsCorrectCount();
            }

            $essayAnswers = $this->essayAnswersForEvaluation();

            DB::commit();

            // Dispatch only after the commit so workers never see half-written answers
            foreach ($essayAnswers as $answer) {
                EvaluateEssayJob::dispatch($answer->id);
            }
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }

        return $this;
    }
}
