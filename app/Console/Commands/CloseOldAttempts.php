<?php

namespace App\Console\Commands;

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
    protected $description = 'Close attempts older than 3 hours';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        Log::info('Command attempts:close-old started.');

        $oldAttempts = \App\Models\Attempt::whereNull('finished_at')
            ->where('created_at', '<', now()->subHours(3))
            ->get();

        $count = $oldAttempts->count();
        $this->info("Found {$count} old attempts to close.");
        Log::info("Found {$count} old attempts to close.");

        foreach ($oldAttempts as $attempt) {
            try {
                $attempt->finish();
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
