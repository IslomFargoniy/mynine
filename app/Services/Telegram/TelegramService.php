<?php

namespace App\Services\Telegram;

use Telegram\Bot\Api;
use Telegram\Bot\Keyboard\Keyboard;

class TelegramService
{
    protected Api $telegram;

    public function __construct()
    {
        $this->telegram = new Api(config('services.telegram.bot_token'));
    }

    /**
     * Handle bot commands (/start, /help, /mocks)
     */
    public function handleCommand(int|string $chatId): void
    {
        $this->sendSafeMessage($chatId, 'We moved to MynineUzBot! Please use @MynineUzBot for further interactions.');

        // clear commands for this bot

        // Clear all commands
        $this->telegram->setMyCommands([
            'commands' => [],
        ]);
    }

    /**
     * Safe message sender (catches Telegram API errors)
     */
    protected function sendSafeMessage(int|string $chatId, string $text, ?Keyboard $keyboard = null): void
    {
        try {
            $params = [
                'chat_id' => $chatId,
                'text' => $text,
            ];
            if ($keyboard) {
                $params['reply_markup'] = $keyboard;
            }
            $this->telegram->sendMessage($params);
        } catch (\Exception $e) {
            \Log::error('Telegram sendMessage error: '.$e->getMessage());
        }
    }
}
