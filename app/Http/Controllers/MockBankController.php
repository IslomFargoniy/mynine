<?php

namespace App\Http\Controllers;

use App\Jobs\ImportMockModuleJob;
use App\Models\Folder;
use App\Models\Test;
use App\Models\TestImport;
use App\Models\TestType;
use App\Models\Type;
use App\Services\AudioUploadService;
use App\Services\Import\MockTestImporter;
use App\Services\Import\MockTestPdfParser;
use App\Services\MockBankService;
use App\Support\CurrentCenter;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Mock Bank (the center's Admin): the center's tests with purpose=mock (Test::query() and {test} are limited
 * to the current center's Mock Bank tests by CenterScope), listed per module with readiness and reuse info.
 */
class MockBankController extends Controller
{
    public function __construct(
        private readonly MockBankService $bank,
        private readonly MockTestImporter $importer,
        private readonly AudioUploadService $audio,
    ) {}

    public function index(Request $request): Response
    {
        $this->authorize('manageBank', Test::class);

        $status = $request->query('status');
        $search = trim((string) $request->query('search', ''));

        $tests = Test::query()
            ->mock()
            ->with(['folder:id,name', 'latestImport'])
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
                    'questions_count' => $tt->parts_count > 0 ? $this->bank->questionCount($tt) : 0,
                    'issues' => $issues,
                    'ready' => $issues === [],
                    'uses' => $uses[$tt->id] ?? 0,
                    'last_used_at' => $tt->last_used_at?->toIso8601String(),
                    'recently_used' => $this->bank->isRecentlyUsed($tt),
                ];
            })->values();

            $withContent = $modules->where('parts_count', '>', 0);
            $editModule = $modules->firstWhere('type', 'Listening') ?? $modules->firstWhere('type', 'Reading') ?? $modules->first();

            return [
                'id' => $test->id,
                'name' => $test->name,
                'folder' => $test->folder?->only(['id', 'name']),
                'bank_status' => $test->bank_status,
                'created_at' => $test->created_at?->toIso8601String(),
                'modules' => $modules,
                'edit_module_id' => $editModule['id'] ?? null,
                'can_be_ready' => $withContent->isNotEmpty() && $withContent->every(fn ($m) => $m['ready']),
                'import' => $this->importSummary($test->latestImport),
            ];
        })->values();

        return Inertia::render('mock-bank/index', [
            'tests' => $rows,
            // Moving a test to the public practice Test Bank is the platform owner's decision.
            'folders' => Gate::allows('manage-content') ? Folder::query()->select('id', 'name')->orderBy('name')->get() : [],
            // Only while the platform owner works as the Mynine center (not when acting as a partner center).
            'canMoveToPractice' => Gate::allows('manage-content') && app(CurrentCenter::class)->isMynine(app(CurrentCenter::class)->id()),
            'reuseDays' => $this->bank->reuseDays(),
            'filters' => ['status' => $status, 'search' => $search],
        ]);
    }

    public function updateStatus(Request $request, Test $test): RedirectResponse
    {
        $this->authorize('manageBank', Test::class);
        abort_unless($test->isMock(), 404);
        $this->authorize('update', $test);

        $data = $request->validate([
            'status' => ['required', Rule::in([Test::BANK_DRAFT, Test::BANK_READY, Test::BANK_ARCHIVED])],
        ]);

        if ($data['status'] === Test::BANK_READY && ! $this->bank->testReadiness($test)['ready']) {
            return back()->with('error', __('bank_test_not_ready'));
        }

        $test->forceFill(['bank_status' => $data['status']])->save();

        return back()->with('success', __('status_updated'));
    }

    /**
     * Turn a Mock Bank test into an open practice test. Practice tests are listed by folder,
     * so the admin picks the folder it moves into.
     */
    public function toPractice(Request $request, Test $test): RedirectResponse
    {
        $this->authorize('manageBank', Test::class);
        Gate::authorize('manage-content');
        $current = app(CurrentCenter::class);
        abort_unless($current->isMynine($current->id()), 403);
        if (! $test->isMock()) {
            // Already a practice test (e.g. a double click): nothing to do.
            return back()->with('success', __('test_already_practice'));
        }

        $data = $request->validate([
            'folder_id' => ['required', 'integer', 'exists:folders,id'],
        ]);

        // A mock still sits (or has results on) one of its modules: it must stay a Mock Bank test.
        if ($test->inUse()) {
            return back()->with('error', __('test_in_use_cannot_move'));
        }

        $test->forceFill(['purpose' => Test::PURPOSE_PRACTICE, 'open' => 1, 'folder_id' => $data['folder_id']])->save();

        return back()->with('success', __('test_moved_to_practice'));
    }

    /**
     * "Import from PDF": store the uploaded files and queue one AI import job per module.
     */
    public function import(Request $request, Test $test): RedirectResponse
    {
        $this->authorize('manageBank', Test::class);
        abort_unless($test->isMock(), 404);
        $this->authorize('update', $test);

        $document = ['nullable', 'file', 'mimes:pdf,docx,txt', 'max:20480'];
        $data = $request->validate([
            'listening_file' => $document,
            'reading_file' => $document,
            'writing_file' => $document,
            'answers_file' => $document,
            // 95 MB: the server takes 100 MB per request (nginx client_max_body_size, PHP post_max_size).
            'listening_audio' => ['nullable', 'file', 'mimes:mp3,wav,ogg,m4a,aac,mpeg,mpga', 'max:97280'],
            'replace' => ['nullable', 'boolean'],
        ]);

        $modules = array_values(array_filter(MockTestPdfParser::MODULES, fn ($m) => $request->hasFile(strtolower($m).'_file')));
        if ($modules === []) {
            // Audio on its own: just attach it to the test, no AI import.
            if ($request->hasFile('listening_audio')) {
                $audio = $this->audio->store($request->file('listening_audio'), $test->audio_path);
                $test->forceFill(['audio_path' => $audio['path'], 'playtime_seconds' => $audio['playtime']])->save();

                return back()->with('success', __('Listening audio saved.'));
            }

            throw ValidationException::withMessages(['listening_file' => __('Upload a Listening, Reading or Writing file.')]);
        }

        if (TestImport::where('test_id', $test->id)->whereIn('status', [TestImport::QUEUED, TestImport::RUNNING])->exists()) {
            throw ValidationException::withMessages(['listening_file' => __('An import of this test is still running.')]);
        }

        $replace = (bool) ($data['replace'] ?? false);
        $testTypes = [];
        foreach ($modules as $module) {
            $testTypes[$module] = $this->moduleOf($test, $module);
            if ($reason = $this->importer->refusal($testTypes[$module], $replace)) {
                throw ValidationException::withMessages([strtolower($module).'_file' => "{$module}: {$reason}"]);
            }
        }

        if ($request->hasFile('listening_audio')) {
            $audio = $this->audio->store($request->file('listening_audio'), $test->audio_path);
            $test->forceFill(['audio_path' => $audio['path'], 'playtime_seconds' => $audio['playtime']])->save();
        }

        $import = TestImport::create([
            'owner_id' => $test->owner_id,
            'test_id' => $test->id,
            'user_id' => $request->user()->id,
            'status' => TestImport::QUEUED,
            'replace' => $replace,
            'modules' => collect($modules)->mapWithKeys(fn ($m) => [$m => ['status' => TestImport::QUEUED, 'warnings' => []]])->all(),
        ]);

        $dir = ImportMockModuleJob::directory($test->id, $import->id);
        $files = [];
        foreach (['listening', 'reading', 'writing', 'answers'] as $key) {
            if ($request->hasFile("{$key}_file")) {
                $file = $request->file("{$key}_file");
                $files[$key] = $file->storeAs($dir, $key.'.'.strtolower($file->getClientOriginalExtension()), 'local');
            }
        }
        $import->forceFill(['files' => $files])->save();

        foreach ($modules as $module) {
            ImportMockModuleJob::dispatch($import->id, $module);
        }

        return back()->with('success', __('Import started. It takes a few minutes; the status is shown on the test card.'));
    }

    /**
     * The test's Listening / Reading / Writing module, created when the test does not have it yet.
     */
    private function moduleOf(Test $test, string $module): TestType
    {
        $type = Type::firstOrCreate(['name' => $module], ['minute' => $module === 'Listening' ? 30 : 60]);

        return TestType::firstOrCreate(['test_id' => $test->id, 'type_id' => $type->id])->load('test');
    }

    /**
     * @return array<string, mixed>|null
     */
    private function importSummary(?TestImport $import): ?array
    {
        if (! $import) {
            return null;
        }

        return [
            'id' => $import->id,
            'status' => $import->status,
            'created_at' => $import->created_at?->toIso8601String(),
            'finished_at' => $import->finished_at?->toIso8601String(),
            'modules' => collect($import->modules ?? [])->map(fn ($m, $name) => [
                'type' => $name,
                'status' => $m['status'] ?? TestImport::QUEUED,
                'message' => $m['message'] ?? null,
                'warnings' => array_values($m['warnings'] ?? []),
                'parts' => $m['parts'] ?? null,
                'questions' => $m['questions'] ?? null,
            ])->values()->all(),
        ];
    }
}
