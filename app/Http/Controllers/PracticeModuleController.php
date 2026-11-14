<?php

namespace App\Http\Controllers;

use App\Models\Attempt;
use App\Models\Folder;
use App\Services\MockResultService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Inertia\Inertia;

/**
 * Listening / Reading / Writing on their own: the practice tests that have the module (by folder, as in the Test
 * Bank), each with "Start" for that module only, plus the student's own bands in it.
 */
class PracticeModuleController extends Controller
{
    public function index(Request $request, string $module, MockResultService $results)
    {
        abort_unless(isset(Attempt::PRACTICE_MODULES[$module]), 404);
        // Center staff run mocks, they do not practise (same rule as the Test Bank).
        if (! Gate::allows('manage-content') && $request->user()?->isStaff()) {
            return redirect()->route('dashboard');
        }

        $typeName = Attempt::PRACTICE_MODULES[$module];
        $hasModule = fn ($q) => $q->whereHas('parts')->whereHas('type', fn ($t) => $t->where('name', $typeName));

        $folders = Folder::query()
            ->where('active', 1)
            ->whereHas('tests', fn ($q) => $q->practice()->where('active', 1)->where('open', 1)->whereHas('types', $hasModule))
            ->with(['tests' => fn ($q) => $q->practice()->where('active', 1)->where('open', 1)
                ->whereHas('types', $hasModule)
                ->with(['types' => fn ($t) => $hasModule($t)->with('type:id,name,minute')])
                ->select('id', 'name', 'comment', 'folder_id', 'active', 'open')
                ->orderBy('id')])
            ->when($request->folder_id, fn ($q) => $q->whereKey($request->folder_id))
            ->when($request->search, fn ($q) => $q->where('name', 'like', '%'.$request->search.'%'))
            ->select('id', 'name', 'comment')
            ->orderBy('id')
            ->get();

        // The student's own finished attempts of this module: band per attempt.
        $mine = Attempt::query()
            ->where('user_id', $request->user()->id)
            ->whereNull('mock_id')
            ->where('module', $module)
            ->whereNotNull('finished_at')
            ->with(['attempt_types.type', 'test:id,name,variant'])
            ->latest('finished_at')
            ->limit(200)
            ->get()
            ->map(fn (Attempt $a) => [
                'id' => $a->id,
                'test_id' => $a->test_id,
                'test' => $a->test?->name,
                'finished_at' => $a->finished_at,
                'band' => $results->attemptBands($a)[$module],
            ]);

        $bands = $mine->pluck('band')->filter(fn ($b) => $b !== null);
        $byTest = $mine->groupBy('test_id')->map(fn ($rows) => [
            'count' => $rows->count(),
            'best' => $rows->pluck('band')->filter(fn ($b) => $b !== null)->max(),
        ]);

        return Inertia::render('practice-module/index', [
            'module' => $module,
            'moduleName' => $typeName,
            'folders' => $folders,
            'byTest' => $byTest,
            'stats' => [
                'count' => $mine->count(),
                'best' => $bands->max(),
                'average' => $bands->isNotEmpty() ? round($bands->avg() * 2) / 2 : null,
            ],
            'recent' => $mine->take(5)->values(),
            'filters' => $request->only(['search', 'folder_id']),
        ]);
    }
}
