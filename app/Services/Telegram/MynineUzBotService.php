<?php

namespace App\Services\Telegram;

use App\Models\Mock;
use App\Models\MockStudent;
use App\Models\User\User;
use App\Services\IeltsScoreConverter;
use App\Services\MockResultService;
use App\Services\ResultSheetService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\URL;
use Telegram\Bot\Api;
use Telegram\Bot\FileUpload\InputFile;
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
            if ($params !== '') {
                $this->handleCodeInput($chatId, $params);
            } else {
                $this->sendSafeMessage(
                    $chatId,
                    "📊 *Imtihon Natijasini Bilish*\n\nIltimos, kartangizdagi *Candidate Number* (nomzod kodi)ni yuboring.\nMasalan: `000123`",
                    null,
                    'Markdown'
                );
            }

            return;
        }

        // 2. A candidate number ("000123"), the last 4 phone digits after it ("3059"), or both ("000123 3059").
        if (preg_match('/^\d{4}(?:\s+\d{4})?$|^\d{6,9}(?:\s+\d{4})?$/', $text)) {
            $this->handleCodeInput($chatId, $text);

            return;
        }

        // 3. Fallback for unknown input
        $this->sendUnknownCommand($chatId);
    }

    /**
     * Look up candidate code and send detailed exam result
     */
    /**
     * Candidate codes are only 6 digits: at most 5 lookups per chat per 10 minutes, so nobody can walk
     * the code space through the bot.
     */
    private function codeLookupThrottled(int|string $chatId): bool
    {
        $key = 'tg-code-lookup:'.$chatId;
        if (RateLimiter::tooManyAttempts($key, 5)) {
            $this->sendMessage($chatId, "Juda ko'p urinish. Iltimos, 10 daqiqadan keyin qayta urinib ko'ring.");

            return true;
        }
        RateLimiter::hit($key, 600);

        return false;
    }

    /**
     * Candidate numbers are issued in order, so a code alone is not enough: the bot asks for the last 4 digits of the
     * candidate's phone before it shows the result (one message "000123 3059" works too).
     */
    private function handleCodeInput(int|string $chatId, string $text): void
    {
        $parts = preg_split('/\s+/', trim($text)) ?: [];
        $pendingKey = 'tg-pending-code:'.$chatId;

        if (count($parts) === 1 && preg_match('/^\d{4}$/', $parts[0])) {
            $code = Cache::get($pendingKey);
            if (! $code) {
                $this->sendSafeMessage($chatId, 'Avval kartangizdagi Candidate Number (nomzod kodi)ni yuboring. Masalan: 000123');

                return;
            }
            $digits = $parts[0];
        } else {
            $code = $parts[0] ?? '';
            $digits = $parts[1] ?? null;
        }

        if (! preg_match(MockStudent::CODE_PATTERN, $code)) {
            $this->sendUnknownCommand($chatId);

            return;
        }

        if ($digits === null) {
            Cache::put($pendingKey, $code, now()->addMinutes(10));
            $this->sendSafeMessage(
                $chatId,
                "🔐 *Tasdiqlash*\n\n`{$code}` kodi uchun ro'yxatdan o'tishda berilgan telefon raqamingizning *oxirgi 4 raqamini* yuboring.\nMasalan: `3059`",
                null,
                'Markdown'
            );

            return;
        }

        if ($this->codeLookupThrottled($chatId)) {
            return;
        }

        $student = MockStudent::withoutGlobalScopes()->where('code', $code)->first();
        $phone = preg_replace('/\D/', '', (string) $student?->phone);
        if (! $student || strlen($phone) < 4 || ! hash_equals(substr($phone, -4), $digits)) {
            // One answer for "no such code" and "wrong digits": the bot does not say which codes exist.
            $this->sendSafeMessage(
                $chatId,
                "❌ Kod yoki telefon raqamining oxirgi 4 raqami mos kelmadi.\n\nQaytadan yuboring, masalan: `000123 3059`. Telefon raqami ro'yxatda bo'lmasa, natijani markaz qabulxonasidan oling.",
                null,
                'Markdown'
            );

            return;
        }

        Cache::forget($pendingKey);
        $this->sendCandidateResult($chatId, $student->code);
    }

    /**
     * The result of a verified candidate (see handleCodeInput).
     */
    protected function sendCandidateResult(int|string $chatId, string $rawCode): void
    {
        $code = strtoupper(trim($rawCode));

        $student = MockStudent::where('code', $code)
            ->with([
                'mock',
                'attempt.attempt_types.type',
                'attempt.test.folder',
            ])
            ->first();

        if (! $student) {
            $this->sendSafeMessage(
                $chatId,
                "❌ *Nomzod Kodi topilmadi*\n\nSiz kiritgan `{$code}` kodi bo'yicha hech qanday ma'lumot topilmadi.\n\nIltimos, kodingizni to'g'ri kiritganingizni tekshiring (masalan: `000123`).",
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

        // Module scores: same rules as the result page / PDF (Reading by test variant, Writing (T1 + 2*T2) / 3 or confirmed).
        $bands = app(MockResultService::class)->attemptBands($attempt);
        $listeningRaw = $bands['listening_correct'];
        $readingRaw = $bands['reading_correct'];
        $listeningBand = $bands['listening'];
        $readingBand = $bands['reading'];
        $writingBand = $bands['writing_pending'] ? null : $bands['writing'];
        $speakingBand = $bands['speaking'];

        $overallBand = $bands['overall'] ?? 0.0;
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

        // The result sheet (PDF) only once every module is ready (Writing checked, Speaking marked).
        $sheets = app(ResultSheetService::class);
        $sheet = $sheets->sheet($student);
        $msg .= $sheet
            ? '📄 Natija varaqasi (PDF) quyida yuborildi.'
            : "📄 Natija varaqasi (PDF) barcha modullar natijasi tayyor bo'lganda shu yerda yuklab olinadi. Kodingizni keyinroq qayta yuboring.";

        $keyboard = Keyboard::make()->inline();
        if ($sheet) {
            $keyboard->row([
                Keyboard::inlineButton([
                    'text' => '📊 Batafsil tahlil (PDF)',
                    'url' => url(URL::temporarySignedRoute('attempt.pdf', now()->addDays(30), ['attempt' => $attempt->id], false)),
                ]),
            ]);
        }

        // The detailed web page requires a login, so only offer it to registered candidates
        if ($attempt->user_id) {
            $keyboard->row([
                Keyboard::inlineButton([
                    'text' => '🔍 Batafsil Natijani Ko\'rish',
                    'web_app' => ['url' => route('attempt.show', $attempt->id)],
                ]),
            ]);
        }

        $this->sendSafeMessage($chatId, $msg, $sheet || $attempt->user_id ? $keyboard : null, 'Markdown');

        if ($sheet) {
            $this->sendResultSheet($chatId, $student, $sheets->pdf([$sheet]));
        }
    }

    /**
     * The result sheet as a PDF document in the chat.
     */
    protected function sendResultSheet(int|string $chatId, MockStudent $student, string $pdf): void
    {
        try {
            $this->telegram->sendDocument([
                'chat_id' => $chatId,
                'document' => InputFile::createFromContents($pdf, 'Result_'.$student->code.'.pdf'),
                'caption' => '📄 '.$student->name.' — natija varaqasi',
            ]);
        } catch (\Exception $e) {
            Log::error('Telegram sendDocument error: '.$e->getMessage());
            $this->sendSafeMessage($chatId, 'PDF yuborilmadi. Iltimos, birozdan keyin kodingizni qayta yuboring.');
        }
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
            "💡 *Maslahat:* Imtihon natijangizni bilish uchun shunchaki kartangizdagi Candidate Number'ni (masalan: `000123`) yuboring, so'ng telefon raqamingizning oxirgi 4 raqamini kiriting!";

        $this->sendSafeMessage($chatId, $text, null, 'Markdown');
    }

    /**
     * Unknown command handler
     */
    protected function sendUnknownCommand(int|string $chatId): void
    {
        $text = "Kechirasiz, buyruq tushunarsiz 😅.\n\n".
            "📊 Natijani bilish uchun *Candidate Number*ni yuboring (masalan: `000123`).\n".
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
                    'web_app' => ['url' => 'https://mynine.uz/test-bank'],
                ]),
            ]);

        $welcomeText = "👋 *Assalomu alaykum, Mynine IELTS platformasiga xush kelibsiz!*\n\n".
            "📊 Mock imtihoni natijangizni bilish uchun kartangizdagi *Candidate Number*ni (masalan: `000123`) yuboring.\n\n".
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
