<?php

namespace App\Http\Controllers;

use App\Models\Folder;
use App\Models\Test;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Inertia\Inertia;

class AllTestController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $per_page = $request->per_page === 'all' ? 100 : min((int) ($request->per_page ?? 10), 100);

        $folder = Folder::with([
            'tests' => function ($query) {
                $query->with([
                    'types' => function ($query) {
                        $query->whereHas('parts');
                    },
                ])
                    ->withCount('attempts')
                    ->where('active', 1)
                    ->where('open', 1)
                    ->orderBy('id', 'asc');
            },
        ])
            ->whereHas('tests', function ($query) {
                $query->where(function ($q) {
                    $q->where('active', 1)
                        ->where('open', 1);
                });
            })
            ->where(function ($query) {
                $query->where('active', 1);
            });

        if ($request->search) {
            $folder->where(function ($query) use ($request) {
                $query->where('name', 'like', "%$request->search%")
                    ->orWhere('comment', 'like', "%$request->search%");
            });
        }

        if ($request->from && $request->to) {
            $folder->whereBetween('created_at', [$request->from, $request->to]);
        }

        if ($request->folder_id) {
            $folder->where(function ($query) use ($request) {
                $query->where('id', $request->folder_id);
            });
        }

        if ($request->teacher_id) {
            $folder->where('user_id', $request->teacher_id);
        }

        if (Auth::user()->hasRole('Admin')) {
            // Admin sees all
        } elseif (Auth::user()->hasRole('Teacher')) {
            $folder->where(fn ($q) => $q->where('user_id', Auth::id()));
        } else {
            // Default: active folders and open tests (already filtered in initial query above)
        }

        $folder = $folder->select('id', 'name', 'comment', 'active', 'user_id', 'created_at', 'updated_at')
            ->orderBy('id', 'asc')
            ->paginate($per_page);

        // Filter folder dropdown for search
        $folders_query = Folder::select('id', 'name')->where('active', 1);
        if (Auth::user()->hasRole('Teacher')) {
            $folders_query->where('user_id', Auth::id());
        } elseif (Auth::user()->hasRole('Student')) {
            $folders_query->where(fn ($q) => $q->where('user_id', Auth::id()));
            $folders_query->where(fn ($q) => $q->where('active', 1));
        } elseif (Auth::user()->hasRole('Admin')) {
            $folders_query = Folder::select('id', 'name'); // Admin sees all in dropdown
        }

        $teachers = Auth::user()->hasRole('Admin')
            ? \App\Models\User\User::whereHas('roles', function ($q) {
                $q->where('name', 'Teacher');
            })->select('id', 'name')->get()
            : [];

        return Inertia::render('all-test/index', [
            'folder' => $folder,
            'folders' => $folders_query->limit(50)->get(),
            'teachers' => $teachers,
            'isAdmin' => Auth::user()->hasRole('Admin'),
            'filters' => $request->only(['search', 'teacher_id', 'folder_id', 'from', 'to', 'per_page']),
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
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(Test $test)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Test $test)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Test $test)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Test $test)
    {
        //
    }
}
