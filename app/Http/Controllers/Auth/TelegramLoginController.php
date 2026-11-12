<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User\User;
use App\Services\Telegram\TelegramLoginVerifier;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TelegramLoginController extends Controller
{
    public function handle(Request $request, TelegramLoginVerifier $verifier)
    {
        // Telegram sends user info via POST
        $data = $request->all();

        // Validate Telegram login
        if (! $verifier->verifyWidget($data)) {
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
}
