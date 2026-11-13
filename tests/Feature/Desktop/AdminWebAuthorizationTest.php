<?php

use App\Models\Attempt;
use App\Models\AttemptType;
use App\Models\Device;

/*
| Authorization of every web route added for the mock-exam system (Admin / Reception / Student / guest).
| Rules: docs/desktop/ARCHITECTURE.md role matrix.
*/

beforeEach(function () {
    $this->admin = makeUser('Admin');
    $this->exam = makeDesktopExam($this->admin);
    $this->attempt = Attempt::create([
        'name' => 'Ali Valiyev', 'mock_id' => $this->exam['mock']->id, 'mock_student_id' => $this->exam['student']->id,
        'test_id' => $this->exam['testL']->id, 'started_at' => now(),
    ]);
    $this->writingType = AttemptType::create([
        'attempt_id' => $this->attempt->id, 'type_id' => $this->exam['writingType']->id, 'is_submitted' => true,
        'started_at' => now(), 'finished_at' => now(),
    ]);
    $this->device = Device::factory()->create();
});

/**
 * [method, route name, parameters (resolved against the test case), allowed for Reception].
 *
 * @return array<string, array{0: string, 1: string, 2: Closure, 3: bool}>
 */
function adminWebRoutes(): array
{
    $mock = fn () => ['mock' => test()->exam['mock']->id];
    $student = fn () => ['mockStudent' => test()->exam['student']->id];
    $attempt = fn () => ['attempt' => test()->attempt->id];
    $test = fn () => ['test' => test()->exam['testL']->id];
    $device = fn () => ['device' => test()->device->id];
    $none = fn () => [];

    return [
        // Admin only
        'mock bank' => ['get', 'mock-bank.index', $none, false],
        'mock bank status' => ['post', 'mock-bank.status', $test, false],
        'mock bank to practice' => ['post', 'mock-bank.to-practice', $test, false],
        'mock create' => ['get', 'mock.create', $none, false],
        'mock edit' => ['get', 'mock.edit', $mock, false],
        'mock store' => ['post', 'mock.store', $none, false],
        'mock update' => ['put', 'mock.update', $mock, false],
        'candidate delete' => ['delete', 'mock-student.destroy', $student, false],
        'speaking page' => ['get', 'speaking.index', $none, false],
        'speaking auto assign' => ['post', 'speaking.auto-assign', $mock, false],
        'speaking slot' => ['post', 'speaking.slot', $student, false],
        'speaking score' => ['post', 'speaking.score', $student, false],
        'writing review' => ['get', 'writing-review.index', $none, false],
        'writing confirm' => ['post', 'writing-review.confirm', fn () => ['attemptType' => test()->writingType->id], false],
        'devices' => ['get', 'desktop.devices.index', $none, false],
        'device approve' => ['post', 'desktop.devices.approve', $device, false],
        'device block' => ['post', 'desktop.devices.block', $device, false],
        'device unblock' => ['post', 'desktop.devices.unblock', $device, false],
        'device rename' => ['patch', 'desktop.devices.update', $device, false],
        'device delete' => ['delete', 'desktop.devices.destroy', $device, false],
        'desktop settings' => ['get', 'desktop.settings.index', $none, false],
        'exit password' => ['post', 'desktop.settings.exit-password', $none, false],
        'monitor extra time' => ['post', 'monitor.extra-time', $attempt, false],
        'monitor pause' => ['post', 'monitor.pause', $attempt, false],
        'monitor resume' => ['post', 'monitor.resume', $attempt, false],
        'monitor force submit' => ['post', 'monitor.force-submit', $attempt, false],
        // Admin + Reception
        'reception' => ['get', 'reception.index', $none, true],
        'monitor' => ['get', 'monitor.index', $none, true],
        'monitor unlock' => ['post', 'monitor.unlock', $attempt, true],
        'candidates store' => ['post', 'mock-student.store', $none, true],
        'repeat check' => ['post', 'mock-student.check-repeats', $none, true],
        'code cards' => ['get', 'mock.code-cards', $mock, true],
        'check in' => ['post', 'reception.check-in', $student, true],
        'deliver' => ['post', 'reception.deliver', $student, true],
        'result sheets' => ['get', 'reception.result-sheets', $none, true],
    ];
}

test('guests are sent to the login page', function (string $method, string $name, Closure $params) {
    $this->{$method}(route($name, $params()))->assertRedirect(route('login'));
})->with(adminWebRoutes());

test('students are forbidden everywhere', function (string $method, string $name, Closure $params) {
    $this->actingAs(makeUser('Student'))->{$method}(route($name, $params()))->assertForbidden();
})->with(adminWebRoutes());

test('reception reaches only the reception, monitor-view, unlock and candidate routes', function (string $method, string $name, Closure $params, bool $receptionAllowed) {
    $response = $this->actingAs(makeUser('Reception'))->{$method}(route($name, $params()));

    $receptionAllowed
        ? expect($response->status())->not->toBe(403)
        : $response->assertForbidden();
})->with(adminWebRoutes());

test('admins reach every page', function (string $name, array $params = []) {
    $this->actingAs($this->admin)->get(route($name, $params))->assertOk();
})->with([
    ['mock-bank.index'], ['mock.create'], ['speaking.index'], ['writing-review.index'], ['desktop.devices.index'],
    ['reception.index'], ['monitor.index'],
]);

test('the old desktop settings page opens the center password dialog on the Exam PCs page', function () {
    $this->actingAs($this->admin)->get(route('desktop.settings.index'))
        ->assertRedirect(route('desktop.devices.index', ['settings' => 1]));
});

test('the Exam PCs page carries the center password status', function () {
    $this->actingAs($this->admin)->get(route('desktop.devices.index'))->assertOk()
        ->assertInertia(fn ($page) => $page->where('centerPassword.set', false)->where('centerPassword.updatedAt', null));

    centerSettings()->setExitPassword('secret12');

    $this->actingAs($this->admin)->get(route('desktop.devices.index'))->assertOk()
        ->assertInertia(fn ($page) => $page->where('centerPassword.set', true)->where('centerPassword.updatedAt', fn ($v) => is_string($v)));
});

test('admins open the mock edit page and the code cards', function () {
    $this->actingAs($this->admin)->get(route('mock.edit', $this->exam['mock']))->assertOk()->assertInertia(fn ($page) => $page->component('mock/form'));
    $this->actingAs($this->admin)->get(route('mock.code-cards', $this->exam['mock']))->assertOk()->assertHeader('Content-Type', 'application/pdf');
});

test('the mock modal loads the form as JSON; saving an edit there stays on the page', function () {
    $mock = $this->exam['mock'];

    $this->actingAs($this->admin)->getJson(route('mock.create'))->assertOk()
        ->assertJsonPath('mock', null)->assertJsonStructure(['modules', 'autoPick', 'reuseDays', 'modulesLocked']);
    $this->actingAs($this->admin)->getJson(route('mock.edit', $mock))->assertOk()
        ->assertJsonPath('mock.id', $mock->id)->assertJsonStructure(['modules', 'autoPick', 'reuseDays']);

    $payload = [
        'name' => 'Renamed in modal', 'started_at' => now()->addDay()->format('Y-m-d H:i'), 'finished_at' => now()->addDay()->addHours(4)->format('Y-m-d H:i'),
        'modules' => $mock->modules()->pluck('test_type_id')->all(), 'stay' => 1,
    ];
    $this->actingAs($this->admin)->from(route('mock.index'))->put(route('mock.update', $mock), $payload)
        ->assertSessionHasNoErrors()->assertRedirect(route('mock.index'));
    expect($mock->fresh()->name)->toBe('Renamed in modal');

    // Other centers' mocks stay hidden from the JSON too.
    $status = $this->actingAs(makeCenter('OTHER'))->getJson(route('mock.edit', $mock))->status();
    expect($status)->toBeIn([403, 404]);
});

test('reception pages never carry answer keys', function () {
    $reception = makeUser('Reception');

    foreach (['reception.index', 'monitor.index'] as $name) {
        $props = $this->actingAs($reception)->get(route($name))->assertOk()->viewData('page')['props'];
        unset($props['auth'], $props['ziggy']);
        assertNoAnswerKeys(json_decode(json_encode($props), true));
    }
});

test('reception lands on the reception desk after login and from the dashboard', function () {
    $reception = makeUser('Reception');

    $this->post(route('login'), ['email_or_phone' => $reception->email, 'password' => 'password'])
        ->assertRedirect(route('reception.index', absolute: false));

    $this->actingAs($reception)->get(route('dashboard'))->assertRedirect(route('reception.index'));
});
