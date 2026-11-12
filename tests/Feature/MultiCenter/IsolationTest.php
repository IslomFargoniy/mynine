<?php

use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\AttemptPart;
use App\Models\AttemptType;
use App\Models\Device;
use App\Models\Mock;
use App\Models\MockStudent;
use App\Models\Test as ExamTest;
use App\Models\TestImport;
use App\Models\User\User;
use App\Services\ExamService;
use App\Support\CurrentCenter;
use Illuminate\Support\Facades\Storage;
use Illuminate\Testing\TestResponse;
use Inertia\Testing\AssertableInertia as Assert;

/*
| Two centers A (the Mynine center) and B, each with its own mock, candidate, attempt (Writing submitted),
| Mock Bank tests, import, PC, Reception user and audio file. Every page, action, export, PDF, media file and
| API of B must be invisible (404 / 403 / empty list) for A's Admin and Reception, and the other way round.
*/

/**
 * @return array<string, mixed>
 */
function centerWorld(User $admin, string $code, string $machineId, string $password): array
{
    $exam = makeDesktopExam($admin, ['name' => 'Mock of '.$admin->centerSetting->code], $code);
    $reception = makeUser('Reception', $admin);

    $attempt = app(ExamService::class)->findOrCreateMockAttempt($exam['student']);
    $writing = AttemptType::create([
        'attempt_id' => $attempt->id, 'type_id' => $exam['writingType']->id,
        'started_at' => now()->subHour(), 'finished_at' => now(), 'is_submitted' => true,
    ]);
    $attemptPart = AttemptPart::create(['attempt_id' => $attempt->id, 'part_id' => $exam['partW']->id, 'started_at' => now()]);
    $essay = AttemptAnswer::create([
        'attempt_part_id' => $attemptPart->id, 'question_id' => $exam['essayQuestion']->id,
        'answer_text' => str_repeat('An essay sentence. ', 20),
    ]);

    $import = TestImport::forceCreate([
        'owner_id' => $admin->id, 'test_id' => $exam['testL']->id, 'user_id' => $admin->id,
        'status' => TestImport::DONE, 'modules' => [],
    ]);

    $audio = 'center-'.strtolower($code).'.mp3';
    Storage::disk('local')->put('audio/'.$audio, 'ID3 fake audio');
    $exam['testL']->forceFill(['audio_path' => 'media/audio/'.$audio])->save();

    centerSettings($admin)->setExitPassword($password);
    $deviceToken = desktopApi('POST', 'device/register', [
        'machine_id' => $machineId, 'name' => 'PC '.$code, 'password' => $password,
        'center_code' => centerSettings($admin)->code,
    ])->assertOk()->json('device_token');
    $device = Device::withoutGlobalScopes()->where('machine_id', $machineId)->firstOrFail();
    $device->approve();

    return [
        'admin' => $admin, 'reception' => $reception, 'exam' => $exam, 'mock' => $exam['mock'], 'student' => $exam['student'],
        'attempt' => $attempt, 'writing' => $writing, 'essay' => $essay, 'import' => $import, 'audio' => $audio,
        'device' => $device, 'deviceToken' => $deviceToken, 'password' => $password,
    ];
}

/**
 * Not found or forbidden: either way the other center's record is out of reach.
 */
function assertBlocked(TestResponse $response): void
{
    expect($response->status())->toBeIn([403, 404], 'Expected 403/404, got '.$response->status().' '.substr((string) $response->getContent(), 0, 200));
}

beforeEach(function () {
    Storage::fake('local');
    Storage::fake('public');

    $this->adminA = makeCenter(); // Mynine
    $this->adminB = makeCenter('BETA');

    $this->a = centerWorld($this->adminA, '111111', 'MACHINE-A', 'alpha-pass');
    $this->b = centerWorld($this->adminB, '222222', 'MACHINE-B', 'beta-pass');

    // Assertions below run outside any request: no leftover center from the last API call.
    request()->attributes->remove(CurrentCenter::REQUEST_ATTRIBUTE);
});

test('the fixture gives each center its own records', function () {
    expect(Mock::withoutGlobalScopes()->find($this->a['mock']->id)->owner_id)->toBe($this->adminA->id)
        ->and(Mock::withoutGlobalScopes()->find($this->b['mock']->id)->owner_id)->toBe($this->adminB->id)
        ->and(ExamTest::withoutGlobalScopes()->find($this->b['exam']['testR']->id)->owner_id)->toBe($this->adminB->id)
        ->and($this->b['device']->owner_id)->toBe($this->adminB->id)
        ->and($this->b['reception']->owner_id)->toBe($this->adminB->id);
});

test('lists of A never contain B (Admin)', function () {
    $admin = $this->adminA;
    $bMock = $this->b['mock']->id;

    $this->actingAs($admin)->get(route('mock.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('mock.data', fn ($rows) => collect($rows)->pluck('id')->all() === [$this->a['mock']->id]));

    $this->actingAs($admin)->get(route('mock-bank.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('tests', fn ($rows) => collect($rows)->pluck('id')->sort()->values()->all()
            === collect([$this->a['exam']['testL']->id, $this->a['exam']['testR']->id, $this->a['exam']['testW']->id])->sort()->values()->all()));

    $this->actingAs($admin)->get(route('reception.index', ['mock_id' => 'all']))->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->where('mocks', fn ($rows) => ! collect($rows)->contains('id', $bMock))
            ->where('candidates', fn ($rows) => collect($rows)->pluck('id')->all() === [$this->a['student']->id]));

    $this->actingAs($admin)->get(route('monitor.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('mocks', fn ($rows) => ! collect($rows)->contains('id', $bMock)));

    $this->actingAs($admin)->get(route('speaking.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('mocks', fn ($rows) => ! collect($rows)->contains('id', $bMock)));

    $this->actingAs($admin)->get(route('writing-review.index', ['status' => 'all']))->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->where('items', fn ($rows) => collect($rows)->pluck('id')->all() === [$this->a['writing']->id])
            ->where('mocks', fn ($rows) => ! collect($rows)->contains('id', $bMock))
            ->where('pendingAi', 1));

    $this->actingAs($admin)->get(route('desktop.devices.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('devices', fn ($rows) => collect($rows)->pluck('id')->all() === [$this->a['device']->id]));

    $this->actingAs($admin)->get(route('attempt.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->where('attempt.data', fn ($rows) => collect($rows)->pluck('id')->all() === [$this->a['attempt']->id])
            ->where('mocks', fn ($rows) => ! collect($rows)->contains('id', $bMock)));

    $this->actingAs($admin)->get(route('staff.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('staff', fn ($rows) => collect($rows)->pluck('id')->all() === [$this->a['reception']->id]));

    $this->actingAs($admin)->get(route('mock.create'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('modules', fn ($rows) => collect($rows)->pluck('test_id')->unique()->sort()->values()->all()
            === collect([$this->a['exam']['testL']->id, $this->a['exam']['testR']->id, $this->a['exam']['testW']->id])->sort()->values()->all()));
});

test('lists of A never contain B (Reception)', function () {
    $this->actingAs($this->a['reception'])->get(route('reception.index', ['mock_id' => 'all']))->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->where('mocks', fn ($rows) => collect($rows)->pluck('id')->all() === [$this->a['mock']->id])
            ->where('candidates', fn ($rows) => collect($rows)->pluck('id')->all() === [$this->a['student']->id]));

    $this->actingAs($this->a['reception'])->get(route('monitor.index', ['mock_id' => $this->b['mock']->id]))->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->where('mocks', fn ($rows) => ! collect($rows)->contains('id', $this->b['mock']->id))
            ->where('attempts', fn ($rows) => ! collect($rows)->contains('id', $this->b['attempt']->id)));
});

test('every page and action on B records is out of reach for A\'s Admin', function () {
    $b = $this->b;
    $this->actingAs($this->adminA);

    $requests = [
        ['get', route('mock.show', $b['mock'])],
        ['get', route('mock.edit', $b['mock'])],
        ['put', route('mock.update', $b['mock']), ['name' => 'Hacked', 'started_at' => now()->format('Y-m-d H:i'), 'finished_at' => now()->addHour()->format('Y-m-d H:i')]],
        ['delete', route('mock.destroy', $b['mock'])],
        ['get', route('mock.code-cards', $b['mock'])],
        ['get', route('mock.code-tickets', $b['mock'])],
        ['post', route('mock-student.store'), ['mock_id' => $b['mock']->id, 'candidates' => [['name' => 'X', 'phone' => '901234567']]]],
        ['post', route('mock-student.check-repeats'), ['mock_id' => $b['mock']->id, 'phones' => ['901234567']]],
        ['delete', route('mock-student.destroy', $b['student'])],
        ['post', route('reception.check-in', $b['student'])],
        ['post', route('reception.deliver', $b['student'])],
        ['post', route('speaking.auto-assign', $b['mock']), ['order' => 'name']],
        ['post', route('speaking.slot', $b['student']), ['speaking_at' => now()->format('Y-m-d H:i')]],
        ['post', route('speaking.score', $b['student']), ['fluency' => 6, 'lexical' => 6, 'grammar' => 6, 'pronunciation' => 6]],
        ['post', route('writing-review.confirm', $b['writing']), ['band' => 7]],
        ['post', route('monitor.extra-time', $b['attempt']), ['minutes' => 5]],
        ['post', route('monitor.pause', $b['attempt'])],
        ['post', route('monitor.resume', $b['attempt'])],
        ['post', route('monitor.force-submit', $b['attempt'])],
        ['post', route('monitor.unlock', $b['attempt'])],
        ['post', route('monitor.release-device', $b['attempt'])],
        ['get', route('attempt.show', $b['attempt'])],
        ['get', route('attempt.pdf', $b['attempt'])],
        ['delete', route('attempt.destroy', $b['attempt'])],
        ['get', route('attempt-part.index', ['attempt_id' => $b['attempt']->id, 'type_id' => $b['exam']['writingType']->id])],
        ['post', route('attempt-type.store'), ['attempt_id' => $b['attempt']->id, 'score' => 7]],
        ['post', route('attempt-answer.re-evaluate-ai', $b['essay'])],
        ['post', route('mock-bank.status', $b['exam']['testR']), ['status' => 'archived']],
        ['post', route('mock-bank.to-practice', $b['exam']['testR'])],
        ['post', route('mock-bank.import', $b['exam']['testR'])],
        ['get', route('test.show', $b['exam']['testR'])],
        ['post', route('test.update', $b['exam']['testR']), ['name' => 'Hacked']],
        ['delete', route('test.destroy', $b['exam']['testR'])],
        ['get', route('test-type.show', $b['exam']['reading'])],
        ['get', route('part.show', $b['exam']['partR'])],
        ['get', route('part.create', ['test_type_id' => $b['exam']['reading']->id])],
        ['delete', route('part.destroy', $b['exam']['partR'])],
        ['put', route('question.update', $b['exam']['dragQ1']), ['textarea' => 'Hacked', 'answer_text' => 'x']],
        ['delete', route('question.destroy', $b['exam']['dragQ1'])],
        ['delete', route('section.destroy', $b['exam']['partR']->sections()->first())],
        ['delete', route('option.destroy', $b['exam']['correctOption'])],
        ['post', route('part.import-ai', $b['exam']['partR']), ['text' => 'x']],
        ['post', route('desktop.devices.approve', $b['device']), ['number' => 5]],
        ['post', route('desktop.devices.block', $b['device'])],
        ['post', route('desktop.devices.unblock', $b['device'])],
        ['patch', route('desktop.devices.update', $b['device']), ['name' => 'Hacked']],
        ['delete', route('desktop.devices.destroy', $b['device'])],
        ['patch', route('staff.update', $b['reception']), ['name' => 'Hacked', 'email' => 'h@example.com']],
        ['post', route('staff.suspend', $b['reception'])],
        ['post', route('staff.activate', $b['reception'])],
        ['get', route('media.audio', $b['audio'])],
        ['get', route('user.index')],
        ['get', route('centers.index')],
        ['post', route('centers.switch', $this->adminB)],
    ];

    foreach ($requests as $request) {
        [$method, $url, $data] = $request + [2 => []];
        assertBlocked($this->{$method.'Json'}($url, $data));
    }

    // Nothing of B changed.
    $mock = Mock::withoutGlobalScopes()->find($b['mock']->id);
    $device = Device::withoutGlobalScopes()->find($b['device']->id);
    expect($mock->name)->toBe('Mock of BETA')
        ->and(MockStudent::withoutGlobalScopes()->where('mock_id', $b['mock']->id)->count())->toBe(1)
        ->and(MockStudent::withoutGlobalScopes()->find($b['student']->id)->checked_in_at)->toBeNull()
        ->and(Attempt::withoutGlobalScopes()->find($b['attempt']->id)->paused_at)->toBeNull()
        ->and(AttemptType::find($b['writing']->id)->reviewed_at)->toBeNull()
        ->and(ExamTest::withoutGlobalScopes()->find($b['exam']['testR']->id)->bank_status)->toBe(ExamTest::BANK_READY)
        ->and($device->name)->toBe('PC 222222')
        ->and($device->is_blocked)->toBeFalse()
        ->and($b['reception']->fresh()->suspended_at)->toBeNull()
        ->and($b['exam']['dragQ1']->fresh()->textarea)->not->toBe('Hacked');
});

test('result sheets of A skip B candidates; A\'s own sheets still print', function () {
    $this->actingAs($this->adminA)->get(route('reception.result-sheets', ['ids' => $this->b['student']->id]))->assertStatus(422);
    $this->actingAs($this->a['reception'])->get(route('reception.result-sheets', ['ids' => $this->b['student']->id]))->assertStatus(422);
});

test('A\'s Reception cannot touch B', function () {
    $b = $this->b;
    $this->actingAs($this->a['reception']);

    foreach ([
        ['get', route('mock.code-cards', $b['mock'])],
        ['get', route('mock.code-tickets', $b['mock'])],
        ['post', route('mock-student.store'), ['mock_id' => $b['mock']->id, 'candidates' => [['name' => 'X', 'phone' => '901234567']]]],
        ['post', route('reception.check-in', $b['student'])],
        ['post', route('reception.deliver', $b['student'])],
        ['post', route('monitor.unlock', $b['attempt'])],
        ['post', route('monitor.release-device', $b['attempt'])],
        ['get', route('attempt.show', $b['attempt'])],
        ['get', route('media.audio', $b['audio'])],
        ['get', route('mock.index')],
        ['get', route('staff.index')],
        ['get', route('desktop.devices.index')],
    ] as $request) {
        [$method, $url, $data] = $request + [2 => []];
        assertBlocked($this->{$method.'Json'}($url, $data));
    }

    expect(MockStudent::withoutGlobalScopes()->where('mock_id', $b['mock']->id)->count())->toBe(1);
});

test('the same pages work for each center\'s own records', function () {
    $this->actingAs($this->adminB)->get(route('mock.show', $this->b['mock']))->assertOk();
    $this->actingAs($this->adminB)->get(route('mock.code-cards', $this->b['mock']))->assertOk();
    $this->actingAs($this->b['reception'])->post(route('reception.check-in', $this->b['student']))->assertRedirect();
    $this->actingAs($this->adminB)->get(route('media.audio', $this->b['audio']))->assertOk();
    $this->actingAs($this->adminB)->get(route('test-type.show', $this->b['exam']['reading']))->assertOk();
    $this->actingAs($this->adminB)->post(route('mock-bank.status', $this->b['exam']['testR']), ['status' => 'archived'])->assertSessionHas('success');

    expect(MockStudent::withoutGlobalScopes()->find($this->b['student']->id)->checked_in_at)->not->toBeNull();
});

test('a candidate of another center hears no audio of this center', function () {
    // B's candidate session (web code entry) may stream B's audio, not A's.
    $this->withSession(['mock_student_id' => $this->b['student']->id])->get(route('media.audio', $this->b['audio']))->assertOk();
    $this->withSession(['mock_student_id' => $this->b['student']->id])->get(route('media.audio', $this->a['audio']))->assertNotFound();

    // A logged-in student without a mock of that center: no Mock Bank audio.
    $this->actingAs(makeUser('Student'))->get(route('media.audio', $this->a['audio']))->assertNotFound();
});

test('an exam PC of A cannot log in B\'s candidate, and B\'s exam token is useless on A\'s PC', function () {
    desktopApi('POST', 'exam/login', ['code' => $this->b['student']->code], $this->a['deviceToken'])
        ->assertStatus(422)
        ->assertJsonPath('code', 'invalid_code');

    expect(Attempt::withoutGlobalScopes()->find($this->b['attempt']->id)->device_id)->toBeNull();

    // B's candidate logs in on B's PC; the token does not work through A's PC.
    $tokenB = desktopApi('POST', 'exam/login', ['code' => $this->b['student']->code], $this->b['deviceToken'])->assertOk()->json('token');
    desktopApi('GET', 'exam', [], $this->a['deviceToken'], $tokenB)->assertStatus(401);
    desktopApi('GET', 'exam', [], $this->b['deviceToken'], $tokenB)->assertOk();

    // A's own candidate still logs in on A's PC.
    desktopApi('POST', 'exam/login', ['code' => $this->a['student']->code], $this->a['deviceToken'])->assertOk();
});

test('each PC gets its own center\'s config, password and background', function () {
    desktopApi('GET', 'device/config', [], $this->b['deviceToken'])->assertOk()
        ->assertJsonPath('center.code', 'BETA')
        ->assertJsonPath('center.name', 'Center BETA')
        ->assertJsonPath('exit_password_offline', centerSettings($this->adminB)->exit_password_offline);

    desktopApi('POST', 'device/unlock', ['password' => 'alpha-pass'], $this->b['deviceToken'])->assertStatus(422);
    desktopApi('POST', 'device/unlock', ['password' => 'beta-pass'], $this->b['deviceToken'])->assertOk();

    desktopApi('GET', 'device/background', [], $this->b['deviceToken'])->assertNotFound();
});

test('the SuperAdmin works as Mynine by default, can switch to B and passes every check', function () {
    $super = makeSuperAdmin(); // = A's admin (the Mynine center)
    expect($super->id)->toBe($this->adminA->id);

    $this->actingAs($super)->get(route('mock.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('mock.data', fn ($rows) => collect($rows)->pluck('id')->all() === [$this->a['mock']->id]));

    $this->actingAs($super)->get(route('centers.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->component('centers/index')->has('centers', 2)->where('activeCenterId', $super->id));

    $this->actingAs($super)->post(route('centers.switch', $this->adminB))->assertRedirect(route('mock.index'));

    $this->actingAs($super)->get(route('mock.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->where('mock.data', fn ($rows) => collect($rows)->pluck('id')->all() === [$this->b['mock']->id])
            ->where('auth.center.code', 'BETA'));
    $this->actingAs($super)->get(route('mock.show', $this->b['mock']))->assertOk();
    $this->actingAs($super)->get(route('desktop.devices.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('devices', fn ($rows) => collect($rows)->pluck('id')->all() === [$this->b['device']->id]));

    // A mock created while switched belongs to B.
    $this->actingAs($super)->post(route('mock.store'), [
        'name' => 'Made by super', 'started_at' => now()->addDay()->format('Y-m-d H:i'), 'finished_at' => now()->addDay()->addHours(3)->format('Y-m-d H:i'),
        'modules' => [$this->b['exam']['listening']->id],
    ])->assertRedirect();
    expect(Mock::withoutGlobalScopes()->where('name', 'Made by super')->value('owner_id'))->toBe($this->adminB->id);

    // Back to Mynine.
    $this->actingAs($super)->post(route('centers.switch', $super));
    $this->actingAs($super)->get(route('mock.index'))
        ->assertInertia(fn (Assert $page) => $page->where('mock.data', fn ($rows) => collect($rows)->pluck('id')->all() === [$this->a['mock']->id]));
});

test('a center admin cannot use another center\'s Mock Bank modules in a mock', function () {
    $this->actingAs($this->adminA)->post(route('mock.store'), [
        'name' => 'Steal modules', 'started_at' => now()->addDay()->format('Y-m-d H:i'), 'finished_at' => now()->addDay()->addHours(3)->format('Y-m-d H:i'),
        'modules' => [$this->b['exam']['listening']->id],
    ])->assertSessionHasErrors('modules');

    expect(Mock::withoutGlobalScopes()->where('name', 'Steal modules')->exists())->toBeFalse();
});

test('candidate codes stay unique across centers', function () {
    $this->actingAs($this->adminA)->post(route('mock-student.store'), [
        'mock_id' => $this->a['mock']->id, 'text' => "Vali ; 901112233\nSoli ; 901112244",
    ])->assertSessionHasNoErrors();

    $codes = MockStudent::withoutGlobalScopes()->pluck('code');
    expect($codes->unique()->count())->toBe($codes->count());
});
