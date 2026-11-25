<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Services\Student\GoogleWebSignIn;
use App\Services\Student\StudentAccounts;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Laravel\Socialite\Facades\Socialite;

/**
 * Browser Google sign-in for the mobile apps: GET /app/google?state=… → Google → /app/google/callback,
 * which sends the browser back to the app at mynine://auth?token=…&state=… (state is the app's own nonce).
 */
class AppGoogleController extends Controller
{
    public function redirect(Request $request)
    {
        $state = (string) $request->query('state', '');
        abort_unless(preg_match('/^[A-Za-z0-9_-]{16,64}$/', $state), 400);
        $request->session()->put('app_google_state', $state);

        return $this->driver()->with(['prompt' => 'select_account'])->redirect();
    }

    public function callback(Request $request, StudentAccounts $accounts, GoogleWebSignIn $signIn)
    {
        $state = (string) $request->session()->pull('app_google_state', '');
        $params = ['state' => $state];

        try {
            $google = $this->driver()->user();
            if (! $google->getEmail()) {
                throw new \RuntimeException('Google account has no email');
            }
            $user = $accounts->fromGoogle((string) $google->getId(), $google->getEmail(), $google->getName(), $google->getAvatar());
            $params['token'] = $signIn->issue($user);
        } catch (\Throwable $e) {
            Log::warning('App Google sign-in failed: '.$e->getMessage());
            $params['error'] = 'google';
        }

        // A plain redirect to the app's scheme: Custom Tabs / browsers hand it to the app and close the tab.
        return redirect()->away('mynine://auth?'.http_build_query($params));
    }

    private function driver()
    {
        return Socialite::driver('google')->redirectUrl(route('app.google.callback'));
    }
}
