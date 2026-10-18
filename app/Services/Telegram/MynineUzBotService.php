<?php

namespace App\Services\Telegram;

use App\Models\Mock;
use App\Models\MockStudent;
use App\Models\User\User;
use App\Services\IeltsScoreConverter;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\URL;
use Telegram\Bot\Api;
use Telegram\Bot\Keyboard\Keyboard;

class MynineUzBotService
{
    protected Api $telegram;

    public function __construct()
    {
        $this->telegram = new Api(config('services.telegram.mynine_bot_token'));
    }

    /**
     * Handle bot commands and text inputs (/start, /help, /mocks, /result, candidate codes)
     */
    public function handleCommand(array $update, string $inputText, int|string $chatId): void
    {
        $text = trim($inputText);
        $parts = explode(' ', $text);
        $command = strtolower($parts[0] ?? '');
        $params = trim(implode(' ', array_slice($parts, 1)));

        // 1. Direct Command matching
        if ($command === '/start' || str_starts_with($text, '/start')) {
            $this->sendWelcomeMessage($update, $chatId);

            return;
        }

        if ($command === '/help') {
            $this->sendHelpMessage($chatId);

            return;
        }

        if ($command === '/mocks') {
            $this->sendMockMessage($chatId);

            return;
        }

        if ($command === '/ref') {
            $this->sendRefMessage($chatId);

            return;
        }

        if ($command === '/result' || $command === '/natija') {
            if (! empty($params)) {
                $this->sendCandidateResult($chatId, $params);
            } else {
                $this->sendSafeMessage(
                    $chatId,
                    "📊 *Imtihon Natijasini Bilish*\n\nIltimos, o'zingizga berilgan *Nomzod Kodini* yuboring.\nMasalan: `TEST1-849201` yoki `MS123456`",
                    null,
                    'Markdown'
                );
            }

            return;
        }

        // 2. Check if the text matches a Candidate Code directly (e.g. TEST1-849201, MS123456)
        $cleanCandidateCode = strtoupper(preg_replace('/[^a-zA-Z0-9-]/', '', $text));
        if (! empty($cleanCandidateCode) && strlen($cleanCandidateCode) >= 4 && strlen($cleanCandidateCode) <= 25) {
            $student = MockStudent::where('code', $cleanCandidateCode)
                ->orWhereRaw("REPLACE(code, '-', '') = ?", [str_replace('-', '', $cleanCandidateCode)])
                ->first();

            if ($student) {
                $this->sendCandidateResult($chatId, $student->code);

                return;
            }
        }

        // 3. Fallback for unknown input
        $this->sendUnknownCommand($chatId);
    }

    /**
     * Look up candidate code and send detailed exam result
     */
    public function sendCandidateResult(int|string $chatId, string $rawCode): void
    {
        $code = strtoupper(trim($rawCode));

        $student = MockStudent::where('code', $code)
            ->with([
                'mock',
                'attempt.attempt_types.type',
                'attempt.test.folder',
            ])
            ->first();

        // Accept the code typed without the hyphen, but never do fuzzy matching:
        // a partial code must not reveal somebody else's result.
        if (! $student && ! str_contains($code, '-')) {
            $student = MockStudent::whereRaw("REPLACE(code, '-', '') = ?", [$code])
                ->with([
                    'mock',
                    'attempt.attempt_types.type',
                    'attempt.test.folder',
                ])
                ->first();
        }

        if (! $student) {
            $this->sendSafeMessage(
                $chatId,
                "❌ *Nomzod Kodi topilmadi*\n\nSiz kiritgan `{$code}` kodi bo'yicha hech qanday ma'lumot topilmadi.\n\nIltimos, kodingizni to'g'ri kiritganingizni tekshiring (masalan: `TEST1-849201`).",
                null,
                'Markdown'
            );

            return;
        }

        $mock = $student->mock;
        $attempt = $student->attempt;

        // If candidate hasn't taken the exam yet
        if (! $attempt || ! $attempt->finished_at) {
            $msg = "⏳ *Imtihon Natijasi Kutilmoqda*\n";
            $msg .= "━━━━━━━━━━━━━━━━━━━\n";
            $msg .= "👤 *Nomzod:* {$student->name}\n";
            $msg .= "🏷 *Kod:* `{$student->code}`\n";
            if ($mock) {
                $msg .= "🧪 *Mock Test:* {$mock->name}\n";
            }
            $msg .= "━━━━━━━━━━━━━━━━━━━\n";
            $msg .= 'ℹ️ Ushbu nomzod imtihonni hali boshlamagan yoki natijalari tekshirilmoqda.';

            $keyboard = Keyboard::make()->inline()->row([
                Keyboard::inlineButton([
                    'text' => 'Platformaga Kirish 🎓',
                    'web_app' => ['url' => 'https://mynine.uz'],
                ]),
            ]);

            $this->sendSafeMessage($chatId, $msg, $keyboard, 'Markdown');

            return;
        }

        // Calculate Module Scores
        $listeningRaw = null;
        $readingRaw = null;
        $listeningBand = null;
        $readingBand = null;
        $writingBand = null;
        $speakingBand = null;

        $validBands = [];

        foreach ($attempt->attempt_types as $typeItem) {
            $typeName = $typeItem->type?->name ?? '';
            if ($typeName === 'Listening') {
                $listeningRaw = (int) ($typeItem->is_correct_count ?? 0);
                $listeningBand = IeltsScoreConverter::convertListening($listeningRaw);
                $validBands[] = $listeningBand;
            } elseif ($typeName === 'Reading') {
                $readingRaw = (int) ($typeItem->is_correct_count ?? 0);
                $readingBand = IeltsScoreConverter::convertReading($readingRaw);
                $validBands[] = $readingBand;
            } elseif ($typeName === 'Writing') {
                $writingBand = $typeItem->is_correct_count !== null ? (float) $typeItem->is_correct_count / 2 : null;
                if ($writingBand !== null) {
                    $validBands[] = $writingBand;
                }
            } elseif ($typeName === 'Speaking') {
                $speakingBand = $typeItem->score !== null ? (float) $typeItem->score : null;
                if ($speakingBand !== null) {
                    $validBands[] = $speakingBand;
                }
            }
        }

        $overallBand = ! empty($validBands) ? IeltsScoreConverter::calculateOverallBand($validBands) : 0.0;
        $cefr = IeltsScoreConverter::getCefrLevel($overallBand);
        $finishedDate = $attempt->finished_at ? date('d.m.Y H:i', strtotime($attempt->finished_at)) : date('d.m.Y');

        $lStr = $listeningBand !== null ? "{$listeningBand} ({$listeningRaw}/40)" : '—';
        $rStr = $readingBand !== null ? "{$readingBand} ({$readingRaw}/40)" : '—';
        $wStr = $writingBand !== null ? number_format($writingBand, 1) : 'Tekshirilmoqda ⏳';
        $sStr = $speakingBand !== null ? number_format($speakingBand, 1) : 'Tekshirilmoqda ⏳';

        $mockName = $mock?->name ?? ($attempt->test?->name ?? 'IELTS Mock Test');

        $msg = "🎓 *IELTS MOCK TEST NATIJASI*\n";
        $msg .= "━━━━━━━━━━━━━━━━━━━\n";
        $msg .= "👤 *Nomzod:* {$student->name}\n";
        $msg .= "🏷 *Nomzod Kodi:* `{$student->code}`\n";
        $msg .= "🧪 *Imtihon:* {$mockName}\n";
        $msg .= "📅 *Sana:* {$finishedDate}\n";
        $msg .= "━━━━━━━━━━━━━━━━━━━\n";
        $msg .= "🎧 *Listening:* {$lStr}\n";
        $msg .= "📖 *Reading:* {$rStr}\n";
        $msg .= "✍️ *Writing:* {$wStr}\n";
        $msg .= "🗣 *Speaking:* {$sStr}\n";
        $msg .= "━━━━━━━━━━━━━━━━━━━\n";
        $msg .= "🏆 *OVERALL BAND SCORE:* *{$overallBand}*\n";
        $msg .= "🎯 *CEFR Darajasi:* *{$cefr}*\n";
        $msg .= "━━━━━━━━━━━━━━━━━━━\n";
        $msg .= "📄 Rasmiy sertifikat (TRF) va batafsil tahlilni quyidagi tugmalar orqali ko'rishingiz mumkin:";

        $keyboard = Keyboard::make()->inline()
            ->row([
                Keyboard::inlineButton([
                    'text' => '📄 Rasmiy TRF Sertifikat (PDF)',
                    'url' => url(URL::signedRoute('attempt.pdf', ['attempt' => $attempt->id], null, false)),
                ]),
            ]);

        // The detailed web page requires a login, so only offer it to registered candidates
        if ($attempt->user_id) {
            $keyboard->row([
                Keyboard::inlineButton([
                    'text' => '🔍 Batafsil Natijani Ko\'rish',
                    'web_app' => ['url' => route('attempt.show', $attempt->id)],
                ]),
            ]);
        }

        $this->sendSafeMessage($chatId, $msg, $keyboard, 'Markdown');
    }

    /**
     * /help command
     */
    protected function sendHelpMessage(int|string $chatId): void
    {
        $text = "📘 *Mynine Bot Yordam Bo'limi:*\n\n".
            "🔹 `/start` - Platformani ochish\n".
            "🔹 `/result <KOD>` - Nomzod kodi orqali natijani bilish\n".
            "🔹 `/mocks` - Faol mock testlarni ko'rish\n".
            "🔹 `/ref` - Shaxsiy taklif havolangiz\n\n".
            "💡 *Maslahat:* Imtihon natijangizni bilish uchun shunchaki o'zingizning Nomzod Kodingizni (masalan: `TEST1-849201` yoki `MS123456`) to'g'ridan-to'g'ri yozib yuborishingiz ham mumkin!";

        $this->sendSafeMessage($chatId, $text, null, 'Markdown');
    }

    /**
     * Unknown command handler
     */
    protected function sendUnknownCommand(int|string $chatId): void
    {
        $text = "Kechirasiz, buyruq tushunarsiz 😅.\n\n".
            "📊 Natijani bilish uchun *Nomzod Kodingizni* yuboring (masalan: `TEST1-849201`).\n".
            "Barcha buyruqlarni ko'rish uchun /help ni bosing.";

        $this->sendSafeMessage($chatId, $text, null, 'Markdown');
    }

    /**
     * /start command — Welcome with WebApp button
     */
    public function sendWelcomeMessage($update, int|string $chatId): void
    {
        $from = $update['message']['from'] ?? [];

        $ref_telegram_id = isset($update['message']['text']) && str_starts_with($update['message']['text'], '/start ')
            ? trim(str_replace('/start ', '', $update['message']['text']))
            : null;

        $user = User::where('telegram_id', $chatId)->first();

        if (! $user) {
            $user = User::create([
                'telegram_id' => $chatId,
                'name' => trim(($from['first_name'] ?? '').' '.($from['last_name'] ?? '')),
                'username' => $from['username'] ?? null,
                'avatar' => $from['photo_url'] ?? null,
                'ref_telegram_id' => $ref_telegram_id,
            ]);
        } else {
            $user->update([
                'name' => trim(($from['first_name'] ?? '').' '.($from['last_name'] ?? '')),
                'username' => $from['username'] ?? null,
                'avatar' => $from['photo_url'] ?? null,
                'ref_telegram_id' => $user->ref_telegram_id ?? $ref_telegram_id,
            ]);
        }

        // Assign default role only if the user was just created
        if ($user->wasRecentlyCreated) {
            $user->assignRole('Student');
        }

        // 1. Set persistent “Open Mynine” button at the bottom
        $this->setPersistentMenuButton();

        // 2. Inline keyboard inside message
        $keyboard = Keyboard::make()
            ->inline()
            ->row([
                Keyboard::inlineButton([
                    'text' => 'Open Mynine 🎓',
                    'web_app' => ['url' => 'https://mynine.uz/all-test'],
                ]),
            ]);

        $welcomeText = "👋 *Assalomu alaykum, Mynine IELTS platformasiga xush kelibsiz!*\n\n".
            "📊 Mock imtihoni natijangizni bilish uchun o'zingizga berilgan *Nomzod Kodini* (masalan: `TEST1-849201`) yuboring.\n\n".
            'Platformani ochish uchun quyidagi tugmani bosing:';

        $this->sendSafeMessage(
            $chatId,
            $welcomeText,
            $keyboard,
            'Markdown'
        );

        if (! $ref_telegram_id) {
            $this->sendRefMessage($chatId);
        }

        $this->telegram->setMyCommands([
            'commands' => [
                [
                    'command' => 'start',
                    'description' => 'Platformani ochish 🎓',
                ],
                [
                    'command' => 'result',
                    'description' => 'Imtihon natijasini bilish 📊',
                ],
                [
                    'command' => 'mocks',
                    'description' => 'Faol mock testlar 🧪',
                ],
                [
                    'command' => 'ref',
                    'description' => 'Referral havola olish 🔗',
                ],
                [
                    'command' => 'help',
                    'description' => 'Yordam va buyruqlar ℹ️',
                ],
            ],
        ]);
    }

    /**
     * /mocks command — Active mock tests list
     */
    public function sendMockMessage(int|string $chatId): void
    {
        $user = User::where('telegram_id', $chatId)->first();
        if (! $user) {
            $this->sendSafeMessage($chatId, "❗ Iltimos, avvalo Mynine botiga /start buyrug'i orqali kiring.");

            return;
        }

        $mocks = Mock::query()
            ->where('finished_at', '>', now())
            ->whereHas('user', function ($query) use ($user) {
                $query->where('telegram_id', '=', $user->ref_telegram_id);
            })
            ->get(['name', 'slug']);

        if ($mocks->isEmpty()) {
            $this->sendSafeMessage($chatId, '😕 Hozircha faol mock testlar mavjud emas.');

            return;
        }

        $keyboard = Keyboard::make()->inline();

        foreach ($mocks as $mock) {
            $keyboard->row([
                Keyboard::inlineButton([
                    'text' => "🧪 {$mock->name}",
                    'web_app' => [
                        'url' => 'https://mynine.uz',
                    ],
                ]),
            ]);
        }

        $this->sendSafeMessage(
            $chatId,
            '🧠 Quyidagi faol mock testlardan birini tanlang:',
            $keyboard
        );
    }

    public function sendRefMessage(int|string $chatId): void
    {
        $this->sendSafeMessage(
            $chatId,
            "Sizning taklif havolangiz: https://t.me/MynineUzBot?start={$chatId}"
        );
    }

    /**
     * Safe message sender (catches Telegram API errors)
     */
    protected function sendSafeMessage(int|string $chatId, string $text, ?Keyboard $keyboard = null, ?string $parseMode = null): void
    {
        try {
            $params = [
                'chat_id' => $chatId,
                'text' => $text,
            ];
            if ($parseMode) {
                $params['parse_mode'] = $parseMode;
            }
            if ($keyboard) {
                $params['reply_markup'] = $keyboard;
            }
            $this->telegram->sendMessage($params);
        } catch (\Exception $e) {
            Log::error('Telegram sendMessage error: '.$e->getMessage());
        }
    }

    /**
     * 🔹 Add persistent web app button (like Telegram Wallet)
     */
    public function setPersistentMenuButton(): void
    {
        try {
            $this->telegram->post('setChatMenuButton', [
                'menu_button' => [
                    'type' => 'web_app',
                    'text' => 'Open Mynine 🎓',
                    'web_app' => [
                        'url' => 'https://mynine.uz',
                    ],
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to set persistent menu button: '.$e->getMessage());
        }
    }
}
