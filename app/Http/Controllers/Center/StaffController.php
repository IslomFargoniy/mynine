<?php

namespace App\Http\Controllers\Center;

use App\Http\Controllers\Controller;
use App\Models\User\User;
use App\Rules\UniquePhone;
use App\Support\CurrentCenter;
use App\Support\UserSessions;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Staff page (the center's Admin): the Reception users of the current center. Only Reception accounts can be
 * created here; they are suspended, never deleted.
 */
class StaffController extends Controller
{
    public function __construct(private readonly CurrentCenter $current) {}

    public function index(): Response
    {
        $this->authorize('manageStaff', User::class);

        $staff = User::query()
            ->where('owner_id', $this->centerId())
            ->whereHas('roles', fn ($q) => $q->where('name', 'Reception'))
            ->orderBy('name')
            ->get(['id', 'name', 'email', 'phone', 'telegram_id', 'suspended_at', 'created_at'])
            ->map(fn (User $u) => [
                'id' => $u->id,
                'name' => $u->name,
                'email' => $u->email,
                'phone' => $u->phone,
                'telegram' => $u->telegram_id !== null,
                'suspended' => $u->suspended_at !== null,
                'suspended_at' => $u->suspended_at?->toIso8601String(),
                'created_at' => $u->created_at?->toIso8601String(),
            ]);

        return Inertia::render('staff/index', [
            'staff' => $staff,
            'center' => $this->current->settings()?->summary(),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $this->authorize('manageStaff', User::class);
        $centerId = $this->centerId();

        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['nullable', 'required_without:phone', 'email', 'max:255', Rule::unique('users', 'email')],
            'phone' => ['nullable', 'required_without:email', 'string', 'max:32', Rule::unique('users', 'phone'), new UniquePhone],
            'password' => ['required', 'string', 'min:8', 'max:255'],
        ]);

        DB::transaction(function () use ($data, $centerId) {
            $user = User::create([
                'name' => $data['name'],
                'email' => isset($data['email']) ? strtolower($data['email']) : null,
                'phone' => $data['phone'] ?? null,
                'password' => $data['password'],
            ]);
            $user->forceFill(['owner_id' => $centerId, 'email_verified_at' => now()])->saveQuietly();
            $user->assignRole('Reception');
        });

        return back()->with('success', __('staff_created'));
    }

    public function update(Request $request, User $staff): RedirectResponse
    {
        abort_unless($staff->isReception(), 404);
        $this->authorize('update', $staff);

        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['nullable', 'required_without:phone', 'email', 'max:255', Rule::unique('users', 'email')->ignore($staff->id)],
            'phone' => ['nullable', 'required_without:email', 'string', 'max:32', Rule::unique('users', 'phone')->ignore($staff->id), new UniquePhone($staff->id)],
            'password' => ['nullable', 'string', 'min:8', 'max:255'],
        ]);

        $staff->forceFill([
            'name' => $data['name'],
            'email' => isset($data['email']) ? strtolower($data['email']) : null,
            'phone' => $data['phone'] ?? null,
        ]);
        if (! empty($data['password'])) {
            $staff->password = $data['password'];
        }
        $staff->saveQuietly();

        return back()->with('success', __('staff_updated'));
    }

    public function suspend(User $staff): RedirectResponse
    {
        abort_unless($staff->isReception(), 404);
        $this->authorize('update', $staff);

        $staff->forceFill(['suspended_at' => now()])->saveQuietly();
        UserSessions::invalidate($staff);

        return back()->with('success', __('staff_suspended'));
    }

    public function activate(User $staff): RedirectResponse
    {
        abort_unless($staff->isReception(), 404);
        $this->authorize('update', $staff);

        $staff->forceFill(['suspended_at' => null])->saveQuietly();

        return back()->with('success', __('staff_activated'));
    }

    private function centerId(): int
    {
        $id = $this->current->id();
        abort_if(! $id, 403);

        return $id;
    }
}
