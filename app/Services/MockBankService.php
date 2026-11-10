<?php

namespace App\Services;

use App\Models\Mock;
use App\Models\MockModule;
use App\Models\Part;
use App\Models\Question;
use App\Models\Test;
use App\Models\TestType;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Mock Bank: per-module readiness, module picking for mocks and the reuse rule
 * (docs/desktop/ARCHITECTURE.md "Reuse rule").
 */
class MockBankService
{
    /** Module types a mock is built from (Speaking is face-to-face). */
    public const MODULE_TYPES = ['Listening', 'Reading', 'Writing'];

    public function reuseDays(): int
    {
        return (int) config('desktop.module_reuse_days', 14);
    }

    /**
     * Problems that keep a module out of the "ready" state (empty = ready).
     *
     * @return array<int, string> machine codes: no_parts, no_questions, missing_answer_keys:<n>, no_audio
     */
    public function moduleIssues(TestType $testType): array
    {
        $typeName = $testType->type?->name;
        $issues = [];

        $partIds = Part::withoutEagerLoads()->where('test_type_id', $testType->id)->pluck('id');
        if ($partIds->isEmpty()) {
            return ['no_parts'];
        }

        $questions = Question::withoutEagerLoads()
            ->whereHas('section', fn ($q) => $q->withoutEagerLoads()->whereIn('part_id', $partIds));

        if (! (clone $questions)->exists()) {
            $issues[] = 'no_questions';
        }

        if (in_array($typeName, ['Listening', 'Reading'], true)) {
            $missing = (clone $questions)
                ->where(fn ($q) => $q->whereNull('answer_text')->orWhere('answer_text', ''))
                ->whereDoesntHave('options', fn ($q) => $q->where('is_correct', 1))
                ->count();

            if ($missing > 0) {
                $issues[] = 'missing_answer_keys:'.$missing;
            }
        }

        if ($typeName === 'Listening') {
            $test = $testType->test;
            $partsWithoutAudio = Part::withoutEagerLoads()->whereIn('id', $partIds)
                ->where(fn ($q) => $q->whereNull('audio_path')->orWhere('audio_path', ''))
                ->count();

            if (empty($test?->audio_path) && $partsWithoutAudio > 0) {
                $issues[] = 'no_audio';
            }
        }

        return $issues;
    }

    /**
     * Listening / Reading / Writing modules of a test that have content (or exist at all).
     *
     * @return Collection<int, TestType>
     */
    public function testModules(Test $test): Collection
    {
        return TestType::query()
            ->with('type')
            ->where('test_id', $test->id)
            ->whereHas('type', fn ($q) => $q->whereIn('name', self::MODULE_TYPES))
            ->withCount(['parts' => fn ($q) => $q->withoutEagerLoads()])
            ->orderBy('type_id')
            ->get();
    }

    /**
     * The module the content editor opens first: Listening, then Reading, then Writing, then any other module.
     */
    public function firstModule(Test $test): ?TestType
    {
        $order = array_flip(self::MODULE_TYPES);

        return TestType::query()
            ->with('type')
            ->where('test_id', $test->id)
            ->orderBy('id')
            ->get()
            ->sortBy(fn (TestType $tt) => [$order[$tt->type?->name] ?? 99, $tt->id])
            ->first();
    }

    /**
     * A test may be marked ready when it has at least one L/R/W module with parts and every
     * such module passes the readiness check.
     *
     * @return array{ready: bool, modules: array<int, array<string, mixed>>}
     */
    public function testReadiness(Test $test): array
    {
        $modules = $this->testModules($test)->filter(fn (TestType $tt) => $tt->parts_count > 0)->values();

        $report = $modules->map(function (TestType $tt) {
            $issues = $this->moduleIssues($tt);

            return [
                'id' => $tt->id,
                'type' => $tt->type?->name,
                'parts_count' => $tt->parts_count,
                'issues' => $issues,
                'ready' => $issues === [],
            ];
        })->all();

        return [
            'ready' => $modules->isNotEmpty() && collect($report)->every(fn ($m) => $m['ready']),
            'modules' => $report,
        ];
    }

    /**
     * Modules a mock may use: L/R/W modules with parts of ready Mock Bank tests.
     *
     * @return Collection<int, TestType>
     */
    public function availableModules(): Collection
    {
        return TestType::query()
            ->with(['type', 'test:id,name,folder_id,purpose,bank_status'])
            ->whereHas('test', fn ($q) => $q->mock()->where('bank_status', Test::BANK_READY))
            ->whereHas('type', fn ($q) => $q->whereIn('name', self::MODULE_TYPES))
            ->whereHas('parts')
            ->orderBy('id')
            ->get();
    }

    public function isRecentlyUsed(TestType $testType): bool
    {
        return $testType->last_used_at !== null
            && $testType->last_used_at->gt(now()->subDays($this->reuseDays()));
    }

    /**
     * Least recently used ready module per type, skipping modules used within the reuse window.
     *
     * @return array<string, TestType|null> keyed by type name
     */
    public function autoPick(): array
    {
        $available = $this->availableModules();
        $picked = [];

        foreach (self::MODULE_TYPES as $typeName) {
            $picked[$typeName] = $available
                ->filter(fn (TestType $tt) => $tt->type?->name === $typeName && ! $this->isRecentlyUsed($tt))
                ->sortBy(fn (TestType $tt) => [$tt->last_used_at?->getTimestamp() ?? 0, $tt->id])
                ->first();
        }

        return $picked;
    }

    /**
     * Replace the mock's modules. attempts.test_id-compatible mocks.test_id becomes the first module's test,
     * and modules that were (re)assigned get last_used_at = now.
     *
     * @param  array<int>  $testTypeIds
     */
    public function syncModules(Mock $mock, array $testTypeIds): void
    {
        $order = array_flip(self::MODULE_TYPES);

        $modules = TestType::query()->with('type')->whereIn('id', $testTypeIds)->get()
            ->sortBy(fn (TestType $tt) => $order[$tt->type?->name] ?? 99)
            ->values();

        DB::transaction(function () use ($mock, $modules) {
            $existing = MockModule::where('mock_id', $mock->id)->pluck('test_type_id')->map(fn ($id) => (int) $id)->all();
            $new = $modules->pluck('id')->map(fn ($id) => (int) $id)->all();

            MockModule::where('mock_id', $mock->id)->whereNotIn('test_type_id', $new)->delete();

            foreach ($modules as $module) {
                MockModule::updateOrCreate(
                    ['mock_id' => $mock->id, 'type_id' => $module->type_id],
                    ['test_type_id' => $module->id],
                );
            }

            $changed = array_values(array_diff($new, $existing));
            if ($changed !== []) {
                TestType::whereIn('id', $changed)->update(['last_used_at' => now()]);
            }

            if ($modules->isNotEmpty()) {
                $mock->forceFill(['test_id' => $modules->first()->test_id])->save();
            }
        });
    }

    /**
     * How many mocks used each module (mock_modules plus legacy mocks.test_id).
     *
     * @param  array<int>  $testTypeIds
     * @return array<int, int>
     */
    public function usageCounts(array $testTypeIds): array
    {
        return MockModule::query()
            ->whereIn('test_type_id', $testTypeIds)
            ->selectRaw('test_type_id, COUNT(DISTINCT mock_id) as uses')
            ->groupBy('test_type_id')
            ->pluck('uses', 'test_type_id')
            ->map(fn ($n) => (int) $n)
            ->all();
    }
}
