<?php

namespace App\Console\Commands;

use App\Models\CenterAuditLog;
use App\Models\User\User;
use App\Services\Users\UserMerger;
use Illuminate\Console\Command;

/**
 * Accounts archived by an older "Replace admin" (email archived+…@mynine.invalid) belong to the person who now runs
 * that center: their attempts and other rows move to the center account and the archived account is deleted, as a
 * Replace admin does today (UserMerger).
 */
class MergeArchivedUsers extends Command
{
    protected $signature = 'users:merge-archived {--dry-run : Only list what would be merged}';

    protected $description = 'Fold accounts archived by Replace admin into the center account that took their email';

    public function handle(UserMerger $merger): int
    {
        $logs = CenterAuditLog::query()->where('action', 'admin_replaced')->orderBy('id')->get()
            ->filter(fn (CenterAuditLog $log) => ! empty($log->meta['archived_user_id']));

        if ($logs->isEmpty()) {
            $this->info('No archived accounts.');

            return self::SUCCESS;
        }

        foreach ($logs as $log) {
            $from = User::find((int) $log->meta['archived_user_id']);
            $into = User::find((int) $log->center_id);
            if (! $from || ! $into) {
                $this->line("#{$log->id}: already merged or center gone, skipped.");

                continue;
            }
            if (! str_ends_with((string) $from->email, '@mynine.invalid') || $from->isStaff()) {
                $this->warn("#{$log->id}: user {$from->id} is not an archived ordinary account, skipped.");

                continue;
            }

            $attempts = $from->attempts()->count();
            $this->line("User {$from->id} ({$from->name}, {$attempts} attempts) → center account {$into->id} ({$into->email})");

            if ($this->option('dry-run')) {
                continue;
            }

            $deleted = $merger->mergeInto($from, $into);
            CenterAuditLog::record('archived_user_merged', $into->id, [
                'meta' => ['merged_user_id' => $from->id, 'deleted' => $deleted, 'attempts' => $attempts],
            ]);
            $this->info($deleted ? '  merged and deleted.' : '  merged; the account had to stay archived.');
        }

        return self::SUCCESS;
    }
}
