<?php

namespace App\Http\Controllers;

use App\Support\UserFacingError;
use App\Http\Requests\StoreMockRequest;
use App\Http\Requests\UpdateMockRequest;
use App\Models\Attempt;
use App\Models\Folder;
use App\Models\Mock;
use App\Models\MockStudent;
use App\Models\Test;
use App\Services\MockBankService;
use App\Support\DayRange;
use App\Support\FilterOptions;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;

class MockController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {

        $this->authorize('viewAny', Mock::class);

        $per_page = $request->per_page === 'all' ? 100 : min((int) ($request->per_page ?? 10), 100);

        $mock = Mock::with([
            'students.attempt',
            'modules.type',
            'modules.testType.test:id,name',
            'test.folder',
            'user:id,name',
        ]);

        if ($request->search) {
            $mock->where(function ($query) use ($request) {
                $query->where('name', 'like', "%$request->search%")
                    ->orWhere('comment', 'like', "%$request->search%")
                    ->orWhereHas('user', function ($q) use ($request) {
                        $q->where('name', 'like', "%$request->search%");
                    })
                    ->orWhereHas('test', function ($q) use ($request) {
                        $q->where('name', 'like', "%$request->search%");
                    });
            });
        }

        // Exam date (started_at), "to" day included.
        if ($range = DayRange::from($request->from, $request->to)) {
            $mock->whereBetween('started_at', $range);
        }

        if ($request->user_id) {
            $mock->where(function ($query) use ($request) {
                $query->where('user_id', $request->user_id);
            });
        }

        if ($request->test_id) {
            $mock->where(function ($query) use ($request) {
                $query->where('test_id', $request->test_id);
            });
        }

        if ($request->folder_id) {
            $mock->whereHas('test', function ($q) use ($request) {
                $q->where('folder_id', $request->folder_id);
            });
        }

        // Mock::query() lists only the current center's mocks (CenterScope).

        $mock = $mock->select('id', 'test_id', 'user_id', 'name', 'comment', 'active', 'require_desktop', 'started_at', 'finished_at', 'created_at')
            ->orderBy('id', 'desc')
            ->paginate($per_page)
            // Page links keep the filters (test, folder, dates...), not only the page number.
            ->withQueryString();

        // Filter tests and folders based on role for search dropdowns
        // Newest first; the filtered test/folder stays in its dropdown (FilterOptions::keep).
        $tests_query = Test::query()->select('id', 'name', 'folder_id')->with('folder:id,name')->orderByDesc('id');
        $folders_query = Folder::select('id', 'name')->orderByDesc('id');

        return Inertia::render('mock/index', [
            'mock' => $mock,
            'tests' => FilterOptions::keep($tests_query, $request->integer('test_id')),
            'users' => [],
            'folders' => FilterOptions::keep($folders_query, $request->integer('folder_id')),
            'isAdmin' => Auth::user()->isCenterAdmin(),
            'filters' => $request->only(['search', 'user_id', 'test_id', 'folder_id', 'from', 'to', 'per_page']),
        ]);
    }

    /**
     * Mock form: one ready Mock Bank module per type, auto pick, desktop and speaking settings.
     */
    public function create(Request $request, MockBankService $bank)
    {
        $this->authorize('create', Mock::class);

        // ?date=YYYY-MM-DD[ HH:MM] picks modules for that exam date (reuse rule), default now.
        $date = $request->filled('date') ? rescue(fn () => Carbon::parse($request->query('date')), null, false) : null;

        $props = ['mock' => null, ...$this->formProps($bank, $date)];

        // The mock modal loads the form data as JSON; a direct visit gets the full page.
        return $this->wantsFormJson($request) ? response()->json($props) : Inertia::render('mock/form', $props);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreMockRequest $request, MockBankService $bank)
    {
        $this->authorize('create', Mock::class);

        $mock = DB::transaction(function () use ($request, $bank) {
            $mock = Mock::create(collect($request->validated())->except('modules')->all());
            $bank->syncModules($mock, $request->moduleIds());

            return $mock;
        });

        return redirect()->route('mock.show', $mock)->with('success', __('success.mock_created'));
    }

    /**
     * Display the specified resource.
     */
    public function show(Request $request, Mock $mock)
    {
        $this->authorize('view', $mock);

        $mock->load([
            'test.folder',
            'user:id,name',
            'modules.testType.test:id,name',
            'modules.type',
            'students.attempt.attempt_types.type',
            'students.attempt.user',
            'students.attempt.mock',
            'students.attempt.test.folder',
            'attempts.test.folder',
            'attempts.user',
            'attempts.mock',
            'attempts.mockStudent',
            'attempts.attempt_types.type',
        ]);

        return Inertia::render('mock/show', [
            'mock' => $mock,
            'isAdmin' => Auth::user()->isCenterAdmin(),
        ]);
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Request $request, Mock $mock, MockBankService $bank)
    {
        $this->authorize('update', $mock);

        $mock->load(['modules.testType.test:id,name', 'modules.type', 'test:id,name']);

        $props = [
            'mock' => $mock,
            ...$this->formProps($bank, $mock->started_at ? Carbon::parse($mock->started_at) : null, $mock),
        ];

        return $this->wantsFormJson($request) ? response()->json($props) : Inertia::render('mock/form', $props);
    }

    /** A plain JSON request (the mock modal), not an Inertia visit. */
    private function wantsFormJson(Request $request): bool
    {
        return $request->wantsJson() && ! $request->header('X-Inertia');
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateMockRequest $request, Mock $mock, MockBankService $bank)
    {
        $this->authorize('update', $mock);

        DB::transaction(function () use ($request, $mock, $bank) {
            $data = collect($request->validated())->except('modules')->all();
            $mock->update($data);

            if ($request->moduleIds() !== []) {
                $bank->syncModules($mock, $request->moduleIds());
            }

            // The exam date may have moved: last_used_at shows the latest exam date of each module.
            $bank->refreshLastUsed($mock->modules()->pluck('test_type_id')->map(fn ($id) => (int) $id)->all());
        });

        // Edited in the modal: stay on the page it was opened from (list or mock page).
        if ($request->boolean('stay')) {
            return back()->with('success', __('success.mock_updated'));
        }

        return redirect()->route('mock.show', $mock)->with('success', __('success.mock_updated'));
    }

    /**
     * @return array<string, mixed>
     */
    private function formProps(MockBankService $bank, ?Carbon $date = null, ?Mock $mock = null): array
    {
        $available = $bank->availableModules();
        $ids = $available->pluck('id')->all();
        $uses = $bank->usageCounts($ids);
        $usage = $bank->usageDates($ids, $mock?->id);

        $modules = $available->map(fn ($tt) => [
            'id' => $tt->id,
            'type' => $tt->type?->name,
            'type_id' => $tt->type_id,
            'test_id' => $tt->test_id,
            'test_name' => $tt->test?->name,
            'last_used_at' => $tt->last_used_at?->toIso8601String(),
            'recently_used' => $bank->isRecentlyUsed($tt, $date, $mock?->id, $usage),
            // Exam dates of the other mocks using the module, so the form can re-check the reuse rule
            // when the exam date changes (|date - used| < reuseDays → warning).
            'used_on' => collect($usage[$tt->id] ?? [])->map(fn ($d) => $d->toIso8601String())->values(),
            'uses' => $uses[$tt->id] ?? 0,
        ])->values();

        return [
            'modules' => $modules,
            'autoPick' => collect($bank->autoPick($date, $mock?->id))->map(fn ($tt) => $tt?->id)->all(),
            'reuseDays' => $bank->reuseDays(),
            'modulesLocked' => $mock?->modulesLocked() ?? false,
        ];
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Request $request, Mock $mock)
    {
        $this->authorize('delete', $mock);

        // A candidate is still writing (or resuming) this mock: deleting it would break their exam.
        if ($mock->hasUnfinishedAttempt()) {
            return back()->with('error', __('mock_has_running_attempt'));
        }

        // Candidates of this mock sat a written module: the results (and the billing) stay; only the platform
        // owner may delete it. Its attempts keep their center (attempts.owner_id) and billing rows remain.
        if (! $request->user()->isSuperAdmin() && $mock->hasBilledCandidates()) {
            return back()->with('error', __('mock_has_exam_results'));
        }

        try {
            DB::transaction(function () use ($mock) {
                // Exam tokens of the candidates die with them (Sanctum tokens are polymorphic, no FK).
                $mock->students()->get()->each(fn (MockStudent $student) => $student->tokens()->delete());
                // Detach/nullify attempts so history is preserved without FK error
                Attempt::where('mock_id', $mock->id)->update(['mock_id' => null]);
                $mock->modules()->delete();
                // Delete associated mock students
                $mock->students()->delete();
                // Delete the mock
                $mock->delete();
            });

            return redirect()->route('mock.index')->with('success', __('success.mock_deleted'));
        } catch (\Exception $e) {
            return redirect()->route('mock.index')->withErrors([
                'error' => UserFacingError::message($e),
            ]);
        }
    }
}
