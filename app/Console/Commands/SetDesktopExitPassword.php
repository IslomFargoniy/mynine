<?php

namespace App\Console\Commands;

use App\Models\CenterSetting;
use App\Support\CurrentCenter;
use Illuminate\Console\Command;

class SetDesktopExitPassword extends Command
{
    protected $signature = 'desktop:exit-password
        {password : New center password for the desktop app}
        {--center= : Center code (default: the Mynine center)}';

    /**
     * @var array<int, string>
     */
    protected $aliases = ['desktop:center-password'];

    protected $description = 'Set a center\'s desktop center password (registers PCs, unlocks the exam screen, opens the admin menu; bcrypt + offline PBKDF2 hash)';

    public function handle(CurrentCenter $current): int
    {
        $password = (string) $this->argument('password');

        if (mb_strlen($password) < 6) {
            $this->error('The password must be at least 6 characters.');

            return self::FAILURE;
        }

        $code = $this->option('center');
        $settings = $code ? CenterSetting::findByCode($code) : $current->settings($current->mynineId());

        if (! $settings) {
            $this->error($code ? "No center with code {$code}." : 'The Mynine center does not exist yet.');

            return self::FAILURE;
        }

        $settings->setExitPassword($password);

        $this->info("Desktop center password of {$settings->name} ({$settings->code}) updated. PCs pick up the offline hash on their next /device/config call.");

        return self::SUCCESS;
    }
}
