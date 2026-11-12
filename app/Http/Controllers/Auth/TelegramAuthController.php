<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TelegramAuthController extends Controller
{
    public function login(Request $request)
    {
        $data = $request->validate([
            'initData' => 'nullable|string',
        ]);

        $initData = $data['initData'] ?? '';
        $tgUser = $initData !== '' ? $this->verifiedTelegramUser($initData) : null;

        if (! $tgUser) {
            // Only the signed "user" object inside initData identifies the account; the request's own
            // id / name fields are never trusted (they let anyone sign in as any Telegram id).
            return response()->json([
                'success' => false,
                'message' => $initData === '' ? 'Telegram authentication initData is required' : 'Invalid Telegram WebApp signature',
            ], 403);
        }

        $data = [
            'id' => $tgUser['id'],
            'first_name' => $tgUser['first_name'] ?? null,
            'last_name' => $tgUser['last_name'] ?? null,
            'username' => $tgUser['username'] ?? null,
            'photo_url' => $tgUser['photo_url'] ?? null,
        ];

        // 1️⃣ Try to find by telegram_id or by email (if older record exists)
        $user = User::where('telegram_id', $data['id'])
            ->first();

        if (! $user) {
            // 2️⃣ Create new user if not found
            $user = new User;
            $user->telegram_id = $data['id'];
        }

        // 3️⃣ Update basic info
        $user->name = trim(($data['first_name'] ?? '').' '.($data['last_name'] ?? ''));
        $user->username = $data['username'] ?? null;
        $user->avatar = $data['photo_url'] ?? null;
        $user->save();

        // Assign default role only if the user was just created
        if ($user->wasRecentlyCreated) {
            $user->assignRole('Student');
        }

        // 5️⃣ Log in user
        Auth::login($user, true);

        return response()->json([
            'success' => true,
            'redirect' => route('test-bank.index'),
        ]);
    }

    /**
     * The Telegram user of a correctly signed WebApp initData (max 1 hour old), or null.
     *
     * @return array{id: int, first_name?: string, last_name?: string, username?: string, photo_url?: string}|null
     */
    private function verifiedTelegramUser(string $initData): ?array
    {
        if (! $this->verifyTelegramWebApp($initData)) {
            return null;
        }
        parse_str($initData, $fields);
        $user = json_decode((string) ($fields['user'] ?? ''), true);

        return is_array($user) && isset($user['id']) && is_numeric($user['id'])
            ? ['id' => (int) $user['id']] + array_filter(
                array_intersect_key($user, array_flip(['first_name', 'last_name', 'username', 'photo_url'])),
                'is_string',
            )
            : null;
    }

    private function verifyTelegramWebApp(string $initData): bool
    {
        $botToken = config('services.telegram.mynine_bot_token');
        if (empty($botToken) || empty($initData)) {
            return false;
        }

        parse_str($initData, $data);

        if (! isset($data['hash'])) {
            return false;
        }

        // Reject stale payloads (replay protection): Telegram signs auth_date as a unix timestamp
        if (! isset($data['auth_date']) || abs(time() - (int) $data['auth_date']) > 3600) {
            return false;
        }

        $checkHash = $data['hash'];
        unset($data['hash']);

        ksort($data);

        $dataCheckArr = [];
        foreach ($data as $key => $value) {
            $dataCheckArr[] = $key.'='.$value;
        }
        $dataCheckString = implode("\n", $dataCheckArr);

        $secretKey = hash_hmac('sha256', $botToken, 'WebAppData', true);
        $hash = hash_hmac('sha256', $dataCheckString, $secretKey);

        return hash_equals($hash, $checkHash);
    }
}
