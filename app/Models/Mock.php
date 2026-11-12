<?php

namespace App\Models;

use App\Models\User\User;
use Carbon\Carbon;
use Database\Factories\MockFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Collection;

class Mock extends Model
{
    use HasFactory;

    /** @use HasFactory<MockFactory> */
    protected $fillable = [
        'name',
        'comment',
        'finished_at',
        'started_at',
        'test_id',
        'user_id',
        'slug',
        'active',
        'require_desktop',
        'speaking_starts_at',
        'speaking_slot_minutes',
    ];

    protected $casts = [
        'require_desktop' => 'boolean',
        // Serialized as Asia/Tashkent wall-clock time like started_at/finished_at (not UTC), so the mock form
        // shows and re-saves the same time whatever the browser's time zone.
        'speaking_starts_at' => 'datetime:Y-m-d H:i:s',
        'speaking_slot_minutes' => 'integer',
    ];

    protected $with = [
        'test',
    ];

    protected $appends = [
        'status',
    ];

    public function getStatusAttribute(): string
    {
        if (! $this->active) {
            return 'inactive';
        }
        $now = now();
        if ($this->started_at && $now->lt(Carbon::parse($this->started_at))) {
            return 'scheduled';
        }
        if ($this->finished_at && $now->gt(Carbon::parse($this->finished_at))) {
            return 'expired';
        }

        return 'active';
    }

    /**
     * Default mock of the staff pages (Speaking, Monitor): today's mock (started today, scheduled or running;
     * the running one, else the earliest), else a currently open mock, else the first one (lists are latest first).
     *
     * @param  Collection<int, Mock>  $mocks
     */
    public static function pickDefault(Collection $mocks): ?self
    {
        $today = $mocks
            ->filter(fn (Mock $m) => $m->started_at && Carbon::parse($m->started_at)->isToday() && in_array($m->status, ['scheduled', 'active'], true))
            ->sortBy(fn (Mock $m) => Carbon::parse($m->started_at)->getTimestamp());

        return $today->first(fn (Mock $m) => $m->status === 'active')
            ?? $today->first()
            ?? $mocks->first(fn (Mock $m) => $m->status === 'active')
            ?? $mocks->first();
    }

    /**
     * Reception's mock when a day has several: the one running now, else the day's earliest upcoming one.
     *
     * @param  Collection<int, Mock>  $mocks  the day's mocks, earliest first
     */
    public static function pickRunningOrNext(Collection $mocks): ?self
    {
        $now = now();

        return $mocks->first(fn (Mock $m) => $m->status === 'active')
            ?? $mocks->first(fn (Mock $m) => $now->between(Carbon::parse($m->started_at), Carbon::parse($m->finished_at)))
            ?? $mocks->first(fn (Mock $m) => Carbon::parse($m->started_at)->gt($now));
    }

    public function test()
    {
        return $this->belongsTo(Test::class, 'test_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function attempts()
    {
        return $this->hasMany(Attempt::class, 'mock_id');
    }

    /**
     * One Mock Bank module (test_types row) per type. Empty for legacy single-test mocks.
     */
    public function modules()
    {
        return $this->hasMany(MockModule::class, 'mock_id');
    }

    public function students()
    {
        return $this->hasMany(MockStudent::class, 'mock_id');
    }

    /**
     * test_type ids the candidates of this mock sit: mock_modules, or (legacy mocks) every module of mocks.test_id that has parts.
     *
     * @return array<int>
     */
    public function moduleTestTypeIds(): array
    {
        $ids = $this->modules()->pluck('test_type_id');

        if ($ids->isEmpty() && $this->test_id) {
            $ids = TestType::withoutEagerLoads()->where('test_id', $this->test_id)->whereHas('parts')->pluck('id');
        }

        return $ids->map(fn ($id) => (int) $id)->all();
    }

    /**
     * Type names of the mock's modules (e.g. Listening, Reading, Writing).
     *
     * @return array<string>
     */
    public function moduleTypeNames(): array
    {
        return TestType::withoutEagerLoads()
            ->whereIn('test_types.id', $this->moduleTestTypeIds())
            ->join('types', 'types.id', '=', 'test_types.type_id')
            ->pluck('types.name')
            ->unique()
            ->values()
            ->all();
    }

    /**
     * Modules cannot be changed once any candidate of this mock has an attempt (logged in on a PC, which may
     * already have prefetched the questions, or scored in Speaking): answers would no longer match.
     */
    public function modulesLocked(): bool
    {
        return $this->attempts()->exists();
    }

    /**
     * Whether a candidate of this mock is still taking it (attempt not finished).
     */
    public function hasUnfinishedAttempt(): bool
    {
        return $this->attempts()->whereNull('finished_at')->exists();
    }
}
