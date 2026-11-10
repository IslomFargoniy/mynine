<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * The system now has three roles: Admin, Reception and Student.
 * Former teachers become students; everything they owned moves to the first admin.
 */
return new class extends Migration
{
    public function up(): void
    {
        $guard = config('auth.defaults.guard', 'web');
        $now = now();

        foreach (['Admin', 'Reception', 'Student'] as $name) {
            if (! DB::table('roles')->where('name', $name)->where('guard_name', $guard)->exists()) {
                DB::table('roles')->insert(['name' => $name, 'guard_name' => $guard, 'created_at' => $now, 'updated_at' => $now]);
            }
        }

        $teacherRole = DB::table('roles')->where('name', 'Teacher')->where('guard_name', $guard)->first();
        if (! $teacherRole) {
            return;
        }

        $studentRoleId = DB::table('roles')->where('name', 'Student')->where('guard_name', $guard)->value('id');
        $adminRoleId = DB::table('roles')->where('name', 'Admin')->where('guard_name', $guard)->value('id');
        $userModel = DB::table('model_has_roles')->where('role_id', $teacherRole->id)->value('model_type') ?? 'App\\Models\\User\\User';

        $teacherIds = DB::table('model_has_roles')
            ->where('role_id', $teacherRole->id)
            ->pluck('model_id');

        $mainAdminId = DB::table('model_has_roles')
            ->where('role_id', $adminRoleId)
            ->whereNotIn('model_id', $teacherIds)
            ->orderBy('model_id')
            ->value('model_id');

        if ($mainAdminId && $teacherIds->isNotEmpty()) {
            DB::table('folders')->whereIn('user_id', $teacherIds)->update(['user_id' => $mainAdminId]);
            DB::table('mocks')->whereIn('user_id', $teacherIds)->update(['user_id' => $mainAdminId]);
        }

        foreach ($teacherIds as $userId) {
            $hasStudent = DB::table('model_has_roles')
                ->where('model_id', $userId)->where('model_type', $userModel)->where('role_id', $studentRoleId)->exists();
            if (! $hasStudent) {
                DB::table('model_has_roles')->insert(['role_id' => $studentRoleId, 'model_type' => $userModel, 'model_id' => $userId]);
            }
        }

        DB::table('model_has_roles')->where('role_id', $teacherRole->id)->delete();
        DB::table('role_has_permissions')->where('role_id', $teacherRole->id)->delete();
        DB::table('roles')->where('id', $teacherRole->id)->delete();

        app()['cache']->forget(config('permission.cache.key', 'spatie.permission.cache'));
    }

    public function down(): void
    {
        // Irreversible: former teachers' ownership cannot be reconstructed.
    }
};
