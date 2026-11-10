<?php

namespace App\Jobs;

use App\Models\TestImport;
use App\Models\TestType;
use App\Services\Import\DocumentTextExtractor;
use App\Services\Import\MockTestImporter;
use App\Services\Import\MockTestPdfParser;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use OpenAI\Exceptions\RateLimitException;
use Throwable;

/**
 * Mock Bank "Import from PDF" for ONE module (Listening or Reading) of a TestImport.
 *
 * The AI calls take minutes (Reading: one call per passage), so the job has its own long timeout.
 * The queue connection's retry_after (DB_QUEUE_RETRY_AFTER) must be larger than $timeout, otherwise
 * the database queue hands the still-running job to a second attempt — see supervisor/README.md.
 */
class ImportMockModuleJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable;

    /** Extra attempts are only used after an OpenAI 429 (tokens-per-minute limit of small accounts). */
    public int $tries = 4;

    public int $timeout = 900;

    public bool $failOnTimeout = true;

    public function __construct(public readonly int $importId, public readonly string $module) {}

    public function handle(DocumentTextExtractor $extractor, MockTestPdfParser $parser, MockTestImporter $importer): void
    {
        $import = TestImport::find($this->importId);
        if (! $import || ($import->modules[$this->module]['status'] ?? null) !== TestImport::QUEUED) {
            return;
        }

        TestImport::updateModule($import->id, $this->module, ['status' => TestImport::RUNNING, 'started_at' => now()->toIso8601String()]);

        $testType = TestType::query()
            ->where('test_id', $import->test_id)
            ->whereHas('type', fn ($q) => $q->where('name', $this->module))
            ->firstOrFail();

        $disk = Storage::disk('local');
        $files = $import->files ?? [];
        $key = strtolower($this->module);

        $text = $extractor->extract($disk->path($files[$key]));
        $answers = isset($files['answers']) ? $extractor->extract($disk->path($files['answers'])) : '';

        try {
            $result = $parser->parse($this->module, $text, $answers);
        } catch (RateLimitException $e) {
            if ($this->attempts() < $this->tries) {
                // Wait for the per-minute token window to reset, then try this module again.
                TestImport::updateModule($import->id, $this->module, [
                    'status' => TestImport::QUEUED,
                    'message' => 'OpenAI rate limit hit, retrying in a moment ('.$this->attempts().'/'.($this->tries - 1).')…',
                ]);
                $this->release(90 * $this->attempts());

                return;
            }

            throw $e;
        }
        $counts = $importer->import($testType, $result['parts'], $import->replace);

        $done = TestImport::updateModule($import->id, $this->module, [
            'status' => TestImport::DONE,
            'message' => null,
            'warnings' => $result['warnings'],
            'parts' => $counts['parts'],
            'questions' => $counts['questions'],
            'test_type_id' => $testType->id,
        ]);

        $this->cleanUp($done);
    }

    public function failed(?Throwable $e): void
    {
        Log::warning('Mock PDF import failed', ['import' => $this->importId, 'module' => $this->module, 'error' => $e?->getMessage()]);

        TestImport::updateModule($this->importId, $this->module, [
            'status' => TestImport::FAILED,
            'message' => mb_substr(self::describe($e), 0, 500),
        ]);
    }

    /**
     * OpenAI answers 429 both for rate limits and for an empty credit balance; say what to do.
     */
    public static function describe(?Throwable $e): string
    {
        if ($e instanceof RateLimitException) {
            return 'OpenAI rejected the request (429): the API credit balance is exhausted or the rate limit was hit. '
                .'Check billing at platform.openai.com, then start the import again.';
        }

        return $e?->getMessage() ?: 'The import failed.';
    }

    /**
     * Uploaded files are deleted once every module of the import succeeded
     * (after a failure they stay for a retry / inspection).
     */
    private function cleanUp(?TestImport $import): void
    {
        if ($import && $import->status === TestImport::DONE) {
            Storage::disk('local')->deleteDirectory(self::directory($import->test_id, $import->id));
        }
    }

    public static function directory(int $testId, int $importId): string
    {
        return "imports/{$testId}/{$importId}";
    }
}
