<?php

namespace App\Services\Student;

use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Identity tokens from the native sign-in SDKs: Google (Android Credential Manager, GoogleSignIn-iOS) and
 * Sign in with Apple. Returns the verified claims or null.
 */
class SocialTokenVerifier
{
    /**
     * @return array{sub: string, email: ?string, name: ?string, picture: ?string}|null
     */
    public function google(string $idToken): ?array
    {
        $allowed = config('mobile.google_client_ids', []);
        if ($allowed === []) {
            return null;
        }

        try {
            $response = Http::timeout(10)->get('https://oauth2.googleapis.com/tokeninfo', ['id_token' => $idToken]);
        } catch (\Throwable $e) {
            Log::warning('Google tokeninfo failed: '.$e->getMessage());

            return null;
        }

        $claims = $response->successful() ? $response->json() : null;
        if (! is_array($claims)
            || ! in_array($claims['aud'] ?? null, $allowed, true)
            || ! in_array($claims['iss'] ?? null, ['accounts.google.com', 'https://accounts.google.com'], true)
            || (int) ($claims['exp'] ?? 0) < time()
            || empty($claims['sub'])
            || empty($claims['email'])
            || ! filter_var($claims['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN)) {
            return null;
        }

        return [
            'sub' => (string) $claims['sub'],
            'email' => (string) $claims['email'],
            'name' => $claims['name'] ?? null,
            'picture' => $claims['picture'] ?? null,
        ];
    }

    /**
     * @return array{sub: string, email: ?string, name: ?string, picture: ?string}|null
     */
    public function apple(string $identityToken): ?array
    {
        try {
            $keys = Cache::remember('apple-auth-keys', now()->addHours(12), function () {
                return Http::timeout(10)->get('https://appleid.apple.com/auth/keys')->throw()->json();
            });

            $claims = (array) JWT::decode($identityToken, JWK::parseKeySet($keys, 'RS256'));
        } catch (\Throwable $e) {
            Cache::forget('apple-auth-keys');
            Log::info('Apple identity token rejected: '.$e->getMessage());

            return null;
        }

        if (($claims['iss'] ?? null) !== 'https://appleid.apple.com'
            || ($claims['aud'] ?? null) !== config('mobile.apple_bundle_id')
            || empty($claims['sub'])) {
            return null;
        }

        $verified = filter_var($claims['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN);

        return [
            'sub' => (string) $claims['sub'],
            'email' => $verified && ! empty($claims['email']) ? (string) $claims['email'] : null,
            'name' => null,
            'picture' => null,
        ];
    }
}
