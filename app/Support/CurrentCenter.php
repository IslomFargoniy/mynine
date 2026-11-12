<?php

namespace App\Support;

use App\Models\CenterSetting;
use App\Models\User\User;
use Closure;
use Illuminate\Support\Facades\Auth;

/**
 * The center (= Admin user id) the current request works for. Read by the CenterScope global scope of every
 * center-owned model and by the policies.
 *
 *  - Admin: their own id. Reception: their Admin (users.owner_id). SuperAdmin: the center chosen on the
 *    Centers page (session), by default their own "Mynine" center.
 *  - Desktop API: the device's center (set by the desktop.device middleware as a request attribute).
 *  - Students, guests, console and queue jobs: null = no center scoping (their access is limited by routes
 *    and policies; jobs work on ids they were given).
 *
 * A staff user without a center gets NONE (0), which matches no row, so a broken staff account sees nothing
 * instead of everything.
 */
class CurrentCenter
{
    public const SESSION_KEY = 'center.active';

    public const REQUEST_ATTRIBUTE = 'center.id';

    public const NONE = 0;

    /** @var array<int, ?int> explicit centers set by runAs(), innermost last; null entries disable scoping */
    private array $stack = [];

    private ?int $mynineId = null;

    /** @var array<int, true> */
    private array $knownCenters = [];

    public function id(): ?int
    {
        if ($this->stack !== []) {
            return end($this->stack);
        }

        $request = app('request');
        if ($request->attributes->has(self::REQUEST_ATTRIBUTE)) {
            return (int) $request->attributes->get(self::REQUEST_ATTRIBUTE);
        }

        $user = Auth::user();

        return $user instanceof User ? $this->forUser($user) : null;
    }

    /**
     * The center a staff user works for right now (null for students).
     */
    public function forUser(User $user): ?int
    {
        if ($user->isSuperAdmin()) {
            $request = app('request');
            $active = $request->hasSession() ? (int) $request->session()->get(self::SESSION_KEY) : 0;

            return $active > 0 && $active !== (int) $user->id && $this->isCenter($active) ? $active : (int) $user->id;
        }

        if ($user->isStaff()) {
            return $user->homeCenterId() ?? self::NONE;
        }

        return null;
    }

    /**
     * Run $callback as $centerId (null = without center scoping, for system lookups).
     *
     * @template T
     *
     * @param  Closure(): T  $callback
     * @return T
     */
    public function runAs(?int $centerId, Closure $callback): mixed
    {
        $this->stack[] = $centerId;

        try {
            return $callback();
        } finally {
            array_pop($this->stack);
        }
    }

    /**
     * @template T
     *
     * @param  Closure(): T  $callback
     * @return T
     */
    public function withoutScope(Closure $callback): mixed
    {
        return $this->runAs(null, $callback);
    }

    public function settings(?int $centerId = null): ?CenterSetting
    {
        $centerId ??= $this->id();

        return $centerId ? CenterSetting::query()->where('owner_id', $centerId)->first() : null;
    }

    public function isSuspended(?int $centerId = null): bool
    {
        return (bool) $this->settings($centerId)?->isSuspended();
    }

    /**
     * Owner id of the platform's own center (code MYNINE), which owns practice tests and students.
     */
    public function mynineId(): ?int
    {
        return $this->mynineId ??= CenterSetting::query()->where('code', CenterSetting::MYNINE_CODE)->value('owner_id');
    }

    public function isMynine(?int $centerId): bool
    {
        return $centerId !== null && $centerId !== self::NONE && $centerId === $this->mynineId();
    }

    public function isCenter(int $userId): bool
    {
        if (isset($this->knownCenters[$userId])) {
            return true;
        }

        if (CenterSetting::query()->where('owner_id', $userId)->exists()) {
            return $this->knownCenters[$userId] = true;
        }

        return false;
    }
}
