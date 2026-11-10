<?php

namespace App\Models;

use App\Models\User\User;
use Carbon\Carbon;
use Database\Factories\MockFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

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
        'speaking_starts_at' => 'datetime',
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
}
