<?php

namespace App\Http\Middleware\Student;

use App\Exceptions\ApiException;
use App\Models\User\User;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

/**
 * Mobile student API: a Sanctum token with the "student" ability issued to a Student user.
 * Staff (center Admins, Reception, the SuperAdmin) use the website; suspended users are signed out.
 */
class AuthenticateStudent
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = Auth::guard('sanctum')->user();

        if (! $user instanceof User || ! $user->tokenCan('student')) {
            throw ApiException::unauthenticated();
        }

        if ($user->isStaff()) {
            throw new ApiException(403, 'staff_account', 'Staff accounts use the mynine.uz website.');
        }

        if ($user->isSuspended()) {
            $user->currentAccessToken()?->delete();

            throw new ApiException(401, 'account_suspended', 'This account is suspended.');
        }

        Auth::setUser($user);

        return $next($request);
    }
}
