<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreUserRequest;
use App\Http\Requests\UpdateUserRequest;
use App\Models\User\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;
use Spatie\Permission\Models\Role;

class UserController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {

        $this->authorize('viewAny', User::class);

        $per_page = $request->per_page === 'all' ? 100 : min((int) ($request->per_page ?? 10), 100);

        $user = User::with([
            'roles',
        ])
            ->whereNotIn('id', [Auth::user()->id])
            ->orderBy('id', 'desc');

        if ($request->search) {
            $user->where(function ($query) use ($request) {
                $query->whereLike('name', "%$request->search%")
                    ->orWhereLike('phone', "%$request->search%")
                    ->orWhereLike('username', "%$request->search%")
                    ->orWhereLike('telegram_id', "%$request->search%")
                    ->orWhereLike('email', "%$request->search%");
            });
        }

        if ($request->from && $request->to) {
            $user->whereBetween('created_at', [$request->from, $request->to]);
        }

        if (Auth::user()->hasRole('Admin')) {
            // Admin sees all excluding self
        } elseif (Auth::user()->hasRole('Teacher')) {
            $user->where(function ($query) {
                $query->where('user_id', '=', Auth::id())
                    ->orWhere('ref_telegram_id', '=', Auth::user()->telegram_id);
            });
        } else {
            // Students shouldn't even be here, but just in case:
            $user->where('id', Auth::id());
        }

        if ($request->role) {
            $user->whereHas('roles', function ($query) use ($request) {
                $query->where('name', $request->role);
            });
        }

        if ($request->teacher_id) {
            $teacher = User::find($request->teacher_id);
            if ($teacher) {
                $user->where(function ($query) use ($teacher) {
                    $query->where('user_id', '=', $teacher->id)
                        ->orWhere('ref_telegram_id', '=', $teacher->telegram_id);
                });
            }
        }

        if (! Auth::user()->hasRole('Admin')) {
            $user->where(function ($query) {
                $query->where('user_id', '=', Auth::id())
                    ->orWhere('ref_telegram_id', '=', Auth::user()->telegram_id);
            });
        }

        $user = $user->paginate($per_page);

        $teachers = Auth::user()->hasRole('Admin')
            ? User::whereHas('roles', function ($q) {
                $q->where('name', 'Teacher');
            })->select('id', 'name')->get()
            : [];

        return Inertia::render('user/index', [
            'user' => $user,
            'roles' => Role::all(),
            'teachers' => $teachers,
            'isAdmin' => Auth::user()->hasRole('Admin'),
            'filters' => $request->only(['search', 'role', 'teacher_id', 'from', 'to', 'per_page']),
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
    public function store(StoreUserRequest $request)
    {
        $this->authorize('viewAny', User::class);

        try {

            $validated = $request->validated();

            if (! empty($validated['password'])) {
                $validated['password'] = Hash::make($validated['password']);
            } else {
                unset($validated['password']); // Don't update if password is empty
            }

            $user = User::create($validated);

            $user->assignRole('Student');

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
    public function show($id)
    {
        if (! Auth::user()->hasRole('Admin')) {
            return back()->with('error', __('error.unauthorized_access'));
        }

        $user = clone User::query()
            ->with([
                'last_attempt.attempt_types',
                'attempts' => function ($query) {
                    $query->whereNotNull('finished_at')
                        ->where('finished_at', '>=', now()->subDays(30))
                        ->with(['attempt_types.type'])
                        ->orderBy('finished_at', 'asc');
                },
            ])
            ->withCount([
                'attempts as attempts_count_this_month' => function ($query) {
                    $query->whereNotNull('finished_at')
                        ->whereYear('finished_at', now()->year)
                        ->whereMonth('finished_at', now()->month);
                },
                'attempts as total_attempts_count' => function ($query) {
                    $query->whereNotNull('finished_at');
                },
            ])
            ->findOrFail($id);

        // Get recent 5 attempts
        $recent_attempts = \App\Models\Attempt::with(['test', 'attempt_types'])
            ->where('user_id', $user->id)
            ->whereNotNull('finished_at')
            ->orderBy('finished_at', 'desc')
            ->limit(5)
            ->get();

        return Inertia::render('user/show', [
            'user' => $user,
            'recent_attempts' => $recent_attempts,
        ]);
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateUserRequest $request, User $user)
    {
        try {

            $validated = $request->validated();

            if (! empty($validated['password'])) {
                $validated['password'] = Hash::make($validated['password']);
            } else {
                unset($validated['password']); // Don't update if password is empty
            }

            $user->update($validated);

            if (Auth::user()->hasRole('Admin')) {
                if (isset($validated['role'])) {
                    $user->syncRoles($validated['role']);
                }
            }

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
    public function destroy(User $user)
    {
        if ($user->id === Auth::id()) {
            return redirect()->route('user.index')->withErrors([
                'error' => "O'z hisobingizni o'chira olmaysiz.",
            ]);
        }

        try {
            \Illuminate\Support\Facades\DB::transaction(function () use ($user) {
                // Delete user roles/permissions
                $user->roles()->detach();
                $user->delete();
            });

            return redirect()->route('user.index')->with('success', __('deleted_successfully') ?? "Foydalanuvchi o'chirildi");
        } catch (\Exception $e) {
            return redirect()->route('user.index')->withErrors([
                'error' => $e->getMessage(),
            ]);
        }
    }
}
