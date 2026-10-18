<?php

// app/Mail/SendResultMail.php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class SendResultMail extends Mailable
{
    use Queueable, SerializesModels;

    public $user;

    public $result;

    public function __construct($user, $result)
    {
        $this->user = $user;
        $this->result = $result;
    }

    public function build()
    {
        return $this->subject('Your Test Results')
            ->markdown('emails.results')
            ->with([
                'user' => $this->user,
                'result' => $this->result,
            ]);
    }
}
