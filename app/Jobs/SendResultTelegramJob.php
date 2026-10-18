<?php

namespace App\Jobs;

use App\Models\Attempt;
use App\Models\User\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Telegram\Bot\Api;
use Telegram\Bot\FileUpload\InputFile;

class SendResultTelegramJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $user;

    protected $attempt;

    public function __construct(User $user, Attempt $attempt)
    {
        $this->user = $user;
        $this->attempt = $attempt;
    }

    public function handle()
    {
        try {
            if (! $this->user->telegram_id) {
                return;
            }

            $telegram = new Api(config('services.telegram.mynine_bot_token'));

            // Generate PDF internally instead of via URL
            $attempt = $this->attempt->load([
                'test',
                'user',
                'mock',
                'attempt_types' => function ($query) {
                    $query->whereHas('type', function ($q) {});
                },
            ]);

            $attempt->attempt_types->each(function ($attemptType) {
                $attemptType->append('attempt_parts');
            });

            $options = [
                'isPhpEnabled' => false,
                'isRemoteEnabled' => true,
                'isHtml5ParserEnabled' => true,
                'isFontSubsettingEnabled' => true,
                'isUnicodeEnabled' => true,
                'defaultFont' => 'DejaVu Sans',
            ];

            $dompdf = new \Dompdf\Dompdf($options);
            $dompdf->loadHtml(view('pdf.attempt', compact('attempt'))->render());
            $dompdf->setPaper('A4');
            $dompdf->render();
            $pdfContent = $dompdf->output();

            // Wrap the content in InputFile
            $document = InputFile::createFromContents($pdfContent, "TestResult_{$this->attempt->id}.pdf");

            // Caption
            $caption = "Hello {$this->user->name},\nYour test attempt is complete! 🎉\n\n".
                       "💳 Bizni Qo'llab-quvvatlang:\n\n".
                       "9860600402432220\n\n".
                       'Donat qilishingiz mumkin.';

            // Send document
            $telegram->sendDocument([
                'chat_id' => $this->user->telegram_id,
                'document' => $document,
                'caption' => $caption,
                'parse_mode' => 'HTML',
            ]);

            Log::info("Telegram PDF sent to user {$this->user->telegram_id}");

        } catch (\Exception $e) {
            Log::error('SendResultTelegramJob failed: '.$e->getMessage());
        }
    }
}
