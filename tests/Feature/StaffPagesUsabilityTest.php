<?php

use App\Models\Attempt;
use App\Models\Mock;
use App\Models\MockStudent;
use App\Models\User\User;
use App\Services\ExamService;
use Inertia\Testing\AssertableInertia as Assert;

function plainMock(User $owner, array $attributes = []): Mock
{
    return Mock::create(array_merge([
        'name' => 'Mock '.uniqid(), 'test_id' => null, 'user_id' => $owner->id, 'slug' => 'mock-'.uniqid(),
        'started_at' => now()->subHour(), 'finished_at' => now()->addHours(4), 'active' => 1, 'require_desktop' => true,
    ], $attributes));
}

function startAttempt(MockStudent $student): Attempt
{
    return app(ExamService::class)->findOrCreateMockAttempt($student);
}

test('the mock list date filter includes mocks created on the "to" day', function () {
    $this->travelTo(now()->setTime(15, 30));
    $admin = makeUser('Admin');
    $mock = plainMock($admin);
    $today = now()->toDateString();

    $this->actingAs($admin)->get(route('mock.index', ['from' => $today, 'to' => $today]))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page->has('mock.data', 1)->where('mock.data.0.id', $mock->id));
});

test('mock list page links keep the filters', function () {
    $admin = makeUser('Admin');
    plainMock($admin, ['name' => 'Alpha 1']);
    plainMock($admin, ['name' => 'Alpha 2']);

    $this->actingAs($admin)->get(route('mock.index', ['search' => 'Alpha', 'per_page' => 1]))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->where('mock.total', 2)
            ->where('mock.next_page_url', fn ($url) => str_contains($url, 'search=Alpha') && str_contains($url, 'per_page=1')));
});

test('the attempts list date filter includes attempts of the "to" day', function () {
    $this->travelTo(now()->setTime(16, 0));
    $admin = makeUser('Admin');
    $exam = makeDesktopExam($admin);
    $attempt = startAttempt($exam['student']);
    $today = now()->toDateString();

    $this->actingAs($admin)->get(route('attempt.index', ['from' => $today, 'to' => $today]))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page->has('attempt.data', 1)->where('attempt.data.0.id', $attempt->id));
});

test('the attempts mock filter lists the newest mocks, not the 50 oldest', function () {
    $admin = makeUser('Admin');
    foreach (range(1, 51) as $i) {
        plainMock($admin, ['name' => "Old mock {$i}"]);
    }
    $latest = plainMock($admin, ['name' => 'Today mock']);

    $this->actingAs($admin)->get(route('attempt.index'))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('mocks', fn ($mocks) => collect($mocks)->contains('id', $latest->id)));
});

test('the monitor lists and selects a mock whose candidate is still writing after the mock ended', function () {
    $admin = makeUser('Admin');
    $exam = makeDesktopExam($admin, ['started_at' => now()->subDays(4), 'finished_at' => now()->subDays(3)]);
    startAttempt($exam['student']);
    // Another current mock without running attempts, started later.
    plainMock($admin, ['started_at' => now()->subMinutes(10)]);

    $this->actingAs($admin)->get(route('monitor.index'))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->where('mock.id', $exam['mock']->id)
            ->where('mocks', fn ($mocks) => collect($mocks)->contains('id', $exam['mock']->id))
            ->has('attempts', 1));
});

test('the monitor keeps an older mock opened by id in its dropdown', function () {
    $admin = makeUser('Admin');
    $old = plainMock($admin, ['started_at' => now()->subMonth(), 'finished_at' => now()->subMonth()->addHours(4)]);

    $this->actingAs($admin)->get(route('monitor.index', ['mock_id' => $old->id]))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->where('mock.id', $old->id)
            ->where('mocks', fn ($mocks) => collect($mocks)->contains('id', $old->id)));
});

test('the Speaking page keeps an older mock opened by id in its dropdown', function () {
    $admin = makeUser('Admin');
    $old = plainMock($admin, ['started_at' => now()->subMonths(3), 'finished_at' => now()->subMonths(3)->addHours(4)]);

    $this->actingAs($admin)->get(route('speaking.index', ['mock_id' => $old->id]))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->where('mock.id', $old->id)
            ->where('mocks', fn ($mocks) => collect($mocks)->contains('id', $old->id)));
});

test('the Writing review keeps the filtered mock in its dropdown', function () {
    $admin = makeUser('Admin');
    $mock = plainMock($admin);

    $this->actingAs($admin)->get(route('writing-review.index', ['mock_id' => $mock->id]))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->where('filters.mock_id', $mock->id)
            ->where('mocks', fn ($mocks) => collect($mocks)->contains('id', $mock->id)));
});

test('reception drops a mock filter of another day and lists the day\'s candidates', function () {
    $admin = makeUser('Admin');
    $exam = makeDesktopExam($admin);
    $old = plainMock($admin, ['started_at' => now()->subWeek(), 'finished_at' => now()->subWeek()->addHours(4)]);

    $this->actingAs($admin)->get(route('reception.index', ['mock_id' => $old->id]))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->where('filters.mock_id', null)
            ->has('candidates', 1)
            ->where('candidates.0.code', $exam['student']->code));
});

test('the mock form gets the Speaking start time as server wall-clock time', function () {
    $admin = makeUser('Admin');
    $exam = makeDesktopExam($admin);
    $exam['mock']->forceFill(['speaking_starts_at' => now()->setTime(15, 0)])->save();

    $this->actingAs($admin)->get(route('mock.edit', $exam['mock']))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('mock.speaking_starts_at', now()->format('Y-m-d').' 15:00:00'));
});
