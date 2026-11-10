<?php

namespace App\Services\Import;

use RuntimeException;

/**
 * The AI provider refused the import call for now (HTTP 429 / RESOURCE_EXHAUSTED, or it stayed
 * overloaded after the in-request retries). ImportMockModuleJob releases the module back to the
 * queue and tries again later instead of failing it.
 */
class AiRateLimitException extends RuntimeException
{
    public function __construct(string $message, public readonly string $provider = 'gemini', public readonly int $status = 429)
    {
        parent::__construct($message, $status);
    }
}
