<?php

namespace App\Http\Controllers\Api\Student;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Models\User\User;
use App\Services\Student\AppLoginCodes;
use App\Services\Student\GoogleWebSignIn;
use App\Services\Student\SocialTokenVerifier;
use App\Services\Student\StudentAccounts;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

/**
 * Mobile sign-in: Telegram bot code, email/username + password, Google and Apple identity tokens.
 * Every route returns {token, user}; the token has the "student" ability only.
 */
class AuthController extends Controller
{
    public function __construct(
        private readonly SocialTokenVerifier $verifier,
        private readonly StudentAccounts $accounts,
    ) {}

    /**
     * POST /student/auth/telegram {code} — the 6-digit code @MynineUzBot sent (or the store reviewer code).
     */
    public function telegram(Request $request, AppLoginCodes $codes): JsonResponse
    {
        $data = $request->validate(['code' => ['required', 'string', 'max:32']]);
        $code = trim($data['code']);

        $reviewerCode = (string) config('mobile.reviewer_code');
        if ($reviewerCode !== '' && hash_equals($reviewerCode, $code)) {
            $user = User::where('email', config('mobile.reviewer_email'))->first();
        } else {
            $user = $codes->consume($code);
        }

        if (! $user) {
            throw ApiException::unprocessable('invalid_code', 'The code is wrong or has expired. Get a new one from the bot.');
        }

        return $this->issue($request, $user);
    }

    /**
     * POST /student/auth/password {login, password} — email or username.
     */
    public function password(Request $request): JsonResponse
    {
        $data = $request->validate([
            'login' => ['required', 'string', 'max:255'],
            'password' => ['required', 'string', 'max:255'],
        ]);

        $login = trim($data['login']);
        $user = User::where(str_contains($login, '@') ? 'email' : 'username', $login)->first();

        if (! $user || ! $user->password || ! Hash::check($data['password'], $user->password)) {
            throw ApiException::unprocessable('invalid_credentials', 'Wrong login or password.');
        }

        return $this->issue($request, $user);
    }

    /**
     * POST /student/auth/google {id_token}
     */
    public function google(Request $request): JsonResponse
    {
        $data = $request->validate(['id_token' => ['required', 'string', 'max:8192']]);
        $claims = $this->verifier->google($data['id_token']);
        if (! $claims) {
            throw ApiException::unprocessable('invalid_token', 'Google sign-in failed. Try again.');
        }

        $user = $this->accounts->fromGoogle($claims['sub'], $claims['email'], $claims['name'] ?: null, $claims['picture'] ?: null);

        return $this->issue($request, $user);
    }

    /**
     * POST /student/auth/apple {identity_token, name?} — Apple sends the name only on the first sign-in.
     */
    public function apple(Request $request): JsonResponse
    {
        $data = $request->validate([
            'identity_token' => ['required', 'string', 'max:8192'],
            'name' => ['nullable', 'string', 'max:255'],
        ]);
        $claims = $this->verifier->apple($data['identity_token']);
        if (! $claims) {
            throw ApiException::unprocessable('invalid_token', 'Apple sign-in failed. Try again.');
        }

        $user = User::where('apple_id', $claims['sub'])->first()
            ?? ($claims['email'] ? User::where('email', $claims['email'])->first() : null);

        if (! $user) {
            $name = trim((string) ($data['name'] ?? '')) ?: 'Apple user';
            $user = $this->createStudent($name, $claims['email'], ['apple_id' => $claims['sub']]);
        } elseif (! $user->apple_id) {
            $user->forceFill(['apple_id' => $claims['sub']])->saveQuietly();
        }

        return $this->issue($request, $user);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['status' => 'ok']);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json(['user' => self::userPayload($request->user())]);
    }

    /**
     * PATCH /student/me {name}
     */
    public function update(Request $request): JsonResponse
    {
        $data = $request->validate(['name' => ['required', 'string', 'min:2', 'max:255']]);
        $user = $request->user();
        $user->forceFill(['name' => trim($data['name'])])->save();

        return response()->json(['user' => self::userPayload($user)]);
    }

    /**
     * DELETE /student/me — delete the account (App Store 5.1.1(v), Google Play). Same as the website's
     * Settings → Delete account.
     */
    public function destroy(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->tokens()->delete();
        $user->delete();

        return response()->json(['status' => 'deleted']);
    }

    /**
     * GET /student/app/version?platform=android|ios
     */
    public function version(Request $request): JsonResponse
    {
        $platform = $request->query('platform') === 'ios' ? 'ios' : 'android';

        return response()->json(config('mobile.'.$platform) + ['platform' => $platform]);
    }

    /**
     * POST /student/auth/google/exchange {token} — the one-time token the browser sign-in
     * (GET /app/google → Google → /app/google/callback) handed back to the app in mynine://auth.
     */
    public function googleExchange(Request $request, GoogleWebSignIn $signIn): JsonResponse
    {
        $data = $request->validate(['token' => ['required', 'string', 'max:128']]);
        $user = $signIn->consume($data['token']);
        if (! $user) {
            throw ApiException::unprocessable('invalid_token', 'Google sign-in expired. Try again.');
        }

        return $this->issue($request, $user);
    }

    private function createStudent(string $name, ?string $email, array $attributes): User
    {
        return $this->accounts->create($name, $email, $attributes);
    }

    private function issue(Request $request, User $user): JsonResponse
    {
        if ($user->isStaff()) {
            throw new ApiException(403, 'staff_account', 'Staff accounts use the mynine.uz website.');
        }
        if ($user->isSuspended()) {
            throw new ApiException(403, 'account_suspended', 'This account is suspended.');
        }
        if (! $user->hasAnyRole(['Student'])) {
            $user->assignRole('Student');
        }

        $platform = in_array($request->header('X-Platform'), ['android', 'ios'], true) ? $request->header('X-Platform') : 'mobile';
        $token = $user->createToken('app:'.$platform, ['student'], now()->addDays(config('mobile.token_days', 90)));

        return response()->json([
            'token' => $token->plainTextToken,
            'user' => self::userPayload($user),
        ]);
    }

    public static function userPayload(User $user): array
    {
        return [
            'id' => (int) $user->id,
            'name' => (string) $user->name,
            'email' => $user->email,
            'username' => $user->username,
            'avatar' => $user->avatar,
            'telegram_connected' => $user->telegram_id !== null,
            'google_connected' => $user->google_id !== null,
            'apple_connected' => $user->apple_id !== null,
            'created_at' => $user->created_at?->toIso8601String(),
        ];
    }
}
