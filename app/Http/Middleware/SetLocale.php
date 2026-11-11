<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Locale of server-rendered text (flash and validation messages, Blade pages).
 *
 * Order: the X-Locale header the SPA sends with every Inertia request (the language picked in the
 * switcher), then the session (set by GET /lang/{locale}), then Uzbek. A valid header is also stored in
 * the session so full page loads, PDFs and redirects follow the same language. Runs after the session
 * has started, which is why this lives in middleware and not in a service provider.
 */
class SetLocale
{
    public const SUPPORTED = ['uz', 'en', 'ru'];

    public const DEFAULT = 'uz';

    public function handle(Request $request, Closure $next): Response
    {
        $header = strtolower(substr((string) $request->header('X-Locale'), 0, 2));

        if (in_array($header, self::SUPPORTED, true)) {
            if ($request->hasSession() && $request->session()->get('locale') !== $header) {
                $request->session()->put('locale', $header);
            }
            $locale = $header;
        } else {
            $session = $request->hasSession() ? $request->session()->get('locale') : null;
            $locale = in_array($session, self::SUPPORTED, true) ? $session : self::DEFAULT;
        }

        app()->setLocale($locale);

        return $next($request);
    }
}
