<?php

namespace App\Http\Middleware\Desktop;

use App\Exceptions\ApiException;
use App\Models\AppRelease;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Rejects exam requests from desktop clients older than the newest active mandatory release (426).
 */
class EnsureClientVersion
{
    public function handle(Request $request, Closure $next): Response
    {
        $minVersion = AppRelease::minVersion();
        if ($minVersion === null) {
            return $next($request);
        }

        $clientVersion = self::clientVersion($request);

        if ($clientVersion === null || version_compare($clientVersion, $minVersion, '<')) {
            throw new ApiException(426, 'client_outdated', 'Please update the Mynine desktop app.', [
                'min_version' => $minVersion,
            ]);
        }

        return $next($request);
    }

    /**
     * Version from "X-Mynine-Client: desktop/1.2.0", or null when missing/malformed.
     */
    public static function clientVersion(Request $request): ?string
    {
        $header = (string) $request->header('X-Mynine-Client', '');

        if (preg_match('#^desktop/(\d+\.\d+\.\d+)$#', trim($header), $m) !== 1) {
            return null;
        }

        return $m[1];
    }
}
