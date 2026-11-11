<?php

namespace App\Jobs;

use App\Models\Attempt;
use App\Models\User\User;
use App\Services\AttemptPdfRenderer;
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

    public int $tries = 3;

    public array $backoff = [30, 120, 600];

    /** The attempt or user was deleted meanwhile: drop the job instead of failing it. */
    public bool $deleteWhenMissingModels = true;

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
            if (! $this->user?->telegram_id || ! config('services.telegram.mynine_bot_token')) {
                return;
            }

            $telegram = new Api(config('services.telegram.mynine_bot_token'));

            $pdfContent = app(AttemptPdfRenderer::class)->render($this->attempt);

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
