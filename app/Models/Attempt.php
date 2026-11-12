<?php

namespace App\Models;

use App\Jobs\EvaluateEssayJob;
use App\Models\Scopes\CenterScope;
use App\Support\CurrentCenter;
use Carbon\Carbon;
use Database\Factories\AttemptsFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;
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

    /**
     * Mock attempts belong to their mock's center. Attempts without a mock (practice on the website) belong
     * to the platform (Mynine); other centers only see their own user's practice attempts.
     */
    protected static function booted(): void
    {
        static::addGlobalScope(new CenterScope);
    }

    public function applyCenterScope(Builder $builder, int $centerId): void
    {
        $isMynine = app(CurrentCenter::class)->isMynine($centerId);

        $builder->where(fn (Builder $q) => $q
            ->whereIn($this->qualifyColumn('mock_id'), Mock::centerMockIds($centerId))
            ->orWhere(fn (Builder $w) => $w
                ->whereNull($this->qualifyColumn('mock_id'))
                ->when(! $isMynine, fn (Builder $u) => $u->where($this->qualifyColumn('user_id'), Auth::id() ?? 0))));
    }

    /**
     * Owner (center Admin id) of a mock attempt; null for practice attempts.
     */
    public function centerId(): ?int
    {
        if (! $this->mock_id) {
            return null;
        }

        $owner = Mock::withoutGlobalScope(CenterScope::class)->withoutEagerLoads()->whereKey($this->mock_id)->value('owner_id');

        return $owner !== null ? (int) $owner : null;
    }

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

    /**
     * Results (scores, answer keys, review) are shown once the attempt is finished, and to graders at any time.
     */
    public function resultsVisibleTo(?User\User $user): bool
    {
        return $this->finished_at !== null || ($user !== null && $user->can('grade', $this));
    }

    public function isPaused(): bool
    {
        return $this->paused_at !== null;
    }

    /**
     * Whether the candidate started a written module (Listening / Reading / Writing). A Speaking band
     * stored before the written exam creates the attempt without one.
     */
    public function hasStartedWrittenModule(): bool
    {
        return $this->attempt_types()
            ->whereNotNull('started_at')
            ->whereHas('type', fn ($q) => $q->whereIn('name', self::DESKTOP_MODULE_ORDER))
            ->exists();
    }

    /**
     * Whether the mock's exam window (mocks.finished_at) is over. Attempts without a mock: always true.
     */
    public function mockWindowEnded(): bool
    {
        $finishedAt = $this->mock_id ? Mock::withoutEagerLoads()->whereKey($this->mock_id)->value('finished_at') : null;

        return ! $this->mock_id || ($finishedAt !== null && now()->gt(Carbon::parse($finishedAt)));
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
     *
     * @param  int|array<int>|null  $typeId  only these module types
     * @param  bool  $unscoredOnly  skip essays that already have a band
     */
    public function essayAnswersForEvaluation(int|array|null $typeId = null, bool $unscoredOnly = false)
    {
        $typeIds = $typeId === null ? null : (array) $typeId;

        return AttemptAnswer::query()
            ->whereHas('attempt_part', function ($query) use ($typeIds) {
                $query->where('attempt_id', $this->id);
                if ($typeIds !== null) {
                    $query->whereHas('part.test_type', fn ($q) => $q->whereIn('type_id', $typeIds));
                }
            })
            ->whereHas('question.section.question_type', fn ($q) => $q->where('type', 'essay'))
            ->whereRaw('LENGTH(answer_text) > 10')
            ->when($unscoredOnly, fn ($q) => $q->whereNull('score'))
            ->get();
    }

    /**
     * Finish the whole attempt: submit every open module, close the parts, score every module and queue
     * the AI evaluation only for essays of modules this call submitted that have no band yet (modules
     * submitted earlier already queued theirs). Safe against concurrent calls.
     */
    public function finish()
    {
        if ($this->finished_at) {
            return $this;
        }

        $essayAnswers = DB::transaction(function () {
            $locked = static::whereKey($this->id)->lockForUpdate()->first();
            if (! $locked || $locked->finished_at !== null) {
                $this->refresh();

                return collect();
            }

            $submittedNow = [];
            foreach (AttemptType::where('attempt_id', $this->id)->where('is_submitted', false)->get() as $attemptType) {
                if ($attemptType->submit()) {
                    $submittedNow[] = (int) $attemptType->type_id;
                }
            }
            $submittedBefore = AttemptType::where('attempt_id', $this->id)
                ->whereNotIn('type_id', $submittedNow ?: [0])
                ->pluck('type_id')
                ->map(fn ($id) => (int) $id)
                ->all();

            $this->finished_at = now();
            $this->paused_at = null;
            $this->save();

            AttemptPart::where('attempt_id', $this->id)->whereNull('finished_at')->update(['finished_at' => now()]);

            foreach (AttemptType::where('attempt_id', $this->id)->get() as $attemptType) {
                $attemptType->recalculateIsCorrectCount();
            }

            $this->unsetRelation('attempt_types')->unsetRelation('attempt_parts');

            // Essays of modules submitted before this call were queued at that moment.
            $essays = $this->essayAnswersForEvaluation(null, true);
            $typeIds = $this->answerTypeIds($essays->pluck('id')->all());

            return $essays
                ->filter(fn (AttemptAnswer $answer) => ! in_array($typeIds[$answer->id] ?? null, $submittedBefore, true))
                ->values();
        });

        // Dispatch only after the commit so workers never see half-written answers
        foreach ($essayAnswers as $answer) {
            EvaluateEssayJob::dispatch($answer->id);
        }

        return $this;
    }

    /**
     * Module type id of each answer: [attempt_answer_id => type_id].
     *
     * @param  array<int>  $answerIds
     * @return array<int, int>
     */
    private function answerTypeIds(array $answerIds): array
    {
        if ($answerIds === []) {
            return [];
        }

        return DB::table('attempt_answers')
            ->join('attempt_parts', 'attempt_parts.id', '=', 'attempt_answers.attempt_part_id')
            ->join('parts', 'parts.id', '=', 'attempt_parts.part_id')
            ->join('test_types', 'test_types.id', '=', 'parts.test_type_id')
            ->whereIn('attempt_answers.id', $answerIds)
            ->pluck('test_types.type_id', 'attempt_answers.id')
            ->map(fn ($id) => (int) $id)
            ->all();
    }
}
