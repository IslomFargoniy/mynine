<?php

namespace App\Http\Middleware;

use App\Models\User\User;
use App\Support\CurrentCenter;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * A suspended center (status suspended or contract ended) is read-only for its Admin and Reception: they may
 * open pages and print results (GET), but nothing that changes data (new mocks, candidates, exam actions).
 * The SuperAdmin is never blocked.
 */
class EnsureCenterIsActive
{
    public function __construct(private readonly CurrentCenter $center) {}

    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user instanceof User && $user->isStaff() && ! $user->isSuperAdmin()
            && ! $request->isMethodSafe() && $this->center->isSuspended($user->centerId())) {
            $message = __('center_suspended');

            if ($request->expectsJson() && ! $request->header('X-Inertia')) {
                return response()->json(['message' => $message, 'code' => 'center_suspended'], 403);
            }

            return back()->with('error', $message);
        }

        return $next($request);
    }
}
