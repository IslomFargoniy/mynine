<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Telegram sends the secret given to setWebhook (secret_token) in X-Telegram-Bot-Api-Secret-Token.
 * Without it anyone could post forged updates (fake /start, code lookups). When no secret is configured
 * the check is skipped so the bots keep working until the webhook is re-registered with one.
 */
class VerifyTelegramWebhook
{
    public function handle(Request $request, Closure $next): Response
    {
        $secret = (string) config('services.telegram.webhook_secret');

        if ($secret !== '' && ! hash_equals($secret, (string) $request->header('X-Telegram-Bot-Api-Secret-Token'))) {
            abort(403);
        }

        return $next($request);
    }
}
