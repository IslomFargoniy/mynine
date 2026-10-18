<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreMockRequest;
use App\Http\Requests\UpdateMockRequest;
use App\Models\Mock;
use App\Models\Test;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
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

        if ($request->from && $request->to) {
            $mock->whereBetween('created_at', [$request->from, $request->to]);
        }

        if ($request->user_id) {
            $mock->where(function ($query) use ($request) {
                $query->where('user_id', $request->user_id);
            });
        }

        if ($request->teacher_id) {
            $mock->where('user_id', $request->teacher_id);
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

        if (Auth::user()->hasRole('Admin')) {
            // Admin can see everything
        } elseif (Auth::user()->hasRole('Teacher')) {
            // Teacher can see their own mocks
            $mock->where(function ($q) {
                $q->where('user_id', Auth::id());
            });
        } else {
            // Students see active mocks
            $mock->where(function ($q) {
                $q->where('active', 1);
            });
        }

        $mock = $mock->select('id', 'test_id', 'user_id', 'name', 'comment', 'active', 'started_at', 'finished_at', 'created_at')
            ->orderBy('id', 'desc')
            ->paginate($per_page);

        // Filter tests and folders based on role for search dropdowns
        $tests_query = Test::query()->select('id', 'name', 'folder_id')->with('folder:id,name');
        $folders_query = \App\Models\Folder::select('id', 'name');

        if (Auth::user()->hasRole('Teacher')) {
            $tests_query->whereHas('folder', function ($q) {
                $q->where('user_id', Auth::id());
            });
            $folders_query->where('user_id', Auth::id());
        } elseif (! Auth::user()->hasRole('Admin')) {
            $tests_query->where('active', 1)->where('open', 1);
            $folders_query->where('active', 1);
        }

        $teachers = Auth::user()->hasRole('Admin')
            ? \App\Models\User\User::whereHas('roles', function ($q) {
                $q->where('name', 'Teacher');
            })->select('id', 'name')->get()
            : [];

        return Inertia::render('mock/index', [
            'mock' => $mock,
            'tests' => $tests_query->limit(50)->get(),
            'users' => [],
            'teachers' => $teachers,
            'folders' => $folders_query->limit(50)->get(),
            'isAdmin' => Auth::user()->hasRole('Admin'),
            'filters' => $request->only(['search', 'teacher_id', 'user_id', 'test_id', 'folder_id', 'from', 'to', 'per_page']),
        ]);
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreMockRequest $request)
    {
        $this->authorize('create', Mock::class);

        try {

            if (! Auth::user()->hasRole('Admin')) {
                $mock = Mock::query()->where('user_id', Auth::id())
                    ->whereMonth('created_at', now()->month)
                    ->whereYear('created_at', now()->year)
                    ->count();

                if ($mock >= 3) {
                    throw new \Exception(__('error.max_mocks_reached'));
                }
            }

            Mock::create($request->validated());

            return back()->with('success', __('success.mock_created'));
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
    public function show(Request $request, Mock $mock)
    {
        $this->authorize('view', $mock);

        $mock->load([
            'test.folder',
            'user:id,name',
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
            'isAdmin' => Auth::user()->hasRole('Admin'),
        ]);
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Mock $mock)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateMockRequest $request, Mock $mock)
    {
        $this->authorize('update', $mock);

        try {

            $mock->update($request->validated());

            return back()->with('success', __('success.mock_updated'));
        } catch (\Exception $e) {
            // Proper Inertia error response
            throw ValidationException::withMessages([
                'error' => [$e->getMessage()],
            ]);
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Mock $mock)
    {
        $this->authorize('delete', $mock);

        try {
            \Illuminate\Support\Facades\DB::transaction(function () use ($mock) {
                // Detach/nullify attempts so history is preserved without FK error
                \App\Models\Attempt::where('mock_id', $mock->id)->update(['mock_id' => null]);
                // Delete associated mock students
                $mock->students()->delete();
                // Delete the mock
                $mock->delete();
            });

            return redirect()->route('mock.index')->with('success', __('success.mock_deleted') ?? "Mock o'chirildi");
        } catch (\Exception $e) {
            return redirect()->route('mock.index')->withErrors([
                'error' => $e->getMessage(),
            ]);
        }
    }
}
