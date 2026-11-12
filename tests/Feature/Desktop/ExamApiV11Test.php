<?php

use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\AttemptPart;
use App\Models\AttemptType;
use App\Models\Device;
use App\Models\Option;
use App\Models\Question;
use App\Models\TestType;
use App\Services\ExamService;
use Carbon\Carbon;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Testing\TestResponse;

/*
|--------------------------------------------------------------------------
| Desktop API v1.1 contract (docs/desktop/API.md "v1.1 changes")
|--------------------------------------------------------------------------
*/

beforeEach(function () {
    $this->admin = makeUser('Admin');
    $this->exam = makeDesktopExam($this->admin);
    $this->device = registerDesktopDevice();
    $this->token = desktopLogin($this->device, 'MOCK-100001');
    $this->attempt = Attempt::where('mock_student_id', $this->exam['student']->id)->firstOrFail();
    $this->listening = $this->exam['listeningType']->id;
});

function v11Item(array $overrides = []): array
{
    return array_merge([
        'client_uuid' => (string) Str::uuid(),
        'part_id' => test()->exam['partL']->id,
        'question_id' => test()->exam['fillQuestion']->id,
        'text' => 'carbon',
        'option_ids' => [],
        'changed_at' => now()->format('Y-m-d\TH:i:s.vP'),
    ], $overrides);
}

function v11Send(array $items): TestResponse
{
    return desktopApi('POST', 'exam/answers', ['answers' => $items], test()->device, test()->token);
}

function startListening(): Carbon
{
    $start = desktopApi('POST', 'exam/modules/'.test()->listening.'/start', [], test()->device, test()->token)->assertOk();

    return Carbon::parse($start->json('finished_at'));
}

test('a) every timestamp has milliseconds and an offset', function () {
    $pattern = '/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}[+-]\d\d:\d\d$/';

    $start = desktopApi('POST', 'exam/modules/'.$this->listening.'/start', [], $this->device, $this->token)->assertOk();
    expect($start->json('server_time'))->toMatch($pattern)->and($start->json('finished_at'))->toMatch($pattern);

    foreach ([['GET', 'exam'], ['POST', 'exam/heartbeat'], ['GET', 'exam/prefetch']] as [$method, $uri]) {
        expect(desktopApi($method, $uri, [], $this->device, $this->token)->assertOk()->json('server_time'))->toMatch($pattern);
    }
    expect(desktopApi('POST', 'device/heartbeat', [], $this->device)->json('server_time'))->toMatch($pattern);
    expect(desktopApi('POST', 'exam/login', ['code' => 'MOCK-100001'], $this->device)->json('expires_at'))->toMatch($pattern);
});

test('b) an invalid item is rejected on its own, never the whole batch', function () {
    startListening();

    $response = v11Send([
        v11Item(['text' => str_repeat('a', 20001)]),
        v11Item(['changed_at' => 'yesterday-ish']),
        v11Item(['option_ids' => range(1, 51)]),
        v11Item(['question_id' => 999999]),
        v11Item(['part_id' => 'abc']),
        v11Item(),
    ])->assertOk();

    expect(collect($response->json('results'))->map(fn ($r) => $r['reason'] ?? $r['status'])->all())
        ->toBe(['invalid', 'invalid', 'too_many_options', 'invalid_question', 'invalid', 'saved']);

    // Only a malformed envelope is a 422.
    desktopApi('POST', 'exam/answers', ['answers' => [['text' => 'no uuid']]], $this->device, $this->token)
        ->assertStatus(422)->assertJsonPath('code', 'validation_failed');
});

test('b) choose-TWO questions refuse more options than the key has', function () {
    startListening();
    $section = makeSection($this->exam['partL'], 'multiple_response', 'Choose TWO');
    $q = Question::create(['section_id' => $section->id, 'order' => 3]);
    $ids = collect(['A' => 1, 'B' => 1, 'C' => 0])->map(fn ($c, $t) => Option::create(['question_id' => $q->id, 'textarea' => $t, 'is_correct' => $c])->id)->values()->all();

    v11Send([v11Item(['question_id' => $q->id, 'text' => null, 'option_ids' => $ids])])
        ->assertJsonPath('results.0.status', 'rejected')->assertJsonPath('results.0.reason', 'too_many_options');
    v11Send([v11Item(['question_id' => $q->id, 'text' => null, 'option_ids' => [$ids[0], $ids[2]]])])
        ->assertJsonPath('results.0.status', 'saved');
});

test('c) seq orders changes of one question when both sides have it, else changed_at', function () {
    startListening();
    $value = fn () => AttemptAnswer::where('question_id', $this->exam['fillQuestion']->id)->value('answer_text');

    v11Send([v11Item(['text' => 'two', 'seq' => 2, 'changed_at' => now()->subSeconds(5)->format('Y-m-d\TH:i:s.vP')])])->assertJsonPath('results.0.status', 'saved');
    // A higher changed_at but a lower seq loses (the PC clock jumped).
    v11Send([v11Item(['text' => 'one', 'seq' => 1, 'changed_at' => now()->format('Y-m-d\TH:i:s.vP')])])->assertJsonPath('results.0.status', 'stale');
    v11Send([v11Item(['text' => 'three', 'seq' => 3, 'changed_at' => now()->subMinute()->format('Y-m-d\TH:i:s.vP')])])->assertJsonPath('results.0.status', 'saved');
    expect($value())->toBe('three')
        ->and((int) AttemptAnswer::where('question_id', $this->exam['fillQuestion']->id)->value('client_seq'))->toBe(3);

    // Without seq: milliseconds decide.
    $other = $this->exam['mcQuestion']->id;
    $t = now();
    v11Send([v11Item(['question_id' => $other, 'text' => null, 'option_ids' => [$this->exam['correctOption']->id], 'changed_at' => $t->copy()->addMilliseconds(500)->format('Y-m-d\TH:i:s.vP')])]);
    v11Send([v11Item(['question_id' => $other, 'text' => null, 'option_ids' => [$this->exam['wrongOption']->id], 'changed_at' => $t->copy()->addMilliseconds(200)->format('Y-m-d\TH:i:s.vP')])])
        ->assertJsonPath('results.0.status', 'stale');
});

test('e) a PC that was offline at the module end syncs its queued answers late, within the cap', function () {
    $finishedAt = startListening();
    desktopApi('POST', 'exam/heartbeat', [], $this->device, $this->token)->assertOk(); // online before the end

    // Offline from here; reconnects 5 minutes after the end: the heartbeat runs first.
    $this->travelTo($finishedAt->copy()->addMinutes(5));
    desktopApi('POST', 'exam/heartbeat', [], $this->device, $this->token)->assertOk();

    v11Send([
        v11Item(['text' => 'late', 'changed_at' => $finishedAt->copy()->subSeconds(20)->format('Y-m-d\TH:i:s.vP')]),
        v11Item(['question_id' => $this->exam['mcQuestion']->id, 'text' => null, 'option_ids' => [$this->exam['correctOption']->id], 'changed_at' => $finishedAt->copy()->addSecond()->format('Y-m-d\TH:i:s.vP')]),
    ])
        ->assertJsonPath('results.0.status', 'saved')->assertJsonPath('results.0.late', true)
        ->assertJsonPath('results.1.status', 'rejected');

    $type = AttemptType::where('attempt_id', $this->attempt->id)->where('type_id', $this->listening)->first();
    expect($type->is_submitted)->toBeTruthy()
        ->and($type->offline_at_end)->toBeTrue()
        ->and(Carbon::parse($type->finished_at)->equalTo($finishedAt))->toBeTrue()
        ->and((bool) AttemptAnswer::where('question_id', $this->exam['fillQuestion']->id)->value('late_synced'))->toBeTrue()
        // Re-scored: "late" is not "carbon", so 0; then a correct late answer counts.
        ->and((float) $type->is_correct_count)->toBe(0.0);

    v11Send([v11Item(['text' => 'carbon', 'changed_at' => $finishedAt->copy()->subSeconds(10)->format('Y-m-d\TH:i:s.vP')])])->assertJsonPath('results.0.status', 'saved');
    expect((float) $type->fresh()->is_correct_count)->toBe(1.0);

    // Even after the attempt was finished (force submit), until the cap.
    app(ExamService::class)->finishAttempt($this->attempt->fresh());
    v11Send([v11Item(['text' => 'carbon', 'changed_at' => $finishedAt->copy()->subSeconds(5)->format('Y-m-d\TH:i:s.vP')])])->assertOk();

    $this->travelTo($finishedAt->copy()->addMinutes(121));
    v11Send([v11Item(['changed_at' => $finishedAt->copy()->subSeconds(2)->format('Y-m-d\TH:i:s.vP')])])
        ->assertStatus(409)->assertJsonPath('code', 'attempt_finished');
});

test('f) the version gate applies to login only, never to a running exam', function () {
    useReleaseManifest(releaseManifestData(['min_version' => '2.0.0']));

    desktopApi('GET', 'exam', [], $this->device, $this->token, '1.0.0')->assertOk();
    desktopApi('POST', 'exam/heartbeat', [], $this->device, $this->token, '1.0.0')->assertOk();
    desktopApi('POST', 'exam/login', ['code' => 'MOCK-100001'], $this->device, null, '1.0.0')
        ->assertStatus(426)->assertJsonPath('code', 'client_outdated');
});

test('h) login on another PC is refused while the bound PC is alive, until the invigilator releases it', function () {
    startListening();
    desktopApi('POST', 'exam/heartbeat', [], $this->device, $this->token)->assertOk();

    $second = registerDesktopDevice('MACHINE-2', 'PC-02');
    desktopApi('POST', 'exam/login', ['code' => 'MOCK-100001'], $second)
        ->assertStatus(409)->assertJsonPath('code', 'session_active_elsewhere');

    // Reception releases the PC from the live monitor.
    $this->actingAs(makeUser('Reception'))->postJson(route('monitor.release-device', $this->attempt))->assertOk()->assertJsonPath('ok', true);
    $this->actingAs(makeUser('Student'))->post(route('monitor.release-device', $this->attempt))->assertForbidden();

    desktopApi('GET', 'exam', [], $this->device, $this->token)->assertStatus(401)->assertJsonPath('code', 'session_revoked');
    $newToken = desktopLogin($second, 'MOCK-100001');
    desktopApi('GET', 'exam', [], $second, $newToken)->assertOk();
    expect(Device::where('machine_id', 'MACHINE-1')->value('current_attempt_id'))->toBeNull();
});

test('h) a silent bound PC (no heartbeat for 90 s) does not block the login, and loses the attempt', function () {
    desktopApi('POST', 'exam/heartbeat', [], $this->device, $this->token)->assertOk();
    $this->travel(2)->minutes();

    $second = registerDesktopDevice('MACHINE-2', 'PC-02');
    desktopLogin($second, 'MOCK-100001');

    expect(Device::where('machine_id', 'MACHINE-1')->value('current_attempt_id'))->toBeNull()
        ->and((int) $this->attempt->fresh()->device_id)->toBe(Device::where('machine_id', 'MACHINE-2')->value('id'));
});

test('c) moving to another PC forgets the old seq counters, so the new PC (seq from 1) is not stale', function () {
    startListening();
    $q = $this->exam['fillQuestion']->id;
    v11Send([v11Item(['text' => 'old pc', 'seq' => 9])])->assertJsonPath('results.0.status', 'saved');

    $this->actingAs(makeUser('Reception'))->postJson(route('monitor.release-device', $this->attempt))->assertOk();
    expect(AttemptAnswer::where('question_id', $q)->value('client_seq'))->toBeNull();

    $second = registerDesktopDevice('MACHINE-2', 'PC-02');
    $token = desktopLogin($second, 'MOCK-100001');
    desktopApi('POST', 'exam/answers', ['answers' => [v11Item(['text' => 'new pc', 'seq' => 1])]], $second, $token)
        ->assertJsonPath('results.0.status', 'saved');
    expect(AttemptAnswer::where('question_id', $q)->value('answer_text'))->toBe('new pc');
});

test('c) a silent PC taken over by another also loses its seq counters', function () {
    startListening();
    v11Send([v11Item(['text' => 'old pc', 'seq' => 9])])->assertJsonPath('results.0.status', 'saved');
    $this->travel(2)->minutes();

    $second = registerDesktopDevice('MACHINE-2', 'PC-02');
    $token = desktopLogin($second, 'MOCK-100001');
    expect(AttemptAnswer::where('question_id', $this->exam['fillQuestion']->id)->value('client_seq'))->toBeNull();
});

test('14) audio goes through nginx with X-Accel-Redirect when enabled', function () {
    Storage::fake('local');
    Storage::disk('local')->put('audio/test l.mp3', 'ID3audio');
    $this->exam['testL']->update(['audio_path' => 'media/audio/test l.mp3']);

    $url = 'exam/audio/test/'.$this->exam['testL']->id;
    desktopApi('GET', $url, [], $this->device, $this->token)->assertOk()->assertHeaderMissing('X-Accel-Redirect');

    config(['desktop.x_accel_audio' => true]);
    $response = desktopApi('GET', $url, [], $this->device, $this->token)->assertOk()
        ->assertHeader('X-Accel-Redirect', '/_protected_audio/test%20l.mp3');
    expect($response->baseResponse->getContent())->toBe('');
});

test('12) a mock keeps its modules once a candidate started one', function () {
    $mock = $this->exam['mock'];
    $payload = fn (array $modules) => [
        'name' => $mock->name, 'started_at' => now()->subHour()->format('Y-m-d H:i'), 'finished_at' => now()->addHours(3)->format('Y-m-d H:i'),
        'modules' => $modules,
    ];
    $current = [$this->exam['listening']->id, $this->exam['reading']->id, $this->exam['writing']->id];

    // The candidate logged in (beforeEach): the PC may already hold the questions, so the modules are fixed.
    expect($mock->modulesLocked())->toBeTrue();

    startListening();
    expect($mock->modulesLocked())->toBeTrue();

    $this->actingAs($this->admin)->put(route('mock.update', $mock), $payload([$this->exam['reading']->id, $this->exam['writing']->id]))
        ->assertSessionHasErrors('modules');
    // Saving the other fields with the same modules still works.
    $this->actingAs($this->admin)->put(route('mock.update', $mock), $payload(array_reverse($current)))->assertSessionHasNoErrors();
});

test('audio lag: the Listening module ends later by the missed audio, once per total, capped; not for other modules', function () {
    $end = startListening();
    $uri = 'exam/modules/'.$this->listening.'/audio-lag';

    $r = desktopApi('POST', $uri, ['lag_seconds' => 60], $this->device, $this->token)->assertOk();
    expect(Carbon::parse($r->json('finished_at'))->diffInSeconds($end->copy()->addSeconds(60), true))->toBeLessThan(1)
        ->and($r->json('audio_lag_seconds'))->toBe(60);

    // The same total again (a retry) or a smaller one: no further change.
    desktopApi('POST', $uri, ['lag_seconds' => 60], $this->device, $this->token)->assertOk();
    desktopApi('POST', $uri, ['lag_seconds' => 10], $this->device, $this->token)->assertOk();
    $type = AttemptType::where('attempt_id', $this->attempt->id)->where('type_id', $this->listening)->firstOrFail();
    expect(Carbon::parse($type->finished_at)->diffInSeconds($end->copy()->addSeconds(60), true))->toBeLessThan(1)
        ->and($type->audio_lag_seconds)->toBe(60);

    // A later restart adds only the difference; the parts move with the module.
    desktopApi('POST', $uri, ['lag_seconds' => 90], $this->device, $this->token)->assertOk();
    expect(Carbon::parse($type->fresh()->finished_at)->diffInSeconds($end->copy()->addSeconds(90), true))->toBeLessThan(1);
    $partEnd = AttemptPart::where('attempt_id', $this->attempt->id)->where('part_id', $this->exam['partL']->id)->value('finished_at');
    expect(Carbon::parse($partEnd)->diffInSeconds($end->copy()->addSeconds(90), true))->toBeLessThan(1);

    // The exam state carries the lag (the app uses it for the audio position after a restart).
    $state = desktopApi('GET', 'exam', [], $this->device, $this->token)->assertOk();
    expect(collect($state->json('modules'))->firstWhere('type_id', $this->listening)['audio_lag_seconds'])->toBe(90);

    // Capped at the module length.
    $listeningModule = TestType::where('test_id', $this->exam['testL']->id)->where('type_id', $this->listening)->firstOrFail();
    $max = app(ExamService::class)->moduleDurationSeconds($listeningModule);
    desktopApi('POST', $uri, ['lag_seconds' => 7000], $this->device, $this->token)->assertOk()->assertJsonPath('audio_lag_seconds', min(7000, $max));
});

test('audio lag: refused before the module started and after the attempt finished', function () {
    $uri = 'exam/modules/'.$this->listening.'/audio-lag';
    desktopApi('POST', $uri, ['lag_seconds' => 30], $this->device, $this->token)->assertStatus(409);

    startListening();
    app(ExamService::class)->finishAttempt($this->attempt->fresh());
    $before = AttemptType::where('attempt_id', $this->attempt->id)->where('type_id', $this->listening)->value('finished_at');
    desktopApi('POST', $uri, ['lag_seconds' => 30], $this->device, $this->token);
    expect(AttemptType::where('attempt_id', $this->attempt->id)->where('type_id', $this->listening)->value('finished_at'))->toEqual($before);
});
