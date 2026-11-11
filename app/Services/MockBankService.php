<?php

namespace App\Services;

use App\Models\Mock;
use App\Models\MockModule;
use App\Models\Part;
use App\Models\Question;
use App\Models\Test;
use App\Models\TestType;
use Carbon\Carbon;
use Carbon\CarbonInterface;
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

    public const QUESTIONS_PER_PAPER = 40;

    public function reuseDays(): int
    {
        return (int) config('desktop.module_reuse_days', 14);
    }

    /**
     * Problems that keep a module out of the "ready" state (empty = ready).
     *
     * @return array<int, string> machine codes: no_parts, no_questions, missing_answer_keys:<n>, question_count:<n>, no_audio,
     *                            writing_tasks:<n>, writing_no_prompt, writing_no_image
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

            // A full Listening / Reading paper has 40 numbered questions. A "choose TWO" question
            // covers as many numbers as it has correct options (same rule as the exam payload).
            $numbers = $this->countNumbers(clone $questions);

            $expected = config('desktop.questions_per_paper', self::QUESTIONS_PER_PAPER);
            if ($expected && $numbers !== (int) $expected) {
                $issues[] = 'question_count:'.$numbers;
            }
        }

        if ($typeName === 'Writing') {
            array_push($issues, ...$this->writingIssues($partIds->all()));
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
     * How many numbered questions a module holds (a "choose TWO" question counts as two), as shown on the bank card.
     */
    public function questionCount(TestType $testType): int
    {
        $partIds = Part::withoutEagerLoads()->where('test_type_id', $testType->id)->pluck('id');
        if ($partIds->isEmpty()) {
            return 0;
        }

        return $this->countNumbers(Question::withoutEagerLoads()
            ->whereHas('section', fn ($q) => $q->withoutEagerLoads()->whereIn('part_id', $partIds)));
    }

    private function countNumbers($questions): int
    {
        return (int) $questions->with('options:id,question_id,is_correct')->get()
            ->sum(fn (Question $q) => $q->options->isEmpty() ? 1 : max(1, $q->options->where('is_correct', true)->count()));
    }

    /**
     * Writing is ready with two essay tasks that each have a prompt, and a Task 1 picture unless Task 1 is a
     * General Training letter.
     *
     * @param  array<int, int>  $partIds
     * @return array<int, string>
     */
    private function writingIssues(array $partIds): array
    {
        $tasks = Part::withoutEagerLoads()
            ->whereIn('id', $partIds)
            ->whereHas('sections', fn ($q) => $q->withoutEagerLoads()->whereHas('question_type', fn ($t) => $t->where('type', 'essay'))->whereHas('questions'))
            ->with(['sections' => fn ($q) => $q->withoutEagerLoads()->select('id', 'part_id', 'textarea')])
            ->orderBy('id')
            ->get(['id', 'textarea']);

        if ($tasks->isEmpty()) {
            return ['writing_tasks:0'];
        }

        $issues = [];
        if ($tasks->count() !== 2) {
            $issues[] = 'writing_tasks:'.$tasks->count();
        }

        $html = fn (Part $part) => $part->textarea.' '.$part->sections->pluck('textarea')->implode(' ');
        $text = fn (Part $part) => trim(preg_replace('/\s+/', ' ', strip_tags($html($part))));

        if ($tasks->contains(fn (Part $part) => mb_strlen($text($part)) < 20)) {
            $issues[] = 'writing_no_prompt';
        }

        $first = $tasks->first();
        $isLetter = (bool) preg_match('/\b(write|writing)\s+(a|an)\s+(\w+\s+)?letter\b|\bDear\s+(Sir|Madam|[A-Z])/i', $text($first));
        if (! $isLetter && ! preg_match('/<img\b/i', $html($first))) {
            $issues[] = 'writing_no_image';
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

    /**
     * Exam dates (mocks.started_at) of the mocks using each module, optionally without one mock.
     *
     * @param  array<int>|null  $testTypeIds  null = every module
     * @return array<int, array<int, Carbon>> test_type_id => dates
     */
    public function usageDates(?array $testTypeIds = null, ?int $exceptMockId = null): array
    {
        return MockModule::query()
            ->join('mocks', 'mocks.id', '=', 'mock_modules.mock_id')
            ->whereNotNull('mocks.started_at')
            ->when($testTypeIds !== null, fn ($q) => $q->whereIn('mock_modules.test_type_id', $testTypeIds))
            ->when($exceptMockId, fn ($q) => $q->where('mock_modules.mock_id', '!=', $exceptMockId))
            ->get(['mock_modules.test_type_id', 'mocks.started_at'])
            ->groupBy('test_type_id')
            ->map(fn ($rows) => $rows->map(fn ($row) => Carbon::parse($row->started_at))->sort()->values()->all())
            ->all();
    }

    /**
     * Reuse rule: a module is "recently used" when another mock using it takes place within reuseDays()
     * of the target date (before or after). The target defaults to now; the mock form passes the mock's date.
     *
     * @param  array<int, array<int, Carbon>>|null  $usage  precomputed usageDates()
     */
    public function isRecentlyUsed(TestType $testType, ?CarbonInterface $date = null, ?int $exceptMockId = null, ?array $usage = null): bool
    {
        $usage ??= $this->usageDates([$testType->id], $exceptMockId);
        $date = Carbon::instance($date ?? now());
        $days = $this->reuseDays();

        foreach ($usage[$testType->id] ?? [] as $used) {
            if (abs($used->diffInSeconds($date, false)) < $days * 86400) {
                return true;
            }
        }

        return false;
    }

    /**
     * Least recently used ready module per type, skipping modules used within the reuse window around the
     * target date.
     *
     * @return array<string, TestType|null> keyed by type name
     */
    public function autoPick(?CarbonInterface $date = null, ?int $exceptMockId = null): array
    {
        $available = $this->availableModules();
        $usage = $this->usageDates($available->pluck('id')->all(), $exceptMockId);
        $picked = [];

        foreach (self::MODULE_TYPES as $typeName) {
            $picked[$typeName] = $available
                ->filter(fn (TestType $tt) => $tt->type?->name === $typeName && ! $this->isRecentlyUsed($tt, $date, $exceptMockId, $usage))
                ->sortBy(fn (TestType $tt) => [collect($usage[$tt->id] ?? [])->last()?->getTimestamp() ?? 0, $tt->id])
                ->first();
        }

        return $picked;
    }

    /**
     * test_types.last_used_at = the latest exam date of the mocks using the module (display only).
     *
     * @param  array<int>  $testTypeIds
     */
    public function refreshLastUsed(array $testTypeIds): void
    {
        $latest = $this->usageDates($testTypeIds);

        foreach (array_unique($testTypeIds) as $id) {
            $dates = $latest[$id] ?? [];
            TestType::whereKey($id)->update(['last_used_at' => $dates === [] ? null : end($dates)]);
        }
    }

    /**
     * Replace the mock's modules. attempts.test_id-compatible mocks.test_id becomes the first module's test,
     * and last_used_at of every touched module is recomputed from the mocks' exam dates.
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

            $this->refreshLastUsed(array_merge($new, $existing));

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
