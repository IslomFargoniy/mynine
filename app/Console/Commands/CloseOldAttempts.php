<?php

namespace App\Console\Commands;

use App\Models\Attempt;
use App\Services\ExamService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class CloseOldAttempts extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'attempts:close-old';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Close abandoned attempts older than 3 hours (never a running, paused or online exam)';

    /**
     * Execute the console command.
     */
    public function handle(ExamService $exam)
    {
        Log::info('Command attempts:close-old started.');

        $grace = (int) config('desktop.answer_grace_seconds', 30);

        $oldAttempts = Attempt::query()
            ->whereNull('finished_at')
            ->where('created_at', '<', now()->subHours(3))
            // Paused by the invigilator: the timers are frozen, not abandoned.
            ->whereNull('paused_at')
            // A desktop PC still sends heartbeats: the exam is running (e.g. extra time).
            ->where(fn ($q) => $q->whereNull('last_heartbeat_at')->orWhere('last_heartbeat_at', '<', now()->subMinutes(10)))
            // A module whose time (plus the answer grace) has not run out yet is still running.
            ->whereDoesntHave('attempt_types', fn ($q) => $q
                ->where('is_submitted', false)
                ->whereNotNull('finished_at')
                ->where('finished_at', '>', now()->subSeconds($grace)))
            ->get();

        $count = $oldAttempts->count();
        $this->info("Found {$count} old attempts to close.");
        Log::info("Found {$count} old attempts to close.");

        foreach ($oldAttempts as $attempt) {
            try {
                $exam->finishAttempt($attempt);
                $this->line("Closed attempt ID: {$attempt->id}");
                Log::debug("Closed attempt ID: {$attempt->id} automatically.");
            } catch (\Exception $e) {
                $message = "Failed to close attempt ID: {$attempt->id}. Error: {$e->getMessage()}";
                $this->error($message);
                Log::error($message);
            }
        }

        $this->info('Done.');
        Log::info('Command attempts:close-old finished.');
    }
}
