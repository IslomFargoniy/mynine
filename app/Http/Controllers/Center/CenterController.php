<?php

namespace App\Http\Controllers\Center;

use App\Http\Controllers\Controller;
use App\Models\CenterAuditLog;
use App\Models\CenterSetting;
use App\Models\User\User;
use App\Support\CurrentCenter;
use App\Support\UserSessions;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Centers page (SuperAdmin). A center IS its Admin user: creating a center creates the Admin, a center is
 * never deleted (suspended instead), and "Replace admin" hands the same account to another person.
 */
class CenterController extends Controller
{
    public function __construct(private readonly CurrentCenter $current) {}

    public function index(Request $request): Response
    {
        Gate::authorize('manage-centers');

        $centers = CenterSetting::query()->with('owner:id,name,email,phone,telegram_id,google_id')->orderBy('id')->get();
        $ids = $centers->pluck('owner_id')->all();

        $count = fn (string $table) => DB::table($table)->whereIn('owner_id', $ids)->groupBy('owner_id')->selectRaw('owner_id, COUNT(*) as n')->pluck('n', 'owner_id');
        $mocks = $count('mocks');
        $devices = $count('devices');
        $staff = DB::table('users')->whereIn('owner_id', $ids)->groupBy('owner_id')->selectRaw('owner_id, COUNT(*) as n')->pluck('n', 'owner_id');
        $candidates = DB::table('mock_students')->join('mocks', 'mocks.id', '=', 'mock_students.mock_id')
            ->whereIn('mocks.owner_id', $ids)->groupBy('mocks.owner_id')->selectRaw('mocks.owner_id, COUNT(*) as n')->pluck('n', 'owner_id');
        $attempts = DB::table('attempts')->join('mocks', 'mocks.id', '=', 'attempts.mock_id')
            ->whereIn('mocks.owner_id', $ids)->groupBy('mocks.owner_id')->selectRaw('mocks.owner_id, COUNT(*) as n')->pluck('n', 'owner_id');

        return Inertia::render('centers/index', [
            'centers' => $centers->map(fn (CenterSetting $c) => [
                ...$c->summary(),
                'admin' => [
                    'id' => $c->owner?->id,
                    'name' => $c->owner?->name,
                    'email' => $c->owner?->email,
                    'phone' => $c->owner?->phone,
                    'telegram' => $c->owner?->telegram_id !== null,
                    'google' => $c->owner?->google_id !== null,
                ],
                'counts' => [
                    'mocks' => (int) ($mocks[$c->owner_id] ?? 0),
                    'candidates' => (int) ($candidates[$c->owner_id] ?? 0),
                    'attempts' => (int) ($attempts[$c->owner_id] ?? 0),
                    'devices' => (int) ($devices[$c->owner_id] ?? 0),
                    'staff' => (int) ($staff[$c->owner_id] ?? 0),
                ],
            ])->values(),
            'activeCenterId' => $request->user()->centerId(),
            'audit' => CenterAuditLog::query()->with('actor:id,name')->latest('id')->limit(30)->get()->map(fn (CenterAuditLog $log) => [
                'id' => $log->id,
                'center_id' => $log->center_id,
                'action' => $log->action,
                'old_email' => $log->old_email,
                'new_email' => $log->new_email,
                'actor' => $log->actor?->name,
                'created_at' => $log->created_at?->toIso8601String(),
            ]),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        Gate::authorize('manage-centers');

        $request->merge(['code' => CenterSetting::normalizeCode($request->input('code'))]);
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'code' => ['required', 'string', 'regex:'.CenterSetting::CODE_PATTERN, Rule::unique('center_settings', 'code')],
            'admin_name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', Rule::unique('users', 'email')],
            'password' => ['nullable', 'string', 'min:8', 'max:255'],
            'contract_until' => ['nullable', 'date_format:Y-m-d'],
        ], [], ['code' => __('center_code')]);

        DB::transaction(function () use ($data) {
            $admin = User::create([
                'name' => $data['admin_name'],
                'email' => strtolower($data['email']),
                // Without a password the Admin signs in with Google (same email) or resets it by email.
                'password' => $data['password'] ?? Str::random(40),
            ]);
            $admin->forceFill(['email_verified_at' => now()])->saveQuietly();
            $admin->assignRole('Admin');

            CenterSetting::create([
                'owner_id' => $admin->id,
                'name' => $data['name'],
                'code' => $data['code'],
                'status' => CenterSetting::STATUS_ACTIVE,
                'contract_until' => $data['contract_until'] ?? null,
            ]);

            CenterAuditLog::record('center_created', $admin->id, ['new_email' => $admin->email, 'meta' => ['code' => $data['code']]]);
        });

        return back()->with('success', __('center_created'));
    }

    public function update(Request $request, User $center): RedirectResponse
    {
        Gate::authorize('manage-centers');
        $settings = $this->settingsOf($center);

        $request->merge(['code' => CenterSetting::normalizeCode($request->input('code'))]);
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'code' => ['required', 'string', 'regex:'.CenterSetting::CODE_PATTERN, Rule::unique('center_settings', 'code')->ignore($settings->id)],
            'admin_name' => ['required', 'string', 'max:255'],
            'contract_until' => ['nullable', 'date_format:Y-m-d'],
        ], [], ['code' => __('center_code')]);

        if ($settings->isMynine() && $data['code'] !== CenterSetting::MYNINE_CODE) {
            return back()->with('error', __('center_mynine_code_fixed'));
        }

        DB::transaction(function () use ($settings, $center, $data) {
            $before = $settings->only(['name', 'code', 'contract_until']);
            $settings->forceFill([
                'name' => $data['name'],
                'code' => $data['code'],
                'contract_until' => $data['contract_until'] ?? null,
            ])->save();
            $center->forceFill(['name' => $data['admin_name']])->saveQuietly();

            CenterAuditLog::record('center_updated', $center->id, ['meta' => ['before' => $before, 'after' => $settings->only(['name', 'code', 'contract_until'])]]);
        });

        return back()->with('success', __('center_updated'));
    }

    /**
     * Suspend (read-only for its staff, desktop logins refused) or activate a center.
     */
    public function status(Request $request, User $center): RedirectResponse
    {
        Gate::authorize('manage-centers');
        $settings = $this->settingsOf($center);

        $data = $request->validate([
            'status' => ['required', Rule::in([CenterSetting::STATUS_ACTIVE, CenterSetting::STATUS_SUSPENDED])],
        ]);

        if ($settings->isMynine() && $data['status'] === CenterSetting::STATUS_SUSPENDED) {
            return back()->with('error', __('center_mynine_cannot_suspend'));
        }

        $settings->forceFill(['status' => $data['status']])->save();
        CenterAuditLog::record($data['status'] === CenterSetting::STATUS_SUSPENDED ? 'center_suspended' : 'center_activated', $center->id);

        return back()->with('success', __($data['status'] === CenterSetting::STATUS_SUSPENDED ? 'center_suspended_saved' : 'center_activated_saved'));
    }

    /**
     * Hand the center's Admin account to another person: new email; Google, GitHub and Telegram links, phone and
     * password cleared; every session of the account ends. The center's data stays with the account.
     */
    public function replaceAdmin(Request $request, User $center): RedirectResponse
    {
        Gate::authorize('manage-centers');
        $this->settingsOf($center);

        if ($center->isSuperAdmin()) {
            return back()->with('error', __('center_replace_superadmin'));
        }

        $data = $request->validate([
            'email' => ['required', 'email', 'max:255', Rule::unique('users', 'email')->ignore($center->id)],
            'name' => ['nullable', 'string', 'max:255'],
        ]);

        $oldEmail = $center->email;
        $newEmail = strtolower($data['email']);

        DB::transaction(function () use ($center, $data, $oldEmail, $newEmail) {
            $center->forceFill([
                'email' => $newEmail,
                'name' => ($data['name'] ?? null) ?: $center->name,
                'email_verified_at' => now(),
                'google_id' => null,
                'github_id' => null,
                'telegram_id' => null,
                'ref_telegram_id' => null,
                'username' => null,
                'avatar' => null,
                'phone' => null,
                // The old person may know the password: the new Admin signs in with Google or resets it.
                'password' => Str::random(40),
            ])->saveQuietly();

            UserSessions::invalidate($center);

            CenterAuditLog::record('admin_replaced', $center->id, [
                'old_email' => $oldEmail,
                'new_email' => $newEmail,
                'meta' => ['center_code' => $center->centerSetting?->code],
            ]);
        });

        return back()->with('success', __('center_admin_replaced', ['email' => $newEmail]));
    }

    /**
     * Work as another center (all center pages show and change that center's data). Own center = default.
     */
    public function switch(Request $request, User $center): RedirectResponse
    {
        Gate::authorize('manage-centers');
        $settings = $this->settingsOf($center);

        if ((int) $center->id === (int) $request->user()->id) {
            $request->session()->forget(CurrentCenter::SESSION_KEY);
        } else {
            $request->session()->put(CurrentCenter::SESSION_KEY, (int) $center->id);
        }

        return redirect()->route('mock.index')->with('success', __('center_switched', ['name' => $settings->name]));
    }

    private function settingsOf(User $center): CenterSetting
    {
        $settings = CenterSetting::query()->where('owner_id', $center->id)->first();
        abort_unless($settings && $center->isCenterAdmin(), 404);

        return $settings;
    }
}
