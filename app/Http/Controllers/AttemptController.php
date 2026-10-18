<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreAttemptRequest;
use App\Models\Attempt;
use Dompdf\Dompdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
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

        if (! Auth::user()->hasRole('Admin')) {
            $data = $data->where(function ($query) {
                $query->where('user_id', Auth::id())
                    ->orWhereHas('mock', function ($q) {
                        $q->where('user_id', Auth::id());
                    });
            });
        }

        if ($request->from && $request->to) {
            $data->whereBetween('created_at', [$request->from, $request->to]);
        }

        if ($request->user_id) {
            $data->where('user_id', $request->user_id);
        }

        if ($request->teacher_id) {
            $teacherId = $request->teacher_id;
            $data->where(function ($q) use ($teacherId) {
                $q->whereHas('mock', function ($mq) use ($teacherId) {
                    $mq->where('user_id', $teacherId);
                })->orWhereHas('test.folder', function ($fq) use ($teacherId) {
                    $fq->where('user_id', $teacherId);
                });
            });
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

        $data = $data->paginate($per_page);

        // Filter dropdown options for search
        $mocks_query = \App\Models\Mock::select('id', 'name');
        $tests_query = \App\Models\Test::select('id', 'name');
        $folders_query = \App\Models\Folder::select('id', 'name');

        if (Auth::user()->hasRole('Teacher')) {
            $mocks_query->where('user_id', Auth::id());
            $tests_query->whereHas('folder', function ($q) {
                $q->where('user_id', Auth::id());
            });
            $folders_query->where('user_id', Auth::id());
        } elseif (! Auth::user()->hasRole('Admin')) {
            $mocks_query->where('active', 1);
            $tests_query->where('active', 1)->where('open', 1);
            $folders_query->where('active', 1);
        }

        $teachers = Auth::user()->hasRole('Admin')
            ? \App\Models\User\User::whereHas('roles', function ($q) {
                $q->where('name', 'Teacher');
            })->select('id', 'name')->get()
            : [];

        return Inertia::render('attempt/index', [
            'attempt' => $data,
            'users' => [],
            'teachers' => $teachers,
            'mocks' => $mocks_query->limit(50)->get(),
            'tests' => $tests_query->limit(50)->get(),
            'folders' => $folders_query->limit(50)->get(),
            'isAdmin' => Auth::user()->hasRole('Admin'),
            'filters' => $request->only(['search', 'teacher_id', 'user_id', 'mock_id', 'test_id', 'folder_id', 'from', 'to', 'per_page']),
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreAttemptRequest $request)
    {
        try {

            $test = \App\Models\Test::with('folder')->findOrFail($request->test_id);

            if (! $request->mock_id) {
                if (! Auth::user()->can('attempt', $test)) {
                    throw new \Exception(__('error.unauthorized_attempt'));
                }

                $active = Attempt::where('user_id', Auth::id())
                    ->whereNull('finished_at')
                    ->first();

                if ($active) {
                    $active->finish();
                }
            } else {
                $mock = \App\Models\Mock::findOrFail($request->mock_id);
                if ((int) $mock->test_id !== (int) $test->id) {
                    throw new \Exception('Mock test boshqa testga tegishli!');
                }
                switch ($mock->status) {
                    case 'inactive':
                        throw new \Exception('Ushbu Mock test hozirda faol emas!');
                    case 'scheduled':
                        $formattedStart = \Carbon\Carbon::parse($mock->started_at)->format('d.m.Y H:i');
                        throw new \Exception("Ushbu Mock test hali boshlanmagan! Boshlanish vaqti: {$formattedStart}");
                    case 'expired':
                        $formattedFinish = \Carbon\Carbon::parse($mock->finished_at)->format('d.m.Y H:i');
                        throw new \Exception("Ushbu Mock test vaqti tugagan! Yakunlangan vaqti: {$formattedFinish}");
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
                'error' => [$e->getMessage()],
            ]);
        }
    }

    /**
     * Display the specified resource.
     */
    public function show(Attempt $attempt)
    {
        $this->authorize('view', $attempt);

        $attempt->load(['test.folder', 'user', 'mock', 'mockStudent', 'attempt_types']);
        // Append attempt_parts only for detail view
        $attempt->attempt_types->each(function ($attemptType) {
            $attemptType->append('attempt_parts');
        });

        return Inertia::render('attempt/show', [
            'attempt' => $attempt,
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

        ini_set('memory_limit', '1024M');
        ini_set('max_execution_time', '300');

        $attempt = $attempt->load([
            'test.folder',
            'user',
            'mock',
            'mockStudent',
            'attempt_types.type',
        ]);

        // Append attempt_parts for PDF view
        $attempt->attempt_types->each(function ($attemptType) {
            $attemptType->append('attempt_parts');
        });

        $options = [
            'isPhpEnabled' => false,
            'isRemoteEnabled' => true,
            'isHtml5ParserEnabled' => true,
            'isFontSubsettingEnabled' => true,
            'isUnicodeEnabled' => true,
            'defaultFont' => 'DejaVu Sans',
        ];

        $dompdf = new Dompdf($options);
        $dompdf->loadHtml(view('pdf.attempt', compact('attempt'))->render());
        $dompdf->setPaper('A4', 'portrait');
        $dompdf->render();

        // Add page numbers to the footer
        $canvas = $dompdf->getCanvas();
        $canvas->page_text(520, 815, '{PAGE_NUM} / {PAGE_COUNT}', null, 9, [0.4, 0.4, 0.4]);

        $filename = "IELTS_TRF_Attempt_{$attempt->id}_".$attempt->created_at->format('Y-m-d');

        return response($dompdf->output(), 200)
            ->header('Content-Type', 'application/pdf')
            ->header('Content-Disposition', 'inline; filename="'.$filename.'.pdf"');

    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Attempt $attempt)
    {
        $this->authorize('delete', $attempt);

        try {
            // AttemptObserver::deleting removes answers, options, parts and types
            \Illuminate\Support\Facades\DB::transaction(fn () => $attempt->delete());

            return redirect()->route('attempt.index')->with('success', __('deleted_successfully') ?? "Natija o'chirildi");
        } catch (\Exception $e) {
            return redirect()->route('attempt.index')->withErrors([
                'error' => $e->getMessage(),
            ]);
        }
    }
}
