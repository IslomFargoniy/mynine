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
            // HTML view + plain-text part (emails.results_plain); the HTML is not a markdown mail.
            ->view('emails.results')
            ->text('emails.results_plain')
            ->with([
                'user' => $this->user,
                'result' => $this->result,
            ]);
    }
}
