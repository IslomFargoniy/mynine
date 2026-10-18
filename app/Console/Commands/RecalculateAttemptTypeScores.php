<?php

namespace App\Console\Commands;

use App\Models\AttemptType;
use Illuminate\Console\Command;

class RecalculateAttemptTypeScores extends Command
{
    protected $signature = 'attempt-types:recalculate';

    protected $description = 'Recalculate is_correct_count for all existing attempt_types';

    public function handle()
    {
        $count = AttemptType::count();
        $this->info("Recalculating is_correct_count for {$count} attempt types...");

        $bar = $this->output->createProgressBar($count);

        AttemptType::chunk(100, function ($attemptTypes) use ($bar) {
            foreach ($attemptTypes as $attemptType) {
                $attemptType->recalculateIsCorrectCount();
                $bar->advance();
            }
        });

        $bar->finish();
        $this->newLine();
        $this->info('Done! All attempt_types updated.');

        return Command::SUCCESS;
    }
}
