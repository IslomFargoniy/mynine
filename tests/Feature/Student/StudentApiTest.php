<?php

use App\Models\Attempt;
use App\Models\Option;
use App\Models\Part;
use App\Models\Question;
use App\Models\Test as ExamTest;
use App\Models\TestType;
use App\Models\User\User;
use App\Services\Student\AppLoginCodes;
use Illuminate\Support\Facades\Http;
use Illuminate\Testing\TestResponse;

/**
 * Mobile student API (/api/v1/student): sign-in, Test Bank, a whole practice attempt through the shared exam
 * controllers, result review, ownership, staff and Mock Bank isolation.
 */
function studentApi(string $method, string $uri, array $data = [], ?string $token = null): TestResponse
{
    app('auth')->forgetGuards();

    return test()->json($method, '/api/v1/student/'.ltrim($uri, '/'), $data, array_filter([
        'Accept' => 'application/json',
        'X-Platform' => 'android',
        'Authorization' => $token ? 'Bearer '.$token : null,
    ]));
}

function studentToken(User $user): string
{
    return $user->createToken('app:test', ['student'])->plainTextToken;
}

beforeEach(function () {
    $this->owner = makeUser('SuperAdmin');
    $this->student = makeUser('Student');
    $this->token = studentToken($this->student);

    // Practice test: Listening (multiple choice + gap) and Reading (gap) modules.
    ['test' => $this->test, 'testType' => $this->reading, 'part' => $this->readingPart] = makeTestContent($this->owner, 'Reading');
    $gap = makeSection($this->readingPart, 'fill_blank', '<p>One word</p>');
    $this->readingQuestion = Question::create(['section_id' => $gap->id, 'order' => 1, 'textarea' => 'Gas: ___', 'answer_text' => 'carbon']);

    $this->listening = TestType::create(['test_id' => $this->test->id, 'type_id' => makeType('Listening', 30)->id]);
    $this->listeningPart = Part::create(['test_type_id' => $this->listening->id, 'name' => 'Part 1', 'minute' => 30]);
    $mc = makeSection($this->listeningPart, 'multiple_choice', '<p>Choose</p>');
    $this->mcQuestion = Question::create(['section_id' => $mc->id, 'order' => 1, 'textarea' => 'Q1?']);
    $this->right = Option::create(['question_id' => $this->mcQuestion->id, 'textarea' => '<p>Right</p>', 'is_correct' => 1]);
    $this->wrong = Option::create(['question_id' => $this->mcQuestion->id, 'textarea' => '<p>Wrong</p>', 'is_correct' => 0]);
});

test('the bot code signs in once and returns a student token', function () {
    $code = app(AppLoginCodes::class)->issue($this->student);

    $response = studentApi('POST', 'auth/telegram', ['code' => $code])->assertOk()
        ->assertJsonPath('user.id', $this->student->id);
    $token = $response->json('token');

    studentApi('GET', 'me', [], $token)->assertOk()->assertJsonPath('user.name', $this->student->name);
    studentApi('POST', 'auth/telegram', ['code' => $code])->assertStatus(422)->assertJsonPath('code', 'invalid_code');
});

test('a new bot code replaces the previous one', function () {
    $codes = app(AppLoginCodes::class);
    $first = $codes->issue($this->student);
    $second = $codes->issue($this->student);

    studentApi('POST', 'auth/telegram', ['code' => $first])->assertStatus(422);
    studentApi('POST', 'auth/telegram', ['code' => $second])->assertOk();
});

test('password sign-in works with email or username and rejects wrong passwords', function () {
    $this->student->forceFill(['password' => 'secret-pass', 'username' => 'aziza'])->save();

    studentApi('POST', 'auth/password', ['login' => $this->student->email, 'password' => 'secret-pass'])->assertOk();
    studentApi('POST', 'auth/password', ['login' => 'aziza', 'password' => 'secret-pass'])->assertOk();
    studentApi('POST', 'auth/password', ['login' => 'aziza', 'password' => 'nope'])->assertStatus(422)
        ->assertJsonPath('code', 'invalid_credentials');
});

test('staff accounts cannot sign in to the app and their tokens are refused', function () {
    $reception = makeUser('Reception');
    $reception->forceFill(['password' => 'secret-pass'])->save();

    studentApi('POST', 'auth/password', ['login' => $reception->email, 'password' => 'secret-pass'])->assertForbidden()
        ->assertJsonPath('code', 'staff_account');
    studentApi('GET', 'me', [], studentToken($reception))->assertForbidden();
    studentApi('POST', 'auth/telegram', ['code' => app(AppLoginCodes::class)->issue($this->owner)])->assertForbidden();
});

test('tokens without the student ability (e.g. desktop exam tokens) are refused', function () {
    $token = $this->student->createToken('other', ['exam'])->plainTextToken;
    studentApi('GET', 'me', [], $token)->assertUnauthorized();
    studentApi('GET', 'me')->assertUnauthorized();
});

test('google sign-in creates a student for a verified id_token of an allowed client', function () {
    config(['mobile.google_client_ids' => ['android-client']]);
    Http::fake(['oauth2.googleapis.com/*' => Http::response([
        'aud' => 'android-client', 'iss' => 'https://accounts.google.com', 'exp' => time() + 600,
        'sub' => 'g-123', 'email' => 'new.student@example.com', 'email_verified' => 'true', 'name' => 'New Student',
    ])]);

    studentApi('POST', 'auth/google', ['id_token' => 'x'])->assertOk()->assertJsonPath('user.google_connected', true);
    $user = User::where('email', 'new.student@example.com')->firstOrFail();
    expect($user->hasRole('Student'))->toBeTrue()->and($user->google_id)->toBe('g-123');

    config(['mobile.google_client_ids' => ['another-client']]);
    studentApi('POST', 'auth/google', ['id_token' => 'x'])->assertStatus(422);
});

test('the reviewer code signs in to the configured account only when set', function () {
    studentApi('POST', 'auth/telegram', ['code' => '159123'])->assertStatus(422);

    config(['mobile.reviewer_code' => '159123', 'mobile.reviewer_email' => $this->student->email]);
    studentApi('POST', 'auth/telegram', ['code' => '159123'])->assertOk()->assertJsonPath('user.id', $this->student->id);
});

test('the test bank lists open practice tests with their modules and hides mock bank and closed tests', function () {
    ExamTest::forceCreate(['folder_id' => null, 'name' => 'Bank', 'active' => 1, 'open' => 0, 'purpose' => ExamTest::PURPOSE_MOCK]);
    ['test' => $closed] = makeTestContent($this->owner, 'Reading', ['open' => 0, 'name' => 'Closed']);

    $data = studentApi('GET', 'tests', [], $this->token)->assertOk()->json('data');
    expect(collect($data)->pluck('id')->all())->toBe([$this->test->id])
        ->and(collect($data[0]['modules'])->pluck('type')->all())->toBe(['listening', 'reading'])
        ->and($data[0]['modules'][1]['questions_count'])->toBe(1);

    expect(studentApi('GET', 'tests?module=listening', [], $this->token)->json('data'))->toHaveCount(1);
    expect(studentApi('GET', 'tests?module=writing', [], $this->token)->json('data'))->toHaveCount(0);
    expect(studentApi('GET', 'tests?full=1', [], $this->token)->json('data'))->toHaveCount(0);

    // With Writing too the test is a full test.
    $writing = TestType::create(['test_id' => $this->test->id, 'type_id' => makeType('Writing', 60)->id]);
    Part::create(['test_type_id' => $writing->id, 'name' => 'Task 1', 'minute' => 20]);
    expect(collect(studentApi('GET', 'tests?full=1', [], $this->token)->json('data'))->pluck('id')->all())->toBe([$this->test->id]);
    studentApi('GET', 'tests/'.$closed->id, [], $this->token)->assertNotFound();
});

test('a whole practice attempt: modules in order, answers, submit, result review', function () {
    $attempt = studentApi('POST', 'attempts', ['test_id' => $this->test->id], $this->token)->assertCreated()->json('attempt');
    expect(collect($attempt['modules'])->pluck('type')->all())->toBe(['listening', 'reading']);
    $id = $attempt['id'];
    $listeningTypeId = $attempt['modules'][0]['type_id'];
    $readingTypeId = $attempt['modules'][1]['type_id'];

    // Reading is locked until Listening is submitted.
    studentApi('POST', "attempts/{$id}/modules/{$readingTypeId}/start", [], $this->token)->assertStatus(409)
        ->assertJsonPath('code', 'module_locked');
    studentApi('POST', "attempts/{$id}/modules/{$listeningTypeId}/start", [], $this->token)->assertOk()
        ->assertJsonPath('status', 'in_progress');

    $part = studentApi('GET', "attempts/{$id}/parts/{$this->listeningPart->id}", [], $this->token)->assertOk()->json();
    expect(json_encode($part))->not->toContain('is_correct')->not->toContain('carbon');
    expect($part['sections'][0]['questions'][0]['options'])->toHaveCount(2);

    studentApi('POST', "attempts/{$id}/answers", ['answers' => [[
        'client_uuid' => 'u1', 'part_id' => $this->listeningPart->id, 'question_id' => $this->mcQuestion->id,
        'option_ids' => [$this->right->id], 'changed_at' => now()->toIso8601String(), 'seq' => 1,
    ]]], $this->token)->assertOk()->assertJsonPath('results.0.status', 'saved');

    studentApi('POST', "attempts/{$id}/modules/{$listeningTypeId}/submit", [], $this->token)->assertOk();
    studentApi('POST', "attempts/{$id}/modules/{$readingTypeId}/start", [], $this->token)->assertOk();
    studentApi('POST', "attempts/{$id}/answers", ['answers' => [[
        'client_uuid' => 'u2', 'part_id' => $this->readingPart->id, 'question_id' => $this->readingQuestion->id,
        'text' => 'oxygen', 'changed_at' => now()->toIso8601String(), 'seq' => 1,
    ]]], $this->token)->assertOk()->assertJsonPath('results.0.status', 'saved');

    studentApi('GET', "attempts/{$id}/result", [], $this->token)->assertStatus(409)->assertJsonPath('code', 'not_finished');
    studentApi('POST', "attempts/{$id}/submit", [], $this->token)->assertOk()->assertJsonPath('attempt.status', 'completed');

    $result = studentApi('GET', "attempts/{$id}/result", [], $this->token)->assertOk()->json();
    $listening = collect($result['modules'])->firstWhere('type', 'listening');
    $reading = collect($result['modules'])->firstWhere('type', 'reading');
    expect($listening['questions'][0])->toMatchArray(['your_answer' => 'Right', 'correct_answer' => 'Right', 'is_correct' => true])
        ->and($reading['questions'][0])->toMatchArray(['your_answer' => 'oxygen', 'correct_answer' => 'carbon', 'is_correct' => false])
        ->and($result['bands']['listening_correct'])->toBe(1);

    $history = studentApi('GET', 'attempts', [], $this->token)->assertOk()->json('data');
    expect($history[0]['id'])->toBe($id)->and($history[0]['status'])->toBe('completed');
});

test('starting the same test again resumes the running attempt; another test finishes it', function () {
    $first = studentApi('POST', 'attempts', ['test_id' => $this->test->id], $this->token)->json('attempt.id');
    studentApi('POST', 'attempts', ['test_id' => $this->test->id], $this->token)->assertOk()
        ->assertJsonPath('resumed', true)->assertJsonPath('attempt.id', $first);

    ['test' => $other] = makeTestContent($this->owner, 'Reading', ['name' => 'Other']);
    studentApi('POST', 'attempts', ['test_id' => $other->id], $this->token)->assertCreated();
    expect(Attempt::find($first)->finished_at)->not->toBeNull();
});

test('module practice opens only that module', function () {
    $attempt = studentApi('POST', 'attempts', ['test_id' => $this->test->id, 'module' => 'reading'], $this->token)
        ->assertCreated()->json('attempt');
    expect(collect($attempt['modules'])->pluck('type')->all())->toBe(['reading']);
    studentApi('GET', "attempts/{$attempt['id']}/parts/{$this->listeningPart->id}", [], $this->token)->assertForbidden();
});

test('another student\'s attempt, a mock attempt and mock bank tests are out of reach', function () {
    $id = studentApi('POST', 'attempts', ['test_id' => $this->test->id], $this->token)->json('attempt.id');
    $other = studentToken(makeUser('Student'));

    studentApi('GET', "attempts/{$id}", [], $other)->assertNotFound();
    studentApi('POST', "attempts/{$id}/submit", [], $other)->assertNotFound();
    expect(studentApi('GET', 'attempts', [], $other)->json('data'))->toBe([]);

    $exam = makeDesktopExam(defaultCenter());
    studentApi('POST', 'attempts', ['test_id' => $exam['testL']->id], $this->token)->assertForbidden();

    $mockAttempt = Attempt::create(['user_id' => $this->student->id, 'mock_id' => $exam['mock']->id, 'test_id' => $exam['testL']->id, 'started_at' => now()]);
    studentApi('GET', "attempts/{$mockAttempt->id}", [], $this->token)->assertNotFound();
});

test('deleting the account removes the user and its tokens', function () {
    studentApi('DELETE', 'me', [], $this->token)->assertOk();
    expect(User::find($this->student->id))->toBeNull();
    studentApi('GET', 'me', [], $this->token)->assertUnauthorized();
});

test('the version endpoint is public', function () {
    studentApi('GET', 'app/version?platform=ios')->assertOk()->assertJsonPath('platform', 'ios')
        ->assertJsonStructure(['latest', 'min_supported', 'store_url']);
});

test('the privacy policy page is public', function () {
    $this->get('/privacy')->assertOk()->assertSee('Maxfiylik siyosati')->assertSee('Hisobni o');
});

test('listening audio started late extends the module by the reported lag (once, as a total)', function () {
    $attempt = studentApi('POST', 'attempts', ['test_id' => $this->test->id], $this->token)->json('attempt');
    $typeId = $attempt['modules'][0]['type_id'];
    $timer = studentApi('POST', "attempts/{$attempt['id']}/modules/{$typeId}/start", [], $this->token)->json();

    $after = studentApi('POST', "attempts/{$attempt['id']}/modules/{$typeId}/audio-lag", ['lag_seconds' => 6], $this->token)
        ->assertOk()->assertJsonPath('audio_lag_seconds', 6)->json();
    expect(Carbon\Carbon::parse($after['finished_at'])->diffInSeconds(Carbon\Carbon::parse($timer['finished_at']), true))->toEqual(6.0);

    studentApi('POST', "attempts/{$attempt['id']}/modules/{$typeId}/audio-lag", ['lag_seconds' => 6], $this->token)
        ->assertOk()->assertJsonPath('finished_at', $after['finished_at']);
});

test('the account deletion instructions page is public', function () {
    $this->get('/delete-account')->assertOk()->assertSee('Hisobni o');
});

test('the app can practise two of the three modules together; all of them is the full test', function () {
    $writing = TestType::create(['test_id' => $this->test->id, 'type_id' => makeType('Writing', 60)->id]);
    Part::create(['test_type_id' => $writing->id, 'name' => 'Task 1', 'minute' => 20]);

    $attempt = studentApi('POST', 'attempts', ['test_id' => $this->test->id, 'module' => 'reading,listening'], $this->token)
        ->assertCreated()->assertJsonPath('attempt.module', 'listening,reading')->json('attempt');
    expect(collect($attempt['modules'])->pluck('type')->all())->toBe(['listening', 'reading']);
    $id = $attempt['id'];

    // Writing is not part of it.
    studentApi('GET', "attempts/{$id}/parts/{$writing->parts()->first()->id}", [], $this->token)->assertForbidden();

    // The attempt ends with its last chosen module, and has no overall band.
    studentApi('POST', "attempts/{$id}/modules/{$attempt['modules'][0]['type_id']}/start", [], $this->token)->assertOk();
    studentApi('POST', "attempts/{$id}/modules/{$attempt['modules'][0]['type_id']}/submit", [], $this->token)->assertOk();
    expect(Attempt::find($id)->finished_at)->toBeNull();
    studentApi('POST', "attempts/{$id}/modules/{$attempt['modules'][1]['type_id']}/start", [], $this->token)->assertOk();
    studentApi('POST', "attempts/{$id}/modules/{$attempt['modules'][1]['type_id']}/submit", [], $this->token)->assertOk();
    expect(Attempt::find($id)->finished_at)->not->toBeNull()
        ->and(app(App\Services\MockResultService::class)->attemptBands(Attempt::find($id))['overall'])->toBeNull();

    // Every module chosen = the whole test; an unknown module is refused.
    studentApi('POST', 'attempts', ['test_id' => $this->test->id, 'module' => 'listening,reading,writing'], $this->token)
        ->assertCreated()->assertJsonPath('attempt.module', null);
    studentApi('POST', 'attempts', ['test_id' => $this->test->id, 'module' => 'reading,speaking'], $this->token)
        ->assertStatus(422)->assertJsonPath('code', 'module_invalid');
});
