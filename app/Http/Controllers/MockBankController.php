<?php

namespace App\Http\Controllers;

use App\Models\Folder;
use App\Models\Test;
use App\Services\MockBankService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Mock Bank (Admin): tests with purpose=mock, listed per module with readiness and reuse info.
 */
class MockBankController extends Controller
{
    public function __construct(private readonly MockBankService $bank) {}

    public function index(Request $request): Response
    {
        $this->authorize('manageBank', Test::class);

        $status = $request->query('status');
        $search = trim((string) $request->query('search', ''));

        $tests = Test::query()
            ->mock()
            ->with('folder:id,name')
            ->when(in_array($status, [Test::BANK_DRAFT, Test::BANK_READY, Test::BANK_ARCHIVED], true), fn ($q) => $q->where('bank_status', $status))
            ->when($search !== '', fn ($q) => $q->where('name', 'like', "%{$search}%"))
            ->orderByDesc('id')
            ->get(['id', 'folder_id', 'name', 'audio_path', 'bank_status', 'created_at']);

        $allModules = $tests->mapWithKeys(fn (Test $test) => [$test->id => $this->bank->testModules($test)]);
        $uses = $this->bank->usageCounts($allModules->flatten(1)->pluck('id')->all());

        $rows = $tests->map(function (Test $test) use ($allModules, $uses) {
            $modules = $allModules[$test->id]->map(function ($tt) use ($uses) {
                $issues = $tt->parts_count > 0 ? $this->bank->moduleIssues($tt) : ['no_parts'];

                return [
                    'id' => $tt->id,
                    'type' => $tt->type?->name,
                    'parts_count' => $tt->parts_count,
                    'issues' => $issues,
                    'ready' => $issues === [],
                    'uses' => $uses[$tt->id] ?? 0,
                    'last_used_at' => $tt->last_used_at?->toIso8601String(),
                    'recently_used' => $this->bank->isRecentlyUsed($tt),
                ];
            })->values();

            $withContent = $modules->where('parts_count', '>', 0);

            return [
                'id' => $test->id,
                'name' => $test->name,
                'folder' => $test->folder?->only(['id', 'name']),
                'bank_status' => $test->bank_status,
                'created_at' => $test->created_at?->toIso8601String(),
                'modules' => $modules,
                'can_be_ready' => $withContent->isNotEmpty() && $withContent->every(fn ($m) => $m['ready']),
            ];
        })->values();

        return Inertia::render('mock-bank/index', [
            'tests' => $rows,
            'folders' => Folder::query()->select('id', 'name')->orderBy('name')->get(),
            'reuseDays' => $this->bank->reuseDays(),
            'filters' => ['status' => $status, 'search' => $search],
        ]);
    }

    public function updateStatus(Request $request, Test $test): RedirectResponse
    {
        $this->authorize('manageBank', Test::class);
        abort_unless($test->isMock(), 404);

        $data = $request->validate([
            'status' => ['required', Rule::in([Test::BANK_DRAFT, Test::BANK_READY, Test::BANK_ARCHIVED])],
        ]);

        if ($data['status'] === Test::BANK_READY && ! $this->bank->testReadiness($test)['ready']) {
            return back()->with('error', "Test tayyor emas: har bir modulda partlar, javob kalitlari va (Listening uchun) audio bo'lishi kerak.");
        }

        $test->forceFill(['bank_status' => $data['status']])->save();

        return back()->with('success', 'Holat yangilandi.');
    }

    /**
     * Turn a Mock Bank test into an open practice test.
     */
    public function toPractice(Test $test): RedirectResponse
    {
        $this->authorize('manageBank', Test::class);
        if (! $test->isMock()) {
            // Already a practice test (e.g. a double click): nothing to do.
            return back()->with('success', 'Test allaqachon amaliyot (practice) testlarida.');
        }

        $test->forceFill(['purpose' => Test::PURPOSE_PRACTICE, 'open' => 1])->save();

        return back()->with('success', "Test amaliyot (practice) testlariga o'tkazildi.");
    }
}
