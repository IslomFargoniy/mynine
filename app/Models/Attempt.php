<?php

namespace App\Models;

use App\Jobs\EvaluateEssayJob;
use Database\Factories\AttemptsFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class Attempt extends Model
{
    /** @use HasFactory<AttemptsFactory> */
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
        'device_id',
        'last_heartbeat_at',
        'paused_at',
        'unlock_requested_at',
    ];

    protected $casts = [
        'last_heartbeat_at' => 'datetime',
        'paused_at' => 'datetime',
        'unlock_requested_at' => 'datetime',
    ];

    /**
     * Desktop exam modules in the fixed order (Speaking is never part of the desktop exam).
     */
    public const DESKTOP_MODULE_ORDER = ['Listening', 'Reading', 'Writing'];

    /** @var array<int>|null|false false = not resolved yet */
    private array|null|false $cachedModuleTestTypeIds = false;

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

    public function device()
    {
        return $this->belongsTo(Device::class, 'device_id');
    }

    public function violations()
    {
        return $this->hasMany(AttemptViolation::class, 'attempt_id');
    }

    public function isPaused(): bool
    {
        return $this->paused_at !== null;
    }

    /**
     * test_type ids this attempt may touch, or null when the attempt is bound to attempts.test_id
     * (practice attempts and legacy single-test mocks).
     *
     * @return array<int>|null
     */
    public function moduleTestTypeIds(): ?array
    {
        if ($this->cachedModuleTestTypeIds !== false) {
            return $this->cachedModuleTestTypeIds;
        }

        $ids = $this->mock_id
            ? MockModule::where('mock_id', $this->mock_id)->pluck('test_type_id')
            : collect();

        return $this->cachedModuleTestTypeIds = $ids->isEmpty() ? null : $ids->map(fn ($id) => (int) $id)->all();
    }

    public function allowsTestType(TestType $testType): bool
    {
        $moduleIds = $this->moduleTestTypeIds();
        if ($moduleIds !== null) {
            return in_array((int) $testType->id, $moduleIds, true);
        }

        return (int) $testType->test_id === (int) $this->test_id;
    }

    public function allowsPart(Part $part): bool
    {
        $moduleIds = $this->moduleTestTypeIds();
        if ($moduleIds !== null) {
            return in_array((int) $part->test_type_id, $moduleIds, true);
        }

        $testId = $part->relationLoaded('test_type')
            ? $part->test_type?->test_id
            : TestType::withoutEagerLoads()->whereKey($part->test_type_id)->value('test_id');

        return $testId !== null && (int) $testId === (int) $this->test_id;
    }

    /**
     * All modules of this attempt (any type that has parts), from mock_modules or from attempts.test_id.
     *
     * @return \Illuminate\Database\Eloquent\Collection<int, TestType>
     */
    public function moduleTestTypes()
    {
        $moduleIds = $this->moduleTestTypeIds();

        $query = TestType::query()->with(['test', 'type'])->whereHas('parts');
        $moduleIds !== null
            ? $query->whereIn('id', $moduleIds)
            : $query->where('test_id', $this->test_id);

        return $query->orderBy('id')->get();
    }

    /**
     * Listening, Reading, Writing modules of the attempt in exam order.
     *
     * @return Collection<int, TestType>
     */
    public function examModules()
    {
        $order = array_flip(self::DESKTOP_MODULE_ORDER);

        return $this->moduleTestTypes()
            ->filter(fn (TestType $tt) => isset($order[$tt->type?->name]))
            ->unique('type_id')
            ->sortBy(fn (TestType $tt) => $order[$tt->type->name])
            ->values();
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
