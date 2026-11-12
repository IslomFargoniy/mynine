<?php

namespace App\Http\Requests\Auth;

use App\Models\User\User;
use Illuminate\Auth\Events\Lockout;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email_or_phone' => ['required', 'string'],
            'password' => ['required', 'string'],
        ];
    }

    public function authenticate(): void
    {
        $this->ensureIsNotRateLimited();

        $loginInput = (string) $this->input('email_or_phone');
        $isEmail = filter_var($loginInput, FILTER_VALIDATE_EMAIL) !== false;
        $credentials = [
            $isEmail ? 'email' : 'phone' => $loginInput,
            'password' => $this->input('password'),
        ];

        if (! $isEmail) {
            // The same number may be stored in different formats: log in only when exactly one account has it.
            $matches = User::withSamePhone($loginInput);
            if ($matches->count() > 1) {
                RateLimiter::hit($this->throttleKey());

                throw ValidationException::withMessages([
                    'email_or_phone' => __('phone_login_ambiguous'),
                ]);
            }
            if ($matches->count() === 1) {
                $credentials['phone'] = $matches->first()->phone;
            }
        }

        if (! Auth::attempt($credentials, $this->boolean('remember'))) {
            RateLimiter::hit($this->throttleKey());

            throw ValidationException::withMessages([
                'email_or_phone' => __('auth.failed'),
            ]);
        }

        RateLimiter::clear($this->throttleKey());
    }

    public function ensureIsNotRateLimited(): void
    {
        if (! RateLimiter::tooManyAttempts($this->throttleKey(), 5)) {
            return;
        }

        event(new Lockout($this));

        $seconds = RateLimiter::availableIn($this->throttleKey());

        throw ValidationException::withMessages([
            'email_or_phone' => __('auth.throttle', [
                'seconds' => $seconds,
                'minutes' => ceil($seconds / 60),
            ]),
        ]);
    }

    public function throttleKey(): string
    {
        return Str::transliterate(Str::lower($this->string('email_or_phone')).'|'.$this->ip());
    }
}
