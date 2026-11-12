<?php

namespace App\Rules;

use App\Models\User\User;
use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

/**
 * No other user has the same phone number in any format (phone is a login identifier).
 */
class UniquePhone implements ValidationRule
{
    public function __construct(private readonly ?int $ignoreUserId = null) {}

    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (! is_string($value) || trim($value) === '') {
            return;
        }

        if (User::withSamePhone($value, $this->ignoreUserId)->isNotEmpty()) {
            $fail(__('phone_taken'));
        }
    }
}
