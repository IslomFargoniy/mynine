<?php

use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\AttemptType;
use App\Models\MockStudent;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\PersonalAccessToken;

beforeEach(function () {
    $this->admin = makeUser('Admin');
    $this->exam = makeDesktopExam($this->admin);
    $this->device = registerDesktopDevice();
    $this->token = desktopLogin($this->device, 'mock-100001');
    $this->attempt = Attempt::where('mock_student_id', $this->exam['student']->id)->firstOrFail();
});

function answerItem(array $overrides = []): array
{
    return array_merge([
        'client_uuid' => (string) Str::uuid(),
        'part_id' => test()->exam['partL']->id,
        'question_id' => test()->exam['fillQuestion']->id,
        'text' => 'carbon',
        'option_ids' => [],
        'changed_at' => now()->toIso8601String(),
    ], $overrides);
}

function sendAnswers(array $items): TestResponse
{
    return desktopApi('POST', 'exam/answers', ['answers' => $items], test()->device, test()->token);
}

test('login binds the attempt to the device and returns the contract shape', function () {
    $student = $this->exam['student']->fresh();

    expect($student->attended)->toBeTrue()
        ->and($student->checked_in_at)->not->toBeNull()
        ->and($this->attempt->device_id)->not->toBeNull()
        ->and((int) $this->attempt->test_id)->toBe((int) $this->exam['testL']->id);

    $response = desktopApi('POST', 'exam/login', ['code' => ' mock-100001 '], $this->device)->assertOk();
    $response->assertJsonStructure(['token', 'expires_at', 'candidate' => ['id', 'name', 'code'], 'mock' => ['id', 'name', 'starts_at', 'ends_at'], 'attempt_id', 'server_time']);
    expect($response->json('attempt_id'))->toBe($this->attempt->id);

    // The previous token was revoked by the second login (one PC at a time).
    desktopApi('GET', 'exam', [], $this->device, $this->token)->assertStatus(401)->assertJsonPath('code', 'unauthenticated');
});

test('login error codes', function () {
    desktopApi('POST', 'exam/login', ['code' => 'NOPE-1'], $this->device)->assertStatus(422)->assertJsonPath('code', 'invalid_code');
    desktopApi('POST', 'exam/login', [], $this->device)->assertStatus(422)->assertJsonPath('code', 'validation_failed');
    desktopApi('POST', 'exam/login', ['code' => 'MOCK-100001'])->assertStatus(401)->assertJsonPath('code', 'unauthenticated');

    $this->exam['mock']->update(['started_at' => now()->addHour(), 'finished_at' => now()->addHours(5)]);
    desktopApi('POST', 'exam/login', ['code' => 'MOCK-100001'], $this->device)
        ->assertStatus(422)->assertJsonPath('code', 'mock_not_started')->assertJsonStructure(['starts_at']);

    $this->exam['mock']->update(['started_at' => now()->subHours(5), 'finished_at' => now()->subHour()]);
    desktopApi('POST', 'exam/login', ['code' => 'MOCK-100001'], $this->device)->assertStatus(422)->assertJsonPath('code', 'mock_finished');

    $this->exam['mock']->update(['active' => 0]);
    desktopApi('POST', 'exam/login', ['code' => 'MOCK-100001'], $this->device)->assertStatus(422)->assertJsonPath('code', 'mock_not_active');

    $this->exam['mock']->update(['active' => 1, 'started_at' => now()->subHour(), 'finished_at' => now()->addHour()]);
    $this->attempt->update(['finished_at' => now()]);
    desktopApi('POST', 'exam/login', ['code' => 'MOCK-100001'], $this->device)->assertStatus(409)->assertJsonPath('code', 'attempt_finished');
});

test('answer keys never appear in any exam payload', function () {
    $listening = $this->exam['listeningType']->id;
    desktopApi('POST', "exam/modules/{$listening}/start", [], $this->device, $this->token)->assertOk();
    sendAnswers([
        answerItem(),
        answerItem(['question_id' => $this->exam['mcQuestion']->id, 'text' => null, 'option_ids' => [$this->exam['correctOption']->id]]),
    ])->assertOk();

    $payloads = [
        desktopApi('GET', 'exam', [], $this->device, $this->token)->assertOk()->json(),
        $prefetch = desktopApi('GET', 'exam/prefetch', [], $this->device, $this->token)->assertOk()->json(),
        desktopApi('GET', 'exam/parts/'.$this->exam['partL']->id, [], $this->device, $this->token)->assertOk()->json(),
        desktopApi('GET', 'exam/parts/'.$this->exam['partR']->id, [], $this->device, $this->token)->assertOk()->json(),
        desktopApi('POST', 'exam/heartbeat', [], $this->device, $this->token)->assertOk()->json(),
        desktopApi('POST', "exam/modules/{$listening}/start", [], $this->device, $this->token)->assertOk()->json(),
    ];

    foreach ($payloads as $payload) {
        assertNoAnswerKeys($payload);
    }

    // The saved answers come back so the app can restore state, without correctness.
    $partL = collect($prefetch['parts'])->firstWhere('id', $this->exam['partL']->id);
    $mcQuestion = collect($partL['sections'][0]['questions'])->firstWhere('id', $this->exam['mcQuestion']->id);
    expect($mcQuestion['answer']['option_ids'])->toBe([$this->exam['correctOption']->id])
        ->and($partL['sections'][1]['questions'][0]['answer']['text'])->toBe('carbon')
        ->and(json_encode($prefetch))->not->toContain('model essay');

    // Word bank: correct words mixed with distractors, alphabetical.
    $partR = collect($prefetch['parts'])->firstWhere('id', $this->exam['partR']->id);
    expect(collect($partR['sections'][0]['drag_options'])->pluck('label')->all())->toBe(['bright', 'cave', 'dark'])
        ->and($prefetch['images'])->toBe([url('/storage/images/p1.png')]);
});

test('exam state lists Listening, Reading, Writing with numbering and durations', function () {
    $response = desktopApi('GET', 'exam', [], $this->device, $this->token)->assertOk();

    expect(collect($response->json('modules'))->pluck('type')->all())->toBe(['listening', 'reading', 'writing'])
        ->and($response->json('modules.0.status'))->toBe('not_started')
        ->and($response->json('modules.0.duration_seconds'))->toBe(30 * 60)
        ->and($response->json('modules.0.parts.0.question_count'))->toBe(2)
        ->and($response->json('modules.0.parts.0.first_question_number'))->toBe(1)
        ->and($response->json('attempt.paused'))->toBeFalse();

    $part = desktopApi('GET', 'exam/parts/'.$this->exam['partL']->id, [], $this->device, $this->token)->assertOk();
    expect($part->json('sections.0.questions.0.number'))->toBe(1)
        ->and($part->json('sections.1.questions.0.number'))->toBe(2)
        ->and($part->json('sections.0.input_type'))->not->toBeNull();
});

test('a candidate cannot reach another candidate\'s parts or audio', function () {
    Storage::fake('local');
    Storage::disk('local')->put('audio/other.mp3', str_repeat('x', 100));

    $other = makeDesktopExam($this->admin, [], 'MOCK-200002');
    $other['testL']->update(['audio_path' => 'media/audio/other.mp3']);
    $other['partR']->update(['audio_path' => 'media/audio/other.mp3']);

    desktopApi('GET', 'exam/parts/'.$other['partR']->id, [], $this->device, $this->token)->assertForbidden()->assertJsonPath('code', 'forbidden');
    desktopApi('GET', 'exam/audio/test/'.$other['testL']->id, [], $this->device, $this->token)->assertForbidden();
    desktopApi('GET', 'exam/audio/part/'.$other['partR']->id, [], $this->device, $this->token)->assertForbidden();

    desktopApi('POST', 'exam/modules/'.$this->exam['listeningType']->id.'/start', [], $this->device, $this->token)->assertOk();
    sendAnswers([answerItem(['part_id' => $other['partL']->id, 'question_id' => $other['fillQuestion']->id])])
        ->assertOk()->assertJsonPath('results.0.status', 'rejected')->assertJsonPath('results.0.reason', 'invalid_question');

    // The other candidate's token cannot be used from this PC.
    $otherDevice = registerDesktopDevice('MACHINE-2', 'PC-02');
    $otherToken = desktopLogin($otherDevice, 'MOCK-200002');
    desktopApi('GET', 'exam', [], $this->device, $otherToken)->assertStatus(401);

    // A web user token is not an exam token.
    $plain = Str::random(40);
    $userToken = PersonalAccessToken::forceCreate([
        'tokenable_type' => $this->admin::class, 'tokenable_id' => $this->admin->id,
        'name' => 'x', 'token' => hash('sha256', $plain), 'abilities' => ['exam'],
    ])->id.'|'.$plain;
    desktopApi('GET', 'exam', [], $this->device, $userToken)->assertStatus(401);
});

test('audio streams with Range support for the candidate\'s own listening test', function () {
    Storage::fake('local');
    Storage::disk('local')->put('audio/l.mp3', '0123456789');
    $this->exam['testL']->update(['audio_path' => 'media/audio/l.mp3', 'playtime_seconds' => 1920]);

    $exam = desktopApi('GET', 'exam', [], $this->device, $this->token)->assertOk();
    expect($exam->json('modules.0.audio.url'))->toBe(route('api.v1.exam.audio.test', $this->exam['testL']->id))
        ->and($exam->json('modules.0.duration_seconds'))->toBe(1925);

    $prefetch = desktopApi('GET', 'exam/prefetch', [], $this->device, $this->token)->assertOk();
    expect($prefetch->json('audio.0'))->toMatchArray(['key' => 'test-'.$this->exam['testL']->id, 'size' => 10, 'sha256' => hash('sha256', '0123456789')]);

    app('auth')->forgetGuards();
    $response = $this->get('/api/v1/exam/audio/test/'.$this->exam['testL']->id, desktopHeaders($this->device, $this->token) + ['Range' => 'bytes=2-5']);
    $response->assertStatus(206)->assertHeader('Content-Range', 'bytes 2-5/10');
    expect(binaryContent($response))->toBe('2345');
});

test('modules must be taken in order and start is idempotent', function () {
    ['listeningType' => $l, 'readingType' => $r] = $this->exam;

    desktopApi('POST', "exam/modules/{$r->id}/start", [], $this->device, $this->token)->assertStatus(409)->assertJsonPath('code', 'module_locked');

    $first = desktopApi('POST', "exam/modules/{$l->id}/start", [], $this->device, $this->token)->assertOk()->assertJsonPath('status', 'in_progress');
    $this->travel(10)->seconds();
    $again = desktopApi('POST', "exam/modules/{$l->id}/start", [], $this->device, $this->token)->assertOk();
    expect($again->json('finished_at'))->toBe($first->json('finished_at'));

    desktopApi('POST', "exam/modules/{$r->id}/start", [], $this->device, $this->token)->assertStatus(409);
    desktopApi('POST', "exam/modules/{$l->id}/submit", [], $this->device, $this->token)->assertOk()->assertJsonPath('status', 'submitted');
    desktopApi('POST', "exam/modules/{$r->id}/start", [], $this->device, $this->token)->assertOk();
    desktopApi('POST', 'exam/modules/999/start', [], $this->device, $this->token)->assertNotFound()->assertJsonPath('code', 'not_found');

    expect(desktopApi('GET', 'exam', [], $this->device, $this->token)->json('modules.0.status'))->toBe('submitted');
});

test('answers are idempotent: duplicate, stale and last-write-wins', function () {
    desktopApi('POST', 'exam/modules/'.$this->exam['listeningType']->id.'/start', [], $this->device, $this->token)->assertOk();

    $first = answerItem(['text' => 'carbon', 'changed_at' => now()->subSeconds(30)->toIso8601String()]);
    sendAnswers([$first])->assertJsonPath('results.0.status', 'saved');
    sendAnswers([$first])->assertJsonPath('results.0.status', 'duplicate');

    sendAnswers([answerItem(['text' => 'older', 'changed_at' => now()->subMinute()->toIso8601String()])])
        ->assertJsonPath('results.0.status', 'stale');

    $newer = answerItem(['text' => 'oxygen', 'changed_at' => now()->toIso8601String()]);
    $older = answerItem(['text' => 'nitrogen', 'changed_at' => now()->subSeconds(10)->toIso8601String()]);
    sendAnswers([$newer, $older])
        ->assertJsonPath('results.0.status', 'saved')
        ->assertJsonPath('results.1.status', 'stale');

    expect(AttemptAnswer::where('question_id', $this->exam['fillQuestion']->id)->count())->toBe(1)
        ->and(AttemptAnswer::where('question_id', $this->exam['fillQuestion']->id)->value('answer_text'))->toBe('oxygen');

    // Radio answer: correctness recorded server-side only.
    sendAnswers([answerItem(['question_id' => $this->exam['mcQuestion']->id, 'text' => null, 'option_ids' => [$this->exam['correctOption']->id, $this->exam['wrongOption']->id]])])
        ->assertJsonPath('results.0.status', 'saved');
    $this->assertDatabaseHas('attempt_answer_options', ['option_id' => $this->exam['correctOption']->id, 'is_correct' => 1]);
    $this->assertDatabaseMissing('attempt_answer_options', ['option_id' => $this->exam['wrongOption']->id]);

    // Questions of modules that were not started are rejected.
    sendAnswers([answerItem(['part_id' => $this->exam['partR']->id, 'question_id' => $this->exam['dragQ1']->id])])
        ->assertJsonPath('results.0.reason', 'invalid_question');

    sendAnswers(array_fill(0, 201, answerItem()))->assertStatus(422)->assertJsonPath('code', 'validation_failed');
});

test('answers after the module time are rejected, with a grace period for queued offline answers', function () {
    $start = desktopApi('POST', 'exam/modules/'.$this->exam['listeningType']->id.'/start', [], $this->device, $this->token)->assertOk();
    $finishedAt = Carbon\Carbon::parse($start->json('finished_at'));

    $this->travelTo($finishedAt->copy()->addSeconds(10));

    sendAnswers([answerItem(['changed_at' => $finishedAt->copy()->subSeconds(5)->toIso8601String()])])
        ->assertJsonPath('results.0.status', 'saved');
    sendAnswers([answerItem(['changed_at' => $finishedAt->copy()->addSeconds(5)->toIso8601String()])])
        ->assertJsonPath('results.0.status', 'rejected')
        ->assertJsonPath('results.0.reason', 'module_time_over');

    $this->travelTo($finishedAt->copy()->addSeconds(45));
    sendAnswers([answerItem(['changed_at' => $finishedAt->copy()->subSeconds(5)->toIso8601String()])])
        ->assertJsonPath('results.0.status', 'rejected');

    expect((bool) AttemptType::where('attempt_id', $this->attempt->id)->value('is_submitted'))->toBeTrue();
});

test('pause rejects answers and resume shifts the timers', function () {
    $start = desktopApi('POST', 'exam/modules/'.$this->exam['listeningType']->id.'/start', [], $this->device, $this->token)->assertOk();
    $finishedAt = Carbon\Carbon::parse($start->json('finished_at'));

    $this->actingAs($this->admin)->post(route('monitor.pause', $this->attempt))->assertRedirect();

    desktopApi('POST', 'exam/heartbeat', [], $this->device, $this->token)->assertJsonPath('paused', true);
    sendAnswers([answerItem()])->assertJsonPath('results.0.status', 'rejected')->assertJsonPath('results.0.reason', 'paused');
    desktopApi('POST', 'exam/modules/'.$this->exam['listeningType']->id.'/submit', [], $this->device, $this->token)->assertStatus(409)->assertJsonPath('code', 'paused');

    // Time passes beyond the module end while paused: nothing is auto-finished.
    $this->travel(40)->minutes();
    desktopApi('GET', 'exam', [], $this->device, $this->token)->assertJsonPath('modules.0.status', 'in_progress');

    $this->actingAs($this->admin)->post(route('monitor.resume', $this->attempt))->assertRedirect();

    $heartbeat = desktopApi('POST', 'exam/heartbeat', [], $this->device, $this->token)->assertJsonPath('paused', false);
    $newFinishedAt = Carbon\Carbon::parse($heartbeat->json('modules.0.finished_at'));
    expect((int) $finishedAt->diffInSeconds($newFinishedAt))->toBe(40 * 60);

    sendAnswers([answerItem()])->assertJsonPath('results.0.status', 'saved');
});

test('the web exam room also rejects answers while paused', function () {
    $this->attempt->update(['paused_at' => now()]);
    $this->attempt->attempt_parts()->create(['part_id' => $this->exam['partL']->id, 'started_at' => now(), 'finished_at' => now()->addHour()]);

    $this->withSession(['mock_student_id' => $this->exam['student']->id])
        ->postJson(route('attempt-answer.store'), [
            'attempt_id' => $this->attempt->id, 'part_id' => $this->exam['partL']->id,
            'question_id' => $this->exam['fillQuestion']->id, 'answer_text' => 'carbon',
        ])->assertStatus(409);
});

test('force submit by an admin is reflected in the heartbeat', function () {
    desktopApi('POST', 'exam/modules/'.$this->exam['listeningType']->id.'/start', [], $this->device, $this->token)->assertOk();

    $this->actingAs(makeUser('Reception'))->post(route('monitor.force-submit', $this->attempt))->assertForbidden();
    $this->actingAs($this->admin)->post(route('monitor.force-submit', $this->attempt))->assertRedirect();

    desktopApi('POST', 'exam/heartbeat', [], $this->device, $this->token)
        ->assertOk()
        ->assertJsonPath('finished', true)
        ->assertJsonPath('modules.0.status', 'submitted');

    sendAnswers([answerItem()])->assertStatus(409)->assertJsonPath('code', 'attempt_finished');
    expect($this->attempt->fresh()->finished_at)->not->toBeNull();
});

test('extra time extends the running module', function () {
    $start = desktopApi('POST', 'exam/modules/'.$this->exam['listeningType']->id.'/start', [], $this->device, $this->token)->assertOk();

    $this->actingAs($this->admin)->post(route('monitor.extra-time', $this->attempt), ['minutes' => 5])->assertRedirect();
    $this->actingAs($this->admin)->post(route('monitor.extra-time', $this->attempt), ['minutes' => 0])->assertSessionHasErrors('minutes');

    $heartbeat = desktopApi('POST', 'exam/heartbeat', [], $this->device, $this->token);
    expect((int) Carbon\Carbon::parse($start->json('finished_at'))->diffInSeconds(Carbon\Carbon::parse($heartbeat->json('modules.0.finished_at'))))->toBe(300);
});

test('remote unlock is delivered once; reception may unlock but not pause', function () {
    $reception = makeUser('Reception');

    $this->actingAs($reception)->post(route('monitor.pause', $this->attempt))->assertForbidden();
    $this->actingAs(makeUser('Student'))->post(route('monitor.unlock', $this->attempt))->assertForbidden();
    $this->actingAs($reception)->post(route('monitor.unlock', $this->attempt))->assertRedirect();

    desktopApi('POST', 'exam/heartbeat', [], $this->device, $this->token)->assertJsonPath('unlock', true);
    desktopApi('POST', 'exam/heartbeat', [], $this->device, $this->token)->assertJsonPath('unlock', false);

    // After submit the PC sits on the code screen: the device heartbeat delivers the unlock.
    desktopApi('POST', 'exam/submit', [], $this->device, $this->token)->assertOk()->assertJsonPath('status', 'completed');
    $this->actingAs($reception)->post(route('monitor.unlock', $this->attempt))->assertRedirect();
    desktopApi('POST', 'device/heartbeat', ['app_version' => '1.0.0', 'state' => 'idle'], $this->device)->assertJsonPath('unlock', true);
});

test('submit finishes the attempt, revokes the token and never returns scores', function () {
    desktopApi('POST', 'exam/modules/'.$this->exam['listeningType']->id.'/start', [], $this->device, $this->token)->assertOk();
    sendAnswers([answerItem()])->assertOk();

    $response = desktopApi('POST', 'exam/submit', [], $this->device, $this->token)->assertOk();
    expect(array_keys($response->json()))->toBe(['status', 'server_time']);

    expect($this->attempt->fresh()->finished_at)->not->toBeNull();
    desktopApi('GET', 'exam', [], $this->device, $this->token)->assertStatus(401);
});

test('violations are stored idempotently and focus loss bumps the web counter', function () {
    $uuid = (string) Str::uuid();
    $payload = ['violations' => [
        ['client_uuid' => $uuid, 'type' => 'focus_lost', 'detail' => ['process' => 'chrome.exe'], 'occurred_at' => now()->toIso8601String()],
        ['client_uuid' => (string) Str::uuid(), 'type' => 'second_monitor', 'occurred_at' => now()->toIso8601String()],
    ]];

    desktopApi('POST', 'exam/violations', $payload, $this->device, $this->token)->assertOk()->assertJsonPath('accepted', 2);
    desktopApi('POST', 'exam/violations', $payload, $this->device, $this->token)->assertOk();

    expect($this->attempt->violations()->count())->toBe(2)
        ->and($this->attempt->fresh()->tab_switch_count)->toBe(1);

    desktopApi('POST', 'exam/violations', ['violations' => [['type' => 'hacking', 'occurred_at' => now()->toIso8601String()]]], $this->device, $this->token)
        ->assertStatus(422);
});

test('logout revokes the exam token', function () {
    desktopApi('POST', 'exam/logout', [], $this->device, $this->token)->assertNoContent();
    desktopApi('GET', 'exam', [], $this->device, $this->token)->assertStatus(401);
});

test('exam tokens expire one hour after the mock ends', function () {
    $token = $this->exam['student']->tokens()->first();
    expect($token->expires_at->equalTo(Carbon\Carbon::parse($this->exam['mock']->fresh()->finished_at)->addHour()))->toBeTrue()
        ->and($token->can('exam'))->toBeTrue()
        ->and($token->tokenable)->toBeInstanceOf(MockStudent::class);
});
