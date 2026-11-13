<?php

namespace App\Services\Users;

use App\Models\User\User;
use App\Support\UserSessions;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

/**
 * Folds one person's account into another of theirs (Replace admin with the email of an ordinary user): their
 * attempts, folders, mocks and every other row that points at them move to [into], then the old account is deleted.
 * If something unexpected still points at it, it is archived instead (email and sign-in links freed).
 */
class UserMerger
{
    /** table => columns that hold a user id of a person (not a center's owner_id). */
    private const PERSON_COLUMNS = [
        'attempts' => ['user_id'],
        'folders' => ['user_id'],
        'mocks' => ['user_id'],
        'users' => ['user_id'],
        'mock_students' => ['user_id', 'delivered_by'],
        'attempt_types' => ['reviewed_by'],
        'test_imports' => ['user_id'],
        'ai_usage_logs' => ['user_id'],
        'center_audit_logs' => ['actor_id'],
    ];

    /** @return bool true when the old account was deleted, false when it had to be archived */
    public function mergeInto(User $from, User $into): bool
    {
        return DB::transaction(function () use ($from, $into) {
            foreach (self::PERSON_COLUMNS as $table => $columns) {
                if (! Schema::hasTable($table)) {
                    continue;
                }
                foreach ($columns as $column) {
                    if (Schema::hasColumn($table, $column)) {
                        DB::table($table)->where($column, $from->id)->update([$column => $into->id]);
                    }
                }
            }

            UserSessions::invalidate($from);
            if (method_exists($from, 'tokens')) {
                $from->tokens()->delete();
            }

            try {
                DB::transaction(function () use ($from) {
                    $from->roles()->detach();
                    $from->permissions()->detach();
                    $from->delete();
                });

                return true;
            } catch (QueryException $e) {
                report($e);
                $from->forceFill([
                    'email' => 'archived+'.$from->id.'.'.now()->timestamp.'@mynine.invalid',
                    'google_id' => null,
                    'github_id' => null,
                    'telegram_id' => null,
                    'password' => Str::random(40),
                ])->saveQuietly();

                return false;
            }
        });
    }
}
