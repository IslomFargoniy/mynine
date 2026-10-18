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
            'id' => 'required|numeric',
            'first_name' => 'nullable|string',
            'last_name' => 'nullable|string',
            'username' => 'nullable|string',
            'photo_url' => 'nullable|string',
        ]);

        $isLocal = app()->environment('local');
        $initData = $data['initData'] ?? '';

        if (! empty($initData)) {
            if (! $this->verifyTelegramWebApp($initData)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid Telegram WebApp signature',
                ], 403);
            }
        } elseif (! $isLocal) {
            return response()->json([
                'success' => false,
                'message' => 'Telegram authentication initData is required',
            ], 403);
        }

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
            'redirect' => route('all-test.index'),
        ]);
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
        if (! isset($data['auth_date']) || abs(time() - (int) $data['auth_date']) > 86400) {
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
