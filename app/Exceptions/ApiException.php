<?php

namespace App\Exceptions;

use Illuminate\Http\JsonResponse;
use RuntimeException;

/**
 * Desktop API error rendered as { "message": "...", "code": "<machine_code>", ...extra }.
 */
class ApiException extends RuntimeException
{
    /**
     * @param  array<string, mixed>  $extra
     */
    public function __construct(
        public readonly int $status,
        public readonly string $errorCode,
        string $message,
        public readonly array $extra = [],
    ) {
        parent::__construct($message);
    }

    public static function unauthenticated(string $message = 'Unauthenticated.'): self
    {
        return new self(401, 'unauthenticated', $message);
    }

    public static function forbidden(string $message = 'Forbidden.'): self
    {
        return new self(403, 'forbidden', $message);
    }

    public static function notFound(string $message = 'Not found.'): self
    {
        return new self(404, 'not_found', $message);
    }

    public static function conflict(string $code, string $message, array $extra = []): self
    {
        return new self(409, $code, $message, $extra);
    }

    public static function unprocessable(string $code, string $message, array $extra = []): self
    {
        return new self(422, $code, $message, $extra);
    }

    public function render(): JsonResponse
    {
        return response()->json(
            ['message' => $this->getMessage(), 'code' => $this->errorCode] + $this->extra,
            $this->status,
        );
    }
}
