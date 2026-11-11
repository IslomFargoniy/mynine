<?php

namespace App\Console\Commands;

use App\Models\Setting;
use Illuminate\Console\Command;

class SetDesktopExitPassword extends Command
{
    protected $signature = 'desktop:exit-password {password : New center password for the desktop app}';

    /**
     * @var array<int, string>
     */
    protected $aliases = ['desktop:center-password'];

    protected $description = 'Set the desktop center password (registers PCs, unlocks the exam screen, opens the admin menu; bcrypt + offline PBKDF2 hash)';

    public function handle(): int
    {
        $password = (string) $this->argument('password');

        if (mb_strlen($password) < 6) {
            $this->error('The password must be at least 6 characters.');

            return self::FAILURE;
        }

        Setting::setExitPassword($password);

        $this->info('Desktop center password updated. PCs pick up the offline hash on their next /device/config call.');

        return self::SUCCESS;
    }
}
