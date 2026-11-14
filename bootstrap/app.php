<?php

use App\Exceptions\ApiException;
use App\Http\Middleware\Desktop\AuthenticateCandidate;
use App\Http\Middleware\Desktop\AuthenticateDevice;
use App\Http\Middleware\Desktop\EnsureClientVersion;
use App\Http\Middleware\EnsureCenterIsActive;
use App\Http\Middleware\EnsureUserIsNotSuspended;
use App\Http\Middleware\HandleAppearance;
use App\Http\Middleware\HandleInertiaRequests;
use App\Http\Middleware\SetLocale;
use App\Support\UserFacingError;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use Illuminate\Http\Middleware\AddLinkHeadersForPreloadedAssets;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Spatie\Permission\Middleware\PermissionMiddleware;
use Spatie\Permission\Middleware\RoleMiddleware;
use Spatie\Permission\Middleware\RoleOrPermissionMiddleware;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->encryptCookies(except: ['appearance', 'sidebar_state']);

        $middleware->web(append: [
            SetLocale::class,
            EnsureUserIsNotSuspended::class,
            HandleAppearance::class,
            HandleInertiaRequests::class,
            AddLinkHeadersForPreloadedAssets::class,
        ]);

        $middleware->alias([
            'role' => RoleMiddleware::class,
            'permission' => PermissionMiddleware::class,
            'role_or_permission' => RoleOrPermissionMiddleware::class,
            'desktop.device' => AuthenticateDevice::class,
            'desktop.client' => EnsureClientVersion::class,
            'desktop.candidate' => AuthenticateCandidate::class,
            'center.active' => EnsureCenterIsActive::class,
        ]);

        // Telegram webhooks and the WebApp login (verified via initData signature) cannot carry a CSRF token.
        $middleware->validateCsrfTokens(except: [
            'bot/webhook',
            'bot/MynineUzBot/webhook',
            'webapp-login',
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        $exceptions->dontReport(ApiException::class);

        // Web: a database error that no controller caught never shows its SQL; a form action goes back with a
        // plain message (the error is still reported).
        $exceptions->render(function (QueryException $e, Request $request) {
            if ($request->is('api/*') || $request->isMethod('GET') || $request->expectsJson() && ! $request->header('X-Inertia')) {
                return null;
            }
            report($e);

            return back()->withErrors(['error' => __(UserFacingError::databaseKey($e))]);
        });

        // Web: a form action the user may not do (403) goes back with a plain message instead of an error page.
        $exceptions->render(function (Throwable $e, Request $request) {
            $forbidden = $e instanceof AuthorizationException
                || ($e instanceof HttpExceptionInterface && $e->getStatusCode() === 403);
            if (! $forbidden || $request->is('api/*') || $request->isMethod('GET') || ! $request->header('X-Inertia')) {
                return null;
            }

            return back()->with('error', __('error_forbidden'));
        });

        // Desktop API (docs/desktop/API.md): every error is { "message": "...", "code": "<machine_code>" }.
        $exceptions->render(function (Throwable $e, Request $request) {
            if (! $request->is('api/v1/*')) {
                return null;
            }

            return match (true) {
                $e instanceof HttpResponseException => null,
                $e instanceof ValidationException => response()->json([
                    'message' => $e->getMessage(),
                    'code' => 'validation_failed',
                    'errors' => $e->errors(),
                ], 422),
                $e instanceof AuthenticationException => response()->json(['message' => 'Unauthenticated.', 'code' => 'unauthenticated'], 401),
                $e instanceof ThrottleRequestsException => response()->json(
                    ['message' => 'Too many requests.', 'code' => 'too_many_requests'], 429, $e->getHeaders()
                ),
                $e instanceof HttpExceptionInterface => response()->json([
                    'message' => $e->getMessage() ?: 'Request failed.',
                    'code' => match ($e->getStatusCode()) {
                        401 => 'unauthenticated',
                        403 => 'forbidden',
                        404 => 'not_found',
                        405 => 'method_not_allowed',
                        default => 'http_error',
                    },
                ], $e->getStatusCode(), $e->getHeaders()),
                config('app.debug') => null,
                default => response()->json(['message' => 'Server error.', 'code' => 'server_error'], 500),
            };
        });
    })->create();
