<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Hash;

class Setting extends Model
{
    public const DESKTOP_EXIT_PASSWORD = 'desktop_exit_password';

    public const DESKTOP_EXIT_PASSWORD_OFFLINE = 'desktop_exit_password_offline';

    /** JSON {"path": "<local disk path>", "sha256": "..."}: the exam app's code-screen background. */
    public const DESKTOP_BACKGROUND = 'desktop_background';

    public const PBKDF2_ITERATIONS = 120000;

    protected $primaryKey = 'key';

    protected $keyType = 'string';

    public $incrementing = false;

    protected $fillable = [
        'key',
        'value',
    ];

    public static function get(string $key, ?string $default = null): ?string
    {
        return static::query()->whereKey($key)->value('value') ?? $default;
    }

    public static function set(string $key, ?string $value): void
    {
        static::query()->updateOrCreate(['key' => $key], ['value' => $value]);
    }

    /**
     * Store the center-wide desktop exit password: bcrypt for online checks and a PBKDF2
     * string ("pbkdf2_sha256$<iterations>$<salt_b64>$<hash_b64>") the app can verify offline.
     */
    public static function setExitPassword(string $plain): void
    {
        $salt = random_bytes(16);
        $hash = hash_pbkdf2('sha256', $plain, $salt, self::PBKDF2_ITERATIONS, 32, true);

        static::set(self::DESKTOP_EXIT_PASSWORD, Hash::make($plain));
        static::set(self::DESKTOP_EXIT_PASSWORD_OFFLINE, sprintf(
            'pbkdf2_sha256$%d$%s$%s',
            self::PBKDF2_ITERATIONS,
            base64_encode($salt),
            base64_encode($hash),
        ));
    }

    public static function checkExitPassword(string $plain): bool
    {
        $hash = static::get(self::DESKTOP_EXIT_PASSWORD);

        return $hash !== null && Hash::check($plain, $hash);
    }
}
