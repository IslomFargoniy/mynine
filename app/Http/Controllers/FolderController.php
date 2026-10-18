<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreFolderRequest;
use App\Http\Requests\UpdateFolderRequest;
use App\Models\Folder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;

class FolderController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {

        $this->authorize('viewAny', Folder::class);

        $per_page = $request->per_page === 'all' ? 100 : min((int) ($request->per_page ?? 10), 100);

        $folder = Folder::query()->select('id', 'name', 'comment', 'active', 'user_id', 'created_at', 'updated_at');

        if ($request->search) {
            $folder->where(function ($query) use ($request) {
                $query->where('name', 'like', "%$request->search%")
                    ->orWhere('comment', 'like', "%$request->search%")
                    ->orWhereHas('user', function ($q) use ($request) {
                        $q->where('name', 'like', "%$request->search%");
                    });
            });
        }

        if ($request->from && $request->to) {
            $folder->whereBetween('created_at', [$request->from, $request->to]);
        }

        if ($request->user_id) {
            $folder->where('user_id', $request->user_id);
        }

        if ($request->teacher_id) {
            $folder->where('user_id', $request->teacher_id);
        }

        if (Auth::user()->hasRole('Admin')) {
            // Admin can see all folders
        } elseif (Auth::user()->hasRole('Teacher')) {
            // Teacher can see only their own folders
            $folder->where('user_id', Auth::id());
        } else {
            // Student and others can see only active folders
            $folder->where('active', 1);
        }

        $folder = $folder->orderBy('id', 'asc')->paginate($per_page);

        $teachers = Auth::user()->hasRole('Admin')
            ? \App\Models\User\User::whereHas('roles', function ($q) {
                $q->where('name', 'Teacher');
            })->select('id', 'name')->get()
            : [];

        return Inertia::render('folder/index', [
            'folder' => $folder,
            'users' => [],
            'teachers' => $teachers,
            'isAdmin' => Auth::user()->hasRole('Admin'),
            'filters' => $request->only(['search', 'teacher_id', 'user_id', 'from', 'to', 'per_page']),
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
    public function store(StoreFolderRequest $request)
    {
        $this->authorize('create', Folder::class);

        try {
            Folder::create($request->validated());

            return back()->with('success', __('updated_successfully'));
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
    public function show(Request $request, Folder $folder)
    {
        $this->authorize('view', $folder);

        $folder->load([
            'tests' => function ($query) use ($request) {
                if ($request->search) {
                    $query->where('name', 'like', '%'.$request->search.'%');
                }
                $query->with([
                    'types' => function ($query) {
                        $query->with([
                            'type',
                        ]);
                    },
                ])
                    ->withCount('attempts')
                    ->orderBy('id', 'asc');
            },
        ]);

        return Inertia::render('folder/show', [
            'folder' => $folder,
        ]);
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Folder $folder)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateFolderRequest $request, Folder $folder)
    {
        $this->authorize('update', $folder);

        try {
            $folder->update($request->validated());

            return back()->with('success', __('updated_successfully'));
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
    public function destroy(Folder $folder)
    {
        $this->authorize('delete', $folder);

        try {
            \Illuminate\Support\Facades\DB::transaction(function () use ($folder) {
                // Delete tests that have no attempts
                foreach ($folder->tests as $test) {
                    if ($test->attempts()->exists()) {
                        throw new \Exception("Ushbu jilddagi ba'zi testlarda urinishlar (attempts) mavjud bo'lgani sababli uni o'chirib bo'lmaydi.");
                    }
                    $test->delete();
                }
                $folder->delete();
            });

            return redirect()->route('folder.index')->with('success', __('deleted_successfully') ?? "Jild o'chirildi");
        } catch (\Exception $e) {
            return redirect()->route('folder.index')->withErrors([
                'error' => $e->getMessage(),
            ]);
        }
    }
}
