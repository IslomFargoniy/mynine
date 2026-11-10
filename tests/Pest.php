<?php

use App\Models\Device;
use App\Models\Folder;
use App\Models\Mock;
use App\Models\MockModule;
use App\Models\MockStudent;
use App\Models\Option;
use App\Models\Part;
use App\Models\Question;
use App\Models\QuestionType;
use App\Models\Section;
use App\Models\Test as ExamTest;
use App\Models\TestType;
use App\Models\Type;
use App\Models\User\User;
use App\Services\Desktop\ReleaseManifest;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

pest()->extend(TestCase::class)
    ->use(RefreshDatabase::class)
    ->in('Feature');

pest()->extend(TestCase::class)->in('Unit');

/*
|--------------------------------------------------------------------------
| Helpers
|--------------------------------------------------------------------------
*/

function seedRoles(): void
{
    foreach (['Admin', 'Reception', 'Student'] as $role) {
        Role::findOrCreate($role);
    }
}

function makeUser(string $role): User
{
    seedRoles();
    $user = User::factory()->create();
    $user->assignRole($role);

    return $user;
}

function makeType(string $name, int $minute = 60): Type
{
    return Type::firstOrCreate(['name' => $name], ['minute' => $minute]);
}

function makeQuestionType(string $type, string $input = 'text'): QuestionType
{
    return QuestionType::firstOrCreate(['type' => $type], ['name' => ucfirst($type), 'input_type' => $input]);
}

/**
 * Folder -> Test -> TestType -> Part owned by the given teacher.
 *
 * @return array{folder: Folder, test: ExamTest, testType: TestType, part: Part}
 */
function makeTestContent(User $owner, string $typeName = 'Reading', array $testAttributes = []): array
{
    $folder = Folder::create(['name' => 'Folder', 'user_id' => $owner->id, 'active' => 1]);
    $test = ExamTest::create(array_merge(['folder_id' => $folder->id, 'name' => 'Test', 'active' => 1, 'open' => 1], $testAttributes));
    $testType = TestType::create(['test_id' => $test->id, 'type_id' => makeType($typeName)->id]);
    $part = Part::create(['test_type_id' => $testType->id, 'name' => 'Part 1', 'minute' => 20]);

    return compact('folder', 'test', 'testType', 'part');
}

function makeSection(Part $part, string $questionType, string $textarea = 'Section'): Section
{
    return Section::create([
        'part_id' => $part->id,
        'question_type_id' => makeQuestionType($questionType)->id,
        'textarea' => $textarea,
    ]);
}

/*
|--------------------------------------------------------------------------
| Desktop exam helpers
|--------------------------------------------------------------------------
*/

/**
 * Mock Bank content (Listening, Reading, Writing modules from three different tests) and a
 * desktop-only mock with one candidate.
 *
 * @return array<string, mixed>
 */
function makeDesktopExam(User $owner, array $mockOverrides = [], string $code = 'MOCK-100001'): array
{
    $listeningType = makeType('Listening', 30);
    $readingType = makeType('Reading', 60);
    $writingType = makeType('Writing', 60);

    $folder = Folder::create(['name' => 'Bank', 'user_id' => $owner->id, 'active' => 1]);
    $bankTest = fn (string $name) => ExamTest::create([
        'folder_id' => $folder->id, 'name' => $name, 'active' => 1, 'open' => 0,
        'purpose' => ExamTest::PURPOSE_MOCK, 'bank_status' => ExamTest::BANK_READY,
    ]);

    // Listening: one multiple choice question + one fill-in-the-blank question
    $testL = $bankTest('Bank L');
    $listening = TestType::create(['test_id' => $testL->id, 'type_id' => $listeningType->id]);
    $partL = Part::create(['test_type_id' => $listening->id, 'name' => 'Part 1', 'minute' => 30]);
    $mc = makeSection($partL, 'multiple_choice', '<p>Choose</p>');
    $mcQuestion = Question::create(['section_id' => $mc->id, 'order' => 1, 'textarea' => 'Q1?']);
    $correctOption = Option::create(['question_id' => $mcQuestion->id, 'textarea' => 'A', 'is_correct' => 1]);
    $wrongOption = Option::create(['question_id' => $mcQuestion->id, 'textarea' => 'B', 'is_correct' => 0]);
    $fill = makeSection($partL, 'fill_blank', '<p>Write one word</p>');
    $fillQuestion = Question::create(['section_id' => $fill->id, 'order' => 2, 'textarea' => 'Gas: ___', 'answer_text' => 'carbon']);

    // Reading: drag-and-drop + matching
    $testR = $bankTest('Bank R');
    $reading = TestType::create(['test_id' => $testR->id, 'type_id' => $readingType->id]);
    $partR = Part::create(['test_type_id' => $reading->id, 'name' => 'Passage 1', 'minute' => 60, 'textarea' => '<p>Passage <img src="/storage/images/p1.png"></p>']);
    $drag = makeSection($partR, 'drag_and_drop', 'The {cave} was {dark}.');
    $dragQ1 = Question::create(['section_id' => $drag->id, 'order' => 1, 'answer_text' => 'cave']);
    $dragQ2 = Question::create(['section_id' => $drag->id, 'order' => 2, 'answer_text' => 'dark']);
    Option::create(['section_id' => $drag->id, 'textarea' => 'bright', 'is_correct' => 0]);

    // Writing: essay
    $testW = $bankTest('Bank W');
    $writing = TestType::create(['test_id' => $testW->id, 'type_id' => $writingType->id]);
    $partW = Part::create(['test_type_id' => $writing->id, 'name' => 'Task 1', 'minute' => 60]);
    $essay = makeSection($partW, 'essay', 'Write about...');
    $essayQuestion = Question::create(['section_id' => $essay->id, 'order' => 1, 'answer_text' => 'model essay']);

    $mock = Mock::create(array_merge([
        'name' => 'Mock 12.11', 'test_id' => null, 'user_id' => $owner->id, 'slug' => 'mock-'.uniqid(),
        'started_at' => now()->subHour(), 'finished_at' => now()->addHours(4), 'active' => 1, 'require_desktop' => true,
    ], $mockOverrides));

    foreach ([$listening, $reading, $writing] as $module) {
        MockModule::create(['mock_id' => $mock->id, 'type_id' => $module->type_id, 'test_type_id' => $module->id]);
    }

    $student = MockStudent::create(['mock_id' => $mock->id, 'name' => 'Ali Valiyev', 'code' => $code, 'phone' => '+998901234567']);

    return compact(
        'listeningType', 'readingType', 'writingType', 'testL', 'testR', 'testW',
        'listening', 'reading', 'writing', 'partL', 'partR', 'partW',
        'mcQuestion', 'correctOption', 'wrongOption', 'fillQuestion', 'dragQ1', 'dragQ2', 'essayQuestion',
        'mock', 'student',
    );
}

/**
 * @return array<string, string>
 */
function desktopHeaders(?string $deviceToken = null, ?string $examToken = null, string $version = '1.0.0'): array
{
    return array_filter([
        'Accept' => 'application/json',
        'X-Mynine-Client' => 'desktop/'.$version,
        'X-Device-Token' => $deviceToken,
        'Authorization' => $examToken ? 'Bearer '.$examToken : null,
    ]);
}

/**
 * Desktop API request; forgets resolved guards so each call authenticates from its own headers.
 */
function desktopApi(string $method, string $uri, array $data = [], ?string $deviceToken = null, ?string $examToken = null, string $version = '1.0.0'): TestResponse
{
    app('auth')->forgetGuards();

    return test()->json($method, '/api/v1/'.ltrim($uri, '/'), $data, desktopHeaders($deviceToken, $examToken, $version));
}

function registerDesktopDevice(string $machineId = 'MACHINE-1', string $name = 'PC-01', bool $approve = true): string
{
    $token = desktopApi('POST', 'device/register', [
        'machine_id' => $machineId, 'name' => $name, 'os_version' => 'Windows 11 23H2', 'app_version' => '1.0.0',
    ])->assertOk()->json('device_token');

    if ($approve) {
        Device::where('machine_id', $machineId)->firstOrFail()->approve();
    }

    return $token;
}

function desktopLogin(string $deviceToken, string $code): string
{
    return desktopApi('POST', 'exam/login', ['code' => $code], $deviceToken)->assertOk()->json('token');
}

/**
 * Fails when any answer-key field appears anywhere in the payload.
 */
function assertNoAnswerKeys(mixed $payload, string $path = '$'): void
{
    if (! is_array($payload)) {
        return;
    }

    foreach ($payload as $key => $value) {
        expect(in_array($key, ['is_correct', 'answer_text', 'score', 'review_note', 'review_note_ai'], true))
            ->toBeFalse("Answer key '{$key}' leaked at {$path}");
        assertNoAnswerKeys($value, $path.'.'.$key);
    }
}

function binaryContent(TestResponse $response): string
{
    ob_start();
    $response->baseResponse->sendContent();

    return (string) ob_get_clean();
}

/**
 * Points ReleaseManifest at a temporary version.json (array → JSON, string → raw content, null → missing file).
 */
function useReleaseManifest(array|string|null $manifest): string
{
    $path = sys_get_temp_dir().'/mynine-version-'.uniqid('', true).'.json';
    if ($manifest !== null) {
        file_put_contents($path, is_array($manifest) ? json_encode($manifest) : $manifest);
    }
    app()->instance(ReleaseManifest::class, new ReleaseManifest($path));

    return $path;
}

function releaseManifestData(array $overrides = []): array
{
    return array_merge([
        'version' => '1.2.0',
        'file' => 'mynine-setup-1.2.0.exe',
        'sha256' => str_repeat('ab', 32),
        'size' => 1024,
        'mandatory' => false,
        'min_version' => null,
        'notes' => 'Fixes',
        'published_at' => '2026-11-10T00:00:00+05:00',
    ], $overrides);
}
