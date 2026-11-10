<?php

namespace App\Http\Middleware\Desktop;

use App\Exceptions\ApiException;
use App\Models\MockStudent;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

/**
 * Exam endpoints: a Sanctum token issued to a MockStudent with the "exam" ability, used from the
 * PC its attempt is bound to. Sets request attributes "candidate" and "attempt".
 */
class AuthenticateCandidate
{
    public function handle(Request $request, Closure $next): Response
    {
        $candidate = Auth::guard('sanctum')->user();

        if (! $candidate instanceof MockStudent || ! $candidate->tokenCan('exam')) {
            throw ApiException::unauthenticated();
        }

        $attempt = $candidate->attempt;
        $device = $request->attributes->get('device');

        if (! $attempt || ($device && (int) $attempt->device_id !== (int) $device->id)) {
            throw ApiException::unauthenticated('This exam session is active on another PC.');
        }

        $request->attributes->set('candidate', $candidate);
        $request->attributes->set('attempt', $attempt);

        return $next($request);
    }
}
