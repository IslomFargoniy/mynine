<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Models\Attempt;
use App\Models\Device;
use App\Models\TestType;
use App\Services\ExamService;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;

/**
 * Base for endpoints behind desktop.device + desktop.candidate (the attempt is already resolved).
 */
abstract class ExamApiController extends Controller
{
    public function __construct(protected readonly ExamService $exam) {}

    protected function attempt(Request $request): Attempt
    {
        return $request->attributes->get('attempt');
    }

    protected function device(Request $request): Device
    {
        return $request->attributes->get('device');
    }

    protected function graceSeconds(): int
    {
        return (int) config('desktop.answer_grace_seconds', 30);
    }

    /**
     * @return Collection<int, TestType>
     */
    protected function modules(Attempt $attempt): Collection
    {
        return $attempt->examModules();
    }

    protected function findModule(Attempt $attempt, int $typeId): TestType
    {
        $module = $this->modules($attempt)->firstWhere('type_id', $typeId);
        if (! $module) {
            throw ApiException::notFound('This module is not part of your exam.');
        }

        return $module;
    }

    protected function ensureNotFinished(Attempt $attempt): void
    {
        if ($attempt->finished_at !== null) {
            throw ApiException::conflict('attempt_finished', 'This exam has already been submitted.');
        }
    }

    protected function ensureNotPaused(Attempt $attempt): void
    {
        if ($attempt->paused_at !== null) {
            throw ApiException::conflict('paused', 'The exam is paused by the invigilator.');
        }
    }

    protected function serverTime(): string
    {
        return now()->toIso8601String();
    }
}
