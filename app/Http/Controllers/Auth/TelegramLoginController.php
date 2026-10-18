<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TelegramLoginController extends Controller
{
    public function handle(Request $request)
    {
        // Telegram sends user info via POST
        $data = $request->all();

        // Validate Telegram login
        if (! $this->isTelegramDataValid($data)) {
            return redirect()->route('home')->with('error', __('error.invalid_telegram_login'));
        }

        // Create or update user
        $user = User::updateOrCreate(
            ['telegram_id' => $data['id']],
            [
                'name' => trim(($data['first_name'] ?? '').' '.($data['last_name'] ?? '')),
                'username' => SocialUsername::unique($data['username'] ?? null),
                'avatar' => $data['photo_url'] ?? null,
            ]
        );

        // Assign default role only if the user was just created
        if ($user->wasRecentlyCreated) {
            $user->assignRole('Student');
        }

        Auth::login($user);

        return redirect()->route('dashboard');
    }

    private function isTelegramDataValid(array $data): bool
    {
        $botToken = config('services.telegram.mynine_bot_token');
        if (empty($botToken) || ! isset($data['hash'])) {
            return false;
        }

        if (! isset($data['auth_date']) || abs(time() - (int) $data['auth_date']) > 86400) {
            return false;
        }

        $checkHash = $data['hash'];
        unset($data['hash']);

        $dataCheckArr = [];
        foreach ($data as $key => $value) {
            $dataCheckArr[] = $key.'='.$value;
        }

        sort($dataCheckArr);
        $dataCheckString = implode("\n", $dataCheckArr);

        $secretKey = hash('sha256', $botToken, true);
        $hash = hash_hmac('sha256', $dataCheckString, $secretKey);

        return hash_equals($hash, $checkHash);
    }
}
