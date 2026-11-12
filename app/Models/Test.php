<?php

namespace App\Models;

use App\Models\Concerns\BelongsToCenter;
use Database\Factories\TestFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Test extends Model
{
    use BelongsToCenter, HasFactory;

    public const PURPOSE_PRACTICE = 'practice';

    public const PURPOSE_MOCK = 'mock';

    public const BANK_DRAFT = 'draft';

    public const BANK_READY = 'ready';

    public const BANK_ARCHIVED = 'archived';

    /** IELTS variant: Reading bands differ between Academic and General Training. */
    public const VARIANT_ACADEMIC = 'academic';

    public const VARIANT_GENERAL = 'general';

    /** @use HasFactory<TestFactory> */
    protected $fillable = [
        'folder_id',
        'name',
        'comment',
        'audio_path',
        'playtime_seconds',
        'active',
        'open',
        'purpose',
        'bank_status',
        'variant',
    ];

    protected $attributes = [
        'purpose' => self::PURPOSE_PRACTICE,
        'bank_status' => self::BANK_DRAFT,
        'variant' => self::VARIANT_ACADEMIC,
    ];

    /**
     * Practice tests are the platform's (Mynine's) public content and visible to everyone; Mock Bank tests
     * belong to one center.
     */
    public function applyCenterScope(Builder $builder, int $centerId): void
    {
        $builder->where(fn (Builder $q) => $q
            ->where($this->qualifyColumn('purpose'), '!=', self::PURPOSE_MOCK)
            ->orWhereNull($this->qualifyColumn('purpose'))
            ->orWhere($this->qualifyColumn('owner_id'), $centerId));
    }

    /**
     * Tests solvable on the website (never Mock Bank tests).
     */
    public function scopePractice(Builder $query): Builder
    {
        return $query->where('purpose', self::PURPOSE_PRACTICE);
    }

    public function scopeMock(Builder $query): Builder
    {
        return $query->where('purpose', self::PURPOSE_MOCK);
    }

    public function isMock(): bool
    {
        return $this->purpose === self::PURPOSE_MOCK;
    }

    public function folder()
    {
        return $this->belongsTo(Folder::class, 'folder_id');
    }

    public function mocks()
    {
        return $this->hasMany(Mock::class, 'test_id');
    }

    public function attempts()
    {
        return $this->hasMany(Attempt::class, 'test_id');
    }

    public function imports()
    {
        return $this->hasMany(TestImport::class, 'test_id');
    }

    public function latestImport()
    {
        return $this->hasOne(TestImport::class, 'test_id')->latestOfMany();
    }

    public function types()
    {
        return $this->hasMany(TestType::class, 'test_id');
    }

    /**
     * Every mock that sits this test: legacy mocks.test_id or a Mock Bank module (mock_modules.test_type_id
     * of one of the test's modules). attempts.test_id / mocks.test_id only hold the FIRST module's test.
     */
    public function usingMocks(): Builder
    {
        $typeIds = TestType::withoutEagerLoads()->where('test_id', $this->id)->pluck('id');

        return Mock::query()->withoutEagerLoads()->where(fn ($q) => $q
            ->where('test_id', $this->id)
            ->orWhereHas('modules', fn ($m) => $m->whereIn('test_type_id', $typeIds)));
    }

    /**
     * Whether the content must not change: the test has attempts, or a mock using it (any module) has
     * attempts or has not ended yet.
     */
    public function inUse(): bool
    {
        if ($this->attempts()->exists()) {
            return true;
        }

        return $this->usingMocks()
            ->where(fn ($q) => $q
                ->whereHas('attempts')
                ->orWhereNull('finished_at')
                ->orWhere('finished_at', '>', now()))
            ->exists();
    }

    protected static function booted()
    {
        static::deleting(function ($test) {
            // Never cascade into mocks (their candidates, codes and results): the caller must refuse.
            if ($test->usingMocks()->exists()) {
                throw new \RuntimeException(__('test_used_by_mock'));
            }
            $test->types->each->delete();
        });
    }
}
