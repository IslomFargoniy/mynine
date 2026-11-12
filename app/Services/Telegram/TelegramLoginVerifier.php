<?php

namespace App\Services\Telegram;

/**
 * Verifies data signed by the Telegram Login Widget (https://core.telegram.org/widgets/login#checking-authorization).
 */
class TelegramLoginVerifier
{
    /**
     * @param  array<string, mixed>  $data  every field Telegram sent (id, first_name, ..., auth_date, hash)
     */
    public function verifyWidget(array $data): bool
    {
        $botToken = config('services.telegram.mynine_bot_token');
        if (empty($botToken) || ! isset($data['hash']) || ! is_string($data['hash'])) {
            return false;
        }

        // Reject stale payloads (replay protection).
        if (! isset($data['auth_date']) || abs(time() - (int) $data['auth_date']) > 86400) {
            return false;
        }

        $checkHash = $data['hash'];
        unset($data['hash']);

        $dataCheckArr = [];
        foreach ($data as $key => $value) {
            if (is_array($value)) {
                return false;
            }
            $dataCheckArr[] = $key.'='.$value;
        }

        sort($dataCheckArr);
        $dataCheckString = implode("\n", $dataCheckArr);

        $secretKey = hash('sha256', $botToken, true);
        $hash = hash_hmac('sha256', $dataCheckString, $secretKey);

        return hash_equals($hash, $checkHash);
    }
}
