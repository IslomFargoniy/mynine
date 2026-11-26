<?php

namespace App\Http\Controllers\Api\Student;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Models\Attempt;
use App\Models\Folder;
use App\Models\Test;
use App\Models\TestType;
use App\Services\ExamService;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Test Bank for the apps: active + open practice tests in active folders, only modules with content
 * (same rules as the website's Test Bank). Mock Bank tests never appear.
 */
class TestController extends Controller
{
    public function __construct(private readonly ExamService $exam) {}

    /**
     * GET /student/tests?search=&module=listening|reading|writing&full=1&folder_id=&page=
     * full=1: only full tests (every practice module has content).
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
            'module' => ['nullable', 'in:'.implode(',', array_keys(Attempt::PRACTICE_MODULES))],
            'folder_id' => ['nullable', 'integer'],
            'full' => ['nullable', 'boolean'],
        ]);

        $query = $this->visibleTests()->with('folder:id,name')->orderByDesc('id');

        if ($search = trim((string) $request->query('search'))) {
            $query->where(fn (Builder $q) => $q->where('name', 'like', "%{$search}%")
                ->orWhereHas('folder', fn ($f) => $f->where('name', 'like', "%{$search}%")));
        }
        if ($module = $request->query('module')) {
            $query->whereHas('types', fn ($t) => $t->whereHas('parts')
                ->whereHas('type', fn ($ty) => $ty->where('name', Attempt::PRACTICE_MODULES[$module])));
        }
        if ($request->boolean('full')) {
            foreach (Attempt::PRACTICE_MODULES as $name) {
                $query->whereHas('types', fn ($t) => $t->whereHas('parts')
                    ->whereHas('type', fn ($ty) => $ty->where('name', $name)));
            }
        }
        if ($request->filled('folder_id')) {
            $query->where('folder_id', $request->integer('folder_id'));
        }

        $page = $query->paginate(30);
        $tests = collect($page->items());

        return response()->json([
            'data' => $this->testPayloads($tests, $request->user()->id),
            'folders' => Folder::query()->where('active', 1)
                ->whereHas('tests', fn ($q) => $q->practice()->where('active', 1)->where('open', 1))
                ->orderBy('id')->get(['id', 'name'])
                ->map(fn ($f) => ['id' => (int) $f->id, 'name' => $f->name])->all(),
            'meta' => [
                'current_page' => $page->currentPage(),
                'last_page' => $page->lastPage(),
                'total' => $page->total(),
            ],
        ]);
    }

    /**
     * GET /student/tests/{test}
     */
    public function show(Request $request, int $test): JsonResponse
    {
        $model = $this->visibleTests()->with('folder:id,name')->whereKey($test)->first();
        if (! $model) {
            throw ApiException::notFound('Test not found.');
        }

        return response()->json(['test' => $this->testPayloads(collect([$model]), $request->user()->id)[0]]);
    }

    private function visibleTests(): Builder
    {
        return Test::query()->practice()
            ->where('active', 1)->where('open', 1)
            ->whereHas('folder', fn ($f) => $f->where('active', 1))
            ->whereHas('types', fn ($t) => $t->whereHas('parts'));
    }

    /**
     * @param  Collection<int, Test>  $tests
     */
    private function testPayloads(Collection $tests, int $userId): array
    {
        if ($tests->isEmpty()) {
            return [];
        }

        $order = array_flip(Attempt::DESKTOP_MODULE_ORDER);
        $types = TestType::query()
            ->whereIn('test_id', $tests->pluck('id'))
            ->whereHas('parts')
            ->withCount('parts')
            ->get()
            ->filter(fn (TestType $tt) => isset($order[$tt->type?->name]))
            ->groupBy('test_id');

        $questionCounts = DB::table('questions')
            ->join('sections', 'sections.id', '=', 'questions.section_id')
            ->join('parts', 'parts.id', '=', 'sections.part_id')
            ->whereIn('parts.test_type_id', $types->flatten()->pluck('id'))
            ->groupBy('parts.test_type_id')
            ->pluck(DB::raw('COUNT(*)'), 'parts.test_type_id');

        $attempts = Attempt::query()->withoutEagerLoads()
            ->where('user_id', $userId)->whereNull('mock_id')
            ->whereIn('test_id', $tests->pluck('id'))
            ->orderByDesc('id')
            ->get(['id', 'test_id', 'module', 'finished_at'])
            ->groupBy('test_id');

        return $tests->map(function (Test $test) use ($types, $questionCounts, $attempts, $order) {
            $mine = $attempts->get($test->id) ?? collect();
            $running = $mine->first(fn ($a) => $a->finished_at === null);

            return [
                'id' => (int) $test->id,
                'name' => $test->name,
                'comment' => $test->comment,
                'variant' => $test->variant,
                'folder' => $test->folder ? ['id' => (int) $test->folder->id, 'name' => $test->folder->name] : null,
                'modules' => ($types->get($test->id) ?? collect())
                    ->unique('type_id')
                    ->sortBy(fn (TestType $tt) => $order[$tt->type->name])
                    ->values()
                    ->map(fn (TestType $tt) => [
                        'type_id' => (int) $tt->type_id,
                        'type' => strtolower($tt->type->name),
                        'title' => $tt->type->name,
                        'duration_seconds' => $this->exam->moduleDurationSeconds($tt),
                        'parts_count' => (int) $tt->parts_count,
                        'questions_count' => (int) ($questionCounts[$tt->id] ?? 0),
                    ])->all(),
                'attempts_count' => $mine->count(),
                'in_progress_attempt_id' => $running ? (int) $running->id : null,
                'last_finished_attempt_id' => ($last = $mine->first(fn ($a) => $a->finished_at !== null)) ? (int) $last->id : null,
            ];
        })->values()->all();
    }
}
