<?php

namespace App\Http\Middleware\Desktop;

use App\Exceptions\ApiException;
use App\Models\Device;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Resolves the exam PC from X-Device-Token (devices.token_hash = sha256 of the plain token).
 */
class AuthenticateDevice
{
    public function handle(Request $request, Closure $next): Response
    {
        $device = Device::findByToken($request->header('X-Device-Token'));

        if (! $device) {
            throw ApiException::unauthenticated('Unknown device. Register this PC again.');
        }

        if ($device->is_blocked) {
            throw new ApiException(403, 'device_blocked', 'This PC is blocked. Contact the administrator.');
        }

        $request->attributes->set('device', $device);

        return $next($request);
    }
}
