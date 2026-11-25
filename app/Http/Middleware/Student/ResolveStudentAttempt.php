<?php

namespace App\Http\Middleware\Student;

use App\Exceptions\ApiException;
use App\Models\Attempt;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

/**
 * /student/attempts/{attempt}/...: the student's own practice attempt (never a mock attempt, never someone
 * else's). Sets the "attempt" request attribute, so the desktop exam controllers (modules, answers, audio)
 * serve the mobile app unchanged.
 */
class ResolveStudentAttempt
{
    public function handle(Request $request, Closure $next): Response
    {
        $id = $request->route('attempt');
        $attempt = ctype_digit((string) $id)
            ? Attempt::whereKey((int) $id)->where('user_id', Auth::id())->whereNull('mock_id')->first()
            : null;

        if (! $attempt) {
            throw ApiException::notFound('Attempt not found.');
        }

        $request->attributes->set('attempt', $attempt);
        // The desktop controllers take {attempt} only through the attribute; drop the raw route parameter so
        // their own route parameters ({typeId}, {part}, {test}) bind by name.
        $request->route()->forgetParameter('attempt');

        return $next($request);
    }
}
