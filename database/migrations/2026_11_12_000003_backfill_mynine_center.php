<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Step 2 of 3: every existing record belongs to the "Mynine" center, whose Admin is the SuperAdmin
 * (resolved by email, never by id). Other Admins become Reception of the Mynine center. The global
 * desktop settings (center password, background) become the Mynine center's.
 *
 * Idempotent. On a database without the SuperAdmin user (fresh install) nothing is changed.
 */
return new class extends Migration
{
    public const SUPER_ADMIN_EMAIL = 'abdurahmanislam304@gmail.com';

    private const OWNED_TABLES = ['mocks', 'devices', 'tests', 'test_imports'];

    public function up(): void
    {
        $guard = config('auth.defaults.guard', 'web');
        $now = now();

        foreach (['SuperAdmin', 'Admin', 'Reception', 'Student'] as $name) {
            if (! DB::table('roles')->where('name', $name)->where('guard_name', $guard)->exists()) {
                DB::table('roles')->insert(['name' => $name, 'guard_name' => $guard, 'created_at' => $now, 'updated_at' => $now]);
            }
        }
        $roleId = fn (string $name) => DB::table('roles')->where('name', $name)->where('guard_name', $guard)->value('id');

        $email = strtolower((string) env('SUPER_ADMIN_EMAIL', self::SUPER_ADMIN_EMAIL));
        $superAdminId = DB::table('users')->whereRaw('LOWER(email) = ?', [$email])->value('id');
        if (! $superAdminId) {
            if (DB::table('mocks')->exists() || DB::table('devices')->exists()) {
                Log::warning("Multi-center backfill skipped: no user with email {$email}.");
            }
            $this->forgetPermissionCache();

            return;
        }

        $userModel = DB::table('model_has_roles')->value('model_type') ?? 'App\\Models\\User\\User';
        $assign = function (int $userId, string $role) use ($roleId, $userModel) {
            DB::table('model_has_roles')->insertOrIgnore(['role_id' => $roleId($role), 'model_type' => $userModel, 'model_id' => $userId]);
        };

        DB::transaction(function () use ($superAdminId, $assign, $roleId, $userModel, $now) {
            $assign($superAdminId, 'SuperAdmin');
            $assign($superAdminId, 'Admin');

            // Other Admins → Reception of Mynine (ids kept in the audit log so down() can restore them).
            $demoted = DB::table('model_has_roles')
                ->where('role_id', $roleId('Admin'))
                ->where('model_type', $userModel)
                ->where('model_id', '!=', $superAdminId)
                ->pluck('model_id')
                ->map(fn ($id) => (int) $id)
                ->all();

            foreach ($demoted as $userId) {
                $assign($userId, 'Reception');
            }
            DB::table('model_has_roles')->where('role_id', $roleId('Admin'))->where('model_type', $userModel)->whereIn('model_id', $demoted)->delete();

            $receptionIds = DB::table('model_has_roles')->where('role_id', $roleId('Reception'))->where('model_type', $userModel)->pluck('model_id');
            DB::table('users')->whereIn('id', $receptionIds)->whereNull('owner_id')->where('id', '!=', $superAdminId)->update(['owner_id' => $superAdminId]);

            $owned = [];
            foreach (self::OWNED_TABLES as $table) {
                $owned[$table] = DB::table($table)->whereNull('owner_id')->update(['owner_id' => $superAdminId]);
            }

            if (! DB::table('center_settings')->where('owner_id', $superAdminId)->exists()) {
                $setting = fn (string $key) => DB::table('settings')->where('key', $key)->first();
                $password = $setting('desktop_exit_password');
                $offline = $setting('desktop_exit_password_offline');
                $background = $setting('desktop_background');

                DB::table('center_settings')->insert([
                    'owner_id' => $superAdminId,
                    'name' => 'Mynine',
                    'code' => DB::table('center_settings')->where('code', 'MYNINE')->exists() ? 'MYNINE'.$superAdminId : 'MYNINE',
                    'status' => 'active',
                    'exit_password' => $password?->value,
                    'exit_password_offline' => $offline?->value,
                    'exit_password_updated_at' => $password?->value ? ($password->updated_at ?? $now) : null,
                    'background' => $background?->value,
                    'background_updated_at' => $background?->value ? ($background->updated_at ?? $now) : null,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }

            DB::table('center_audit_logs')->insert([
                'actor_id' => null,
                'center_id' => $superAdminId,
                'action' => 'backfill',
                'meta' => json_encode(['demoted_admin_ids' => $demoted, 'owned' => $owned]),
                'created_at' => $now,
            ]);
        });

        $this->forgetPermissionCache();
    }

    public function down(): void
    {
        $guard = config('auth.defaults.guard', 'web');
        $roleId = fn (string $name) => DB::table('roles')->where('name', $name)->where('guard_name', $guard)->value('id');
        $userModel = DB::table('model_has_roles')->value('model_type') ?? 'App\\Models\\User\\User';

        $log = DB::table('center_audit_logs')->where('action', 'backfill')->orderByDesc('id')->first();
        $demoted = $log ? (array) (json_decode((string) $log->meta, true)['demoted_admin_ids'] ?? []) : [];

        DB::transaction(function () use ($demoted, $roleId, $userModel, $log) {
            if ($roleId('Admin')) {
                foreach ($demoted as $userId) {
                    DB::table('model_has_roles')->insertOrIgnore(['role_id' => $roleId('Admin'), 'model_type' => $userModel, 'model_id' => $userId]);
                }
                if ($roleId('Reception')) {
                    DB::table('model_has_roles')->where('role_id', $roleId('Reception'))->where('model_type', $userModel)->whereIn('model_id', $demoted)->delete();
                }
            }

            if ($superAdminRole = $roleId('SuperAdmin')) {
                DB::table('model_has_roles')->where('role_id', $superAdminRole)->delete();
                DB::table('role_has_permissions')->where('role_id', $superAdminRole)->delete();
                DB::table('roles')->where('id', $superAdminRole)->delete();
            }

            // The owner_id columns are dropped by the previous migration's down(); center_settings with it.
            if ($log) {
                DB::table('center_audit_logs')->where('id', $log->id)->delete();
            }
        });

        $this->forgetPermissionCache();
    }

    private function forgetPermissionCache(): void
    {
        app()['cache']->forget(config('permission.cache.key', 'spatie.permission.cache'));
    }
};
