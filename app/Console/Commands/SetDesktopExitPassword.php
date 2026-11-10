<?php

namespace App\Console\Commands;

use App\Models\Setting;
use Illuminate\Console\Command;

class SetDesktopExitPassword extends Command
{
    protected $signature = 'desktop:exit-password {password : New center-wide exit password for the desktop app}';

    protected $description = 'Set the desktop lockdown exit password (bcrypt + offline PBKDF2 hash)';

    public function handle(): int
    {
        $password = (string) $this->argument('password');

        if (mb_strlen($password) < 6) {
            $this->error('The password must be at least 6 characters.');

            return self::FAILURE;
        }

        Setting::setExitPassword($password);

        $this->info('Desktop exit password updated. PCs pick up the offline hash on their next /device/config call.');

        return self::SUCCESS;
    }
}
