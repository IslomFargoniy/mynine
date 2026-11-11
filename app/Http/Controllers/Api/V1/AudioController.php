<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\ApiException;
use App\Models\Part;
use App\Models\Test;
use App\Services\AudioUploadService;
use App\Services\ExamService;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AudioController extends ExamApiController
{
    public function __construct(ExamService $exam, private readonly AudioUploadService $audio)
    {
        parent::__construct($exam);
    }

    /**
     * GET /exam/audio/test/{test} — the Listening recording of a module in this attempt.
     */
    public function test(Request $request, int $test): Response
    {
        $module = $this->modules($this->attempt($request))
            ->first(fn ($testType) => (int) $testType->test_id === $test && $testType->type?->name === 'Listening');

        if (! $module) {
            throw ApiException::forbidden('This audio is not part of your exam.');
        }

        return $this->stream(Test::whereKey($test)->value('audio_path'));
    }

    /**
     * GET /exam/audio/part/{part}
     */
    public function part(Request $request, int $part): Response
    {
        $model = Part::withoutEagerLoads()->find($part, ['id', 'test_type_id', 'audio_path']);
        $moduleIds = $this->modules($this->attempt($request))->pluck('id')->map(fn ($id) => (int) $id)->all();

        if (! $model || ! in_array((int) $model->test_type_id, $moduleIds, true)) {
            throw ApiException::forbidden('This audio is not part of your exam.');
        }

        return $this->stream($model->audio_path);
    }

    private function stream(?string $storedPath): Response
    {
        $path = $this->audio->absolutePath($storedPath);
        if (! $path) {
            throw ApiException::notFound('Audio file not found.');
        }

        // PHP (BinaryFileResponse) or nginx (X-Accel-Redirect) answer Range requests with 206 Partial Content.
        return $this->audio->response($path);
    }
}
