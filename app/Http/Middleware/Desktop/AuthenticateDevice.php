<?php

namespace App\Http\Middleware\Desktop;

use App\Exceptions\ApiException;
use App\Models\Device;
use App\Support\CurrentCenter;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Resolves the exam PC from X-Device-Token (devices.token_hash = sha256 of the plain token) and makes its
 * center the current center of the request: every query after this (candidates, attempts, mocks) is limited
 * to that center. A PC without a center sees nothing (CurrentCenter::NONE).
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
        $request->attributes->set(CurrentCenter::REQUEST_ATTRIBUTE, (int) ($device->owner_id ?? CurrentCenter::NONE));

        return $next($request);
    }
}
