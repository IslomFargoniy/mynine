<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreUserRequest;
use App\Http\Requests\UpdateUserRequest;
use App\Models\Attempt;
use App\Models\User\User;
use App\Support\DayRange;
use App\Support\UserFacingError;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
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

        // "to" day included.
        if ($range = DayRange::from($request->from, $request->to)) {
            $user->whereBetween('created_at', $range);
        }

        if ($request->role) {
            $user->whereHas('roles', function ($query) use ($request) {
                $query->where('name', $request->role);
            });
        }

        $user = $user->paginate($per_page);

        return Inertia::render('user/index', [
            'user' => $user,
            'roles' => Role::query()->whereIn('name', ['Student', 'Reception'])->get(),
            'isAdmin' => true,
            'filters' => $request->only(['search', 'role', 'from', 'to', 'per_page']),
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
                'error' => [UserFacingError::message($e)],
            ]);
        }

    }

    /**
     * Display the specified resource.
     */
    public function show($id)
    {
        $this->authorize('viewAny', User::class);

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
        $recent_attempts = Attempt::with(['test', 'attempt_types'])
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
        $this->authorize('viewAny', User::class);

        // Center Admins are managed on the Centers page (Replace admin keeps the audit trail).
        if ($user->isCenterAdmin() && (int) $user->id !== (int) Auth::id()) {
            throw ValidationException::withMessages(['error' => [__('user_is_center_admin')]]);
        }

        try {

            $validated = $request->validated();

            if (! empty($validated['password'])) {
                $validated['password'] = Hash::make($validated['password']);
            } else {
                unset($validated['password']); // Don't update if password is empty
            }

            $user->update($validated);

            // Roles given here: Student or Reception (of the Mynine center). Admin / SuperAdmin come from the
            // Centers page only.
            if (isset($validated['role']) && in_array($validated['role'], ['Student', 'Reception'], true) && ! $user->isCenterAdmin()) {
                $user->syncRoles($validated['role']);
                $user->forceFill(['owner_id' => $validated['role'] === 'Reception' ? Auth::user()->centerId() : null])->saveQuietly();
            }

            return back()->with('success', __('updated_successfully'));
        } catch (\Exception $e) {
            // Proper Inertia error response
            throw ValidationException::withMessages([
                'error' => [UserFacingError::message($e)],
            ]);
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(User $user)
    {
        $this->authorize('viewAny', User::class);

        // Centers (Admin users) are never deleted: suspend them on the Centers page.
        if ($user->isCenterAdmin()) {
            return redirect()->route('user.index')->withErrors(['error' => __('user_is_center_admin')]);
        }

        if ($user->id === Auth::id()) {
            return redirect()->route('user.index')->withErrors([
                'error' => __('cannot_delete_self'),
            ]);
        }

        // Exam results belong to the attempts: an account with attempts is never deleted.
        $attempts = DB::table('attempts')->where('user_id', $user->id)->count();
        if ($attempts > 0) {
            return redirect()->route('user.index')->withErrors(['error' => __('user_has_results', ['count' => $attempts])]);
        }

        try {
            DB::transaction(function () use ($user) {
                // Delete user roles/permissions
                $user->roles()->detach();
                $user->delete();
            });

            return redirect()->route('user.index')->with('success', __('deleted_successfully') ?? "Foydalanuvchi o'chirildi");
        } catch (\Exception $e) {
            return redirect()->route('user.index')->withErrors([
                'error' => UserFacingError::message($e),
            ]);
        }
    }
}
