<?php

namespace App\Http\Middleware\Desktop;

use App\Exceptions\ApiException;
use App\Models\MockStudent;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Laravel\Sanctum\PersonalAccessToken;
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
            throw $this->tokenError($request);
        }

        $attempt = $candidate->attempt;
        $device = $request->attributes->get('device');

        if (! $attempt || ($device && (int) $attempt->device_id !== (int) $device->id)) {
            throw new ApiException(401, 'session_revoked', 'This exam session is active on another PC.');
        }

        $request->attributes->set('candidate', $candidate);
        $request->attributes->set('attempt', $attempt);

        return $next($request);
    }

    /**
     * 401 with a reason the app can show: the token was deleted (another login, submit, released by the
     * invigilator) → session_revoked; it ran out → session_expired; no / unknown token → unauthenticated.
     */
    private function tokenError(Request $request): ApiException
    {
        $bearer = $request->bearerToken();
        if (! $bearer) {
            return ApiException::unauthenticated();
        }

        if (str_contains($bearer, '|')) {
            [$id] = explode('|', $bearer, 2);
            $token = ctype_digit($id) ? PersonalAccessToken::find($id) : null;

            if (! $token) {
                return new ApiException(401, 'session_revoked', 'This exam session was closed. Enter your code again.');
            }

            if ($token->expires_at !== null && $token->expires_at->isPast()) {
                return new ApiException(401, 'session_expired', 'This exam session has expired. Enter your code again.');
            }
        }

        return ApiException::unauthenticated();
    }
}
