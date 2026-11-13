<?php

namespace App\Http\Controllers;

use App\Support\UserFacingError;
use App\Http\Requests\StoreAttemptRequest;
use App\Models\Attempt;
use App\Models\Folder;
use App\Models\Mock;
use App\Models\Test;
use App\Services\AttemptPdfRenderer;
use App\Services\ExamService;
use App\Services\MockResultService;
use App\Support\DayRange;
use App\Support\FilterOptions;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;

class AttemptController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $per_page = $request->per_page === 'all' ? 100 : min((int) ($request->per_page ?? 10), 100);

        $data = Attempt::with([
            'test.folder',
            'user',
            'mock',
            'mockStudent',
            'attempt_types.type',
        ])->orderBy('id', 'desc');

        // Attempt::query() is limited to the current center for staff (CenterScope); a center's Admin sees
        // all of it, anyone else only their own attempts.
        if (! Auth::user()->isCenterAdmin()) {
            $data = $data->where(function ($query) {
                $query->where('user_id', Auth::id())
                    ->orWhereHas('mock', function ($q) {
                        $q->where('user_id', Auth::id());
                    });
            });
        }

        // Exam date: the mock's started_at, or the attempt's own date for practice attempts; "to" day included.
        if ($range = DayRange::from($request->from, $request->to)) {
            $data->where(fn ($q) => $q
                ->whereHas('mock', fn ($m) => $m->withoutEagerLoads()->whereBetween('started_at', $range))
                ->orWhere(fn ($w) => $w->whereNull('mock_id')->whereBetween('created_at', $range)));
        }

        if ($request->user_id) {
            $data->where('user_id', $request->user_id);
        }

        if ($request->mock_id) {
            $data->where('mock_id', $request->mock_id);
        }

        if ($request->test_id) {
            $data->where('test_id', $request->test_id);
        }

        if ($request->folder_id) {
            $data->whereHas('test', function ($q) use ($request) {
                $q->where('folder_id', $request->folder_id);
            });
        }

        if ($request->search) {
            $data = $data->where(function ($query) use ($request) {
                $query->whereHas('test', function ($q) use ($request) {
                    $q->where('name', 'like', '%'.$request->search.'%');
                })
                    ->orWhereHas('mock', function ($q) use ($request) {
                        $q->where('name', 'like', '%'.$request->search.'%');
                    })
                    ->orWhereHas('user', function ($q) use ($request) {
                        $q->where('name', 'like', '%'.$request->search.'%')
                            ->orWhere('email', 'like', '%'.$request->search.'%');
                    });
            });
        }

        // Page links keep the filters (mock, test, dates...), not only the page number.
        $data = $data->paginate($per_page)->withQueryString();

        // Scores of a running attempt stay hidden from the candidate; visible rows get the server-computed
        // module band (attempt_types[].band, e.g. Writing = (T1 + 2*T2) / 3) for the list and the Excel export.
        $results = app(MockResultService::class);
        $data->getCollection()->each(function (Attempt $attempt) use ($results) {
            if (! $attempt->resultsVisibleTo(Auth::user())) {
                $attempt->attempt_types->each->hideResults();

                return;
            }

            $bands = $results->attemptBands($attempt);
            $attempt->attempt_types->each(fn ($type) => $type->setAttribute('band', $bands[strtolower((string) $type->type?->name)] ?? null));
        });

        // Filter dropdown options for search
        // Newest first (today's mock must be in the list); the filtered item stays in its dropdown.
        $mocks_query = Mock::withoutEagerLoads()->select('id', 'name')->orderByDesc('id');
        $tests_query = Test::select('id', 'name')->orderByDesc('id');
        $folders_query = Folder::select('id', 'name')->orderByDesc('id');

        if (! Auth::user()->isCenterAdmin()) {
            // Only mocks the user sat (never other centers' mock names).
            $mocks_query->whereHas('attempts', fn ($q) => $q->where('user_id', Auth::id()));
            $tests_query->practice()->where('active', 1)->where('open', 1);
            $folders_query->where('active', 1);
        }

        return Inertia::render('attempt/index', [
            'attempt' => $data,
            'users' => [],
            'mocks' => FilterOptions::keep($mocks_query, $request->integer('mock_id')),
            'tests' => FilterOptions::keep($tests_query, $request->integer('test_id')),
            'folders' => FilterOptions::keep($folders_query, $request->integer('folder_id')),
            'isAdmin' => Auth::user()->isCenterAdmin(),
            'filters' => $request->only(['search', 'user_id', 'mock_id', 'test_id', 'folder_id', 'from', 'to', 'per_page']),
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreAttemptRequest $request)
    {
        try {

            $test = Test::with('folder')->findOrFail($request->test_id);

            // Mock Bank tests are reachable only through a mock attempt (candidate code / desktop app).
            if ($test->isMock()) {
                throw new \Exception(__('error.unauthorized_attempt'));
            }

            if (! $request->mock_id) {
                if (! Auth::user()->can('attempt', $test)) {
                    throw new \Exception(__('error.unauthorized_attempt'));
                }

                $active = Attempt::where('user_id', Auth::id())
                    ->whereNull('finished_at')
                    ->first();

                if ($active) {
                    app(ExamService::class)->finishAttempt($active);
                }
            } else {
                $mock = Mock::findOrFail($request->mock_id);
                if ((int) $mock->test_id !== (int) $test->id) {
                    throw new \Exception(__('mock_other_test'));
                }
                switch ($mock->status) {
                    case 'inactive':
                        throw new \Exception(__('mock_inactive'));
                    case 'scheduled':
                        $formattedStart = Carbon::parse($mock->started_at)->format('d.m.Y H:i');
                        throw new \Exception(__('mock_not_started', ['time' => $formattedStart]));
                    case 'expired':
                        $formattedFinish = Carbon::parse($mock->finished_at)->format('d.m.Y H:i');
                        throw new \Exception(__('mock_finished', ['time' => $formattedFinish]));
                }
            }

            $data = $request->validated();
            $data['user_id'] = Auth::id();
            if (empty($data['name']) && Auth::check()) {
                $data['name'] = Auth::user()->name;
            }
            $data['started_at'] = date('Y-m-d H:i:s');
            $data['status'] = 1;

            $attempt = Attempt::create($data);

            return redirect()->route('practice.index', ['attempt_id' => $attempt->id]);

        } catch (\Exception $e) {
            // Proper Inertia error response
            throw ValidationException::withMessages([
                'error' => [UserFacingError::message($e)],
            ]);
        }
    }

    /**
     * Display the specified resource.
     */
    public function show(Attempt $attempt, MockResultService $results)
    {
        $this->authorize('view', $attempt);

        $attempt->load(['test.folder', 'user', 'mock', 'mockStudent', 'attempt_types']);

        // Answer keys, candidate answers with correctness and scores only once the attempt is finished
        // (graders: always) — same rule as AttemptPartController.
        $visible = $attempt->resultsVisibleTo(Auth::user());
        $attempt->attempt_types->each(function ($attemptType) use ($visible) {
            $visible ? $attemptType->append('attempt_parts') : $attemptType->hideResults();
        });

        $bands = $visible ? $results->attemptBands($attempt) : null;

        return Inertia::render('attempt/show', [
            'attempt' => $attempt,
            'results_visible' => $visible,
            // Server-computed bands (null while hidden): {listening, reading, writing, speaking, overall,
            // listening_correct, reading_correct, reading_variant, writing_confirmed, writing_pending}.
            'bands' => $bands,
            'writing_band' => $bands['writing'] ?? null,
        ]);
    }

    /**
     * Display the specified resource.
     */
    public function pdf(Request $request, Attempt $attempt)
    {
        // Links sent by email / Telegram are signed; everyone else must be allowed to view the attempt.
        if (! $request->hasValidSignature(false)) {
            $this->authorize('view', $attempt);
        }

        // No result sheet while the exam is running (graders excepted), signed link or not.
        abort_unless($attempt->resultsVisibleTo(Auth::user()), 403, 'Results are available after the attempt is finished.');

        ini_set('memory_limit', '1024M');
        ini_set('max_execution_time', '300');

        $output = app(AttemptPdfRenderer::class)->render($attempt);

        $filename = "IELTS_TRF_Attempt_{$attempt->id}_".$attempt->created_at->format('Y-m-d');

        return response($output, 200)
            ->header('Content-Type', 'application/pdf')
            ->header('Content-Disposition', 'inline; filename="'.$filename.'.pdf"');

    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Attempt $attempt)
    {
        $this->authorize('delete', $attempt);

        // A running (or resumable) exam must not lose its answers: finish it first.
        if ($attempt->finished_at === null) {
            return back()->with('error', __('attempt_not_finished'));
        }

        try {
            // AttemptObserver::deleting removes answers, options, parts and types
            DB::transaction(fn () => $attempt->delete());

            return redirect()->route('attempt.index')->with('success', __('deleted_successfully') ?? "Natija o'chirildi");
        } catch (\Exception $e) {
            return redirect()->route('attempt.index')->withErrors([
                'error' => UserFacingError::message($e),
            ]);
        }
    }
}
