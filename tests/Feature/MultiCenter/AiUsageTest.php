<?php

use App\Jobs\EvaluateEssayJob;
use App\Jobs\ImportMockModuleJob;
use App\Models\AiUsageLog;
use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\AttemptPart;
use App\Models\AttemptType;
use App\Models\Question;
use App\Models\Test as ExamTest;
use App\Models\TestImport;
use App\Models\TestType;
use App\Models\User\User;
use App\Services\GeminiService;
use App\Services\OpenAIService;
use App\Support\AiUsage;
use GuzzleHttp\Client as GuzzleClient;
use GuzzleHttp\Handler\MockHandler;
use GuzzleHttp\HandlerStack;
use GuzzleHttp\Psr7\Response as Psr7Response;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;

/**
 * OpenAIService whose HTTP calls get these chat completion responses (real client, faked transport).
 *
 * @param  array<int, array<string, mixed>>  $usages
 */
function openAiWithResponses(array $usages, string $model = 'gpt-4o-mini-2024-07-18', string $content = '{"overall": 7, "scores": {}, "feedback": "ok"}'): OpenAIService
{
    $responses = array_map(fn (array $usage) => new Psr7Response(200, ['Content-Type' => 'application/json'], json_encode([
        'id' => 'chatcmpl-1',
        'object' => 'chat.completion',
        'created' => time(),
        'model' => $model,
        'choices' => [['index' => 0, 'message' => ['role' => 'assistant', 'content' => $content], 'finish_reason' => 'stop']],
        'usage' => $usage,
    ])), $usages);

    $client = OpenAI::factory()
        ->withApiKey('test-key')
        ->withHttpClient(new GuzzleClient(['handler' => HandlerStack::create(new MockHandler($responses))]))
        ->make();

    return (new OpenAIService)->usingClient($client);
}

/**
 * A Writing answer of a mock candidate of $center (or a practice answer when $center is null).
 */
function writingAnswer(?User $center): AttemptAnswer
{
    if ($center) {
        $exam = makeDesktopExam($center, [], 'W-'.uniqid());
        $attempt = Attempt::create(['name' => 'Cand', 'mock_id' => $exam['mock']->id, 'mock_student_id' => $exam['student']->id, 'test_id' => $exam['testW']->id, 'started_at' => now()]);
        $part = $exam['partW'];
        $question = $exam['essayQuestion'];
    } else {
        $admin = makeSuperAdmin();
        $student = makeUser('Student');
        ['test' => $test, 'testType' => $testType, 'part' => $part] = makeTestContent($admin, 'Writing');
        $question = Question::create(['section_id' => makeSection($part, 'essay', 'Write')->id, 'textarea' => 'Task']);
        $attempt = Attempt::create(['user_id' => $student->id, 'test_id' => $test->id, 'started_at' => now()]);
        AttemptType::create(['attempt_id' => $attempt->id, 'type_id' => $testType->type_id, 'started_at' => now(), 'finished_at' => now()->addHour()]);
    }

    $attemptPart = AttemptPart::create(['attempt_id' => $attempt->id, 'part_id' => $part->id, 'started_at' => now()]);

    return AttemptAnswer::create(['attempt_part_id' => $attemptPart->id, 'question_id' => $question->id, 'answer_text' => str_repeat('word ', 80)]);
}

test('a Writing evaluation of a mock candidate is logged for the mock center with the OpenAI token counts and cost', function () {
    defaultCenter();
    $center = makeCenter('ALPHA');
    $answer = writingAnswer($center);

    app()->instance(OpenAIService::class, openAiWithResponses([['prompt_tokens' => 1200, 'completion_tokens' => 300, 'total_tokens' => 1500]]));
    (new EvaluateEssayJob($answer->id))->handle();

    expect((float) $answer->fresh()->score)->toBe(7.0);

    $log = AiUsageLog::sole();
    expect($log->only(['owner_id', 'provider', 'model', 'purpose', 'input_tokens', 'output_tokens', 'attempt_answer_id', 'test_import_id']))->toBe([
        'owner_id' => $center->id,
        'provider' => 'openai',
        'model' => 'gpt-4o-mini-2024-07-18',
        'purpose' => 'writing_eval',
        'input_tokens' => 1200,
        'output_tokens' => 300,
        'attempt_answer_id' => $answer->id,
        'test_import_id' => null,
    ])
        // gpt-4o-mini: $0.15 / 1M input, $0.60 / 1M output
        ->and((float) $log->estimated_cost_usd)->toBe(round((1200 * 0.15 + 300 * 0.60) / 1_000_000, 6));
});

test('a practice Writing evaluation is logged without a center (Mynine practice)', function () {
    $answer = writingAnswer(null);

    app()->instance(OpenAIService::class, openAiWithResponses([['prompt_tokens' => 10, 'completion_tokens' => 5, 'total_tokens' => 15]]));
    (new EvaluateEssayJob($answer->id))->handle();

    expect(AiUsageLog::sole()->only(['owner_id', 'purpose', 'attempt_answer_id']))
        ->toBe(['owner_id' => null, 'purpose' => 'writing_eval', 'attempt_answer_id' => $answer->id]);
});

test('an unknown model gets no cost; prices match by the longest model prefix', function () {
    expect(AiUsage::estimateCost('some-new-model', 1000, 1000))->toBeNull()
        ->and(AiUsage::price('gpt-4o-mini-2024-07-18'))->toBe(config('ai_pricing.models.gpt-4o-mini'))
        ->and(AiUsage::price('gpt-4o-2024-08-06'))->toBe(config('ai_pricing.models.gpt-4o'))
        ->and(AiUsage::price('models/gemini-2.5-flash'))->toBe(config('ai_pricing.models')['gemini-2.5-flash']);

    app(AiUsage::class)->record('openai', 'some-new-model', 10, 10);
    expect(AiUsageLog::sole()->estimated_cost_usd)->toBeNull()
        ->and(AiUsageLog::sole()->purpose)->toBe('other');
});

test('a Gemini PDF import is logged for the center of the imported test with input, output and thinking tokens', function () {
    defaultCenter();
    $center = makeCenter('BETA');
    config([
        'services.mock_import.provider' => 'gemini',
        'services.gemini.key' => 'test-gemini-key',
        'services.gemini.import_model' => 'gemini-2.5-flash',
    ]);

    $test = ExamTest::forceCreate(['folder_id' => null, 'name' => 'Bank', 'purpose' => 'mock', 'open' => 0, 'owner_id' => $center->id]);
    TestType::create(['test_id' => $test->id, 'type_id' => makeType('Listening')->id]);
    $import = TestImport::create(['owner_id' => $center->id, 'test_id' => $test->id, 'user_id' => $center->id, 'status' => TestImport::QUEUED, 'modules' => ['Listening' => ['status' => 'queued']]]);
    $dir = ImportMockModuleJob::directory($test->id, $import->id);
    Storage::disk('local')->put("{$dir}/listening.pdf", "%PDF-1.4\npaper\n%%EOF");
    $import->forceFill(['files' => ['listening' => "{$dir}/listening.pdf"]])->save();

    Http::fake(['generativelanguage.googleapis.com/*' => Http::response([
        'candidates' => [['content' => ['role' => 'model', 'parts' => [['text' => json_encode(['answers' => [], 'parts' => []])]]], 'finishReason' => 'STOP']],
        'usageMetadata' => ['promptTokenCount' => 50000, 'candidatesTokenCount' => 8000, 'thoughtsTokenCount' => 2000, 'totalTokenCount' => 60000],
        'modelVersion' => 'gemini-2.5-flash',
    ])]);

    try {
        app()->call([new ImportMockModuleJob($import->id, 'Listening'), 'handle']);
    } catch (Throwable) {
        // An empty paper fails the import; the billed calls are still logged.
    }

    $logs = AiUsageLog::all();
    expect($logs)->not->toBeEmpty()
        ->and($logs->count())->toBe(count(Http::recorded()));

    $log = $logs->first();
    expect($log->only(['owner_id', 'user_id', 'provider', 'model', 'purpose', 'input_tokens', 'output_tokens', 'test_import_id', 'attempt_answer_id']))->toBe([
        'owner_id' => $center->id,
        'user_id' => $center->id,
        'provider' => 'gemini',
        'model' => 'gemini-2.5-flash',
        'purpose' => 'pdf_import',
        'input_tokens' => 50000,
        'output_tokens' => 10000,
        'test_import_id' => $import->id,
        'attempt_answer_id' => null,
    ])
        ->and((float) $log->estimated_cost_usd)->toBe(round((50000 * 0.30 + 10000 * 2.50) / 1_000_000, 6));
});

test('a failed Gemini request is not logged', function () {
    config(['services.gemini.key' => 'k']);
    Http::fake(['generativelanguage.googleapis.com/*' => Http::response(['error' => ['message' => 'bad', 'status' => 'INVALID_ARGUMENT']], 400)]);

    expect(fn () => app(GeminiService::class)->generateJson([['text' => 'x']]))->toThrow(RuntimeException::class);
    expect(AiUsageLog::count())->toBe(0);
});
