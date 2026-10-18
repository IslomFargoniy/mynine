<?php

// app/Jobs/SendResultEmailJob.php

namespace App\Jobs;

use App\Mail\SendResultMail;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Mail;

class SendResultEmailJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $user;

    protected $result;

    public function __construct($user, $result)
    {
        $this->user = $user;
        $this->result = $result;
    }

    public function handle()
    {
        try {
            Mail::to($this->user->email)->send(new SendResultMail($this->user, $this->result));
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('SendResultEmailJob failed: '.$e->getMessage());
            throw $e;
        }
    }
}
