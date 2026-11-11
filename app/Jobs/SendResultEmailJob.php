<?php

// app/Jobs/SendResultEmailJob.php

namespace App\Jobs;

use App\Mail\SendResultMail;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class SendResultEmailJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;

    public array $backoff = [30, 120, 600];

    /** The attempt or user was deleted meanwhile: drop the job instead of failing it. */
    public bool $deleteWhenMissingModels = true;

    protected $user;

    protected $result;

    public function __construct($user, $result)
    {
        $this->user = $user;
        $this->result = $result;
    }

    public function handle()
    {
        $email = $this->user?->email;
        if (empty($email) || ! filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return;
        }

        try {
            Mail::to($email)->send(new SendResultMail($this->user, $this->result));
        } catch (\Exception $e) {
            Log::error('SendResultEmailJob failed: '.$e->getMessage());
            throw $e;
        }
    }

    public function failed(\Throwable $exception): void
    {
        Log::warning('SendResultEmailJob gave up: '.$exception->getMessage());
    }
}
