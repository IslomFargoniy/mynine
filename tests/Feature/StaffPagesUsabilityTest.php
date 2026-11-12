<?php

use App\Models\Attempt;
use App\Models\Folder;
use App\Models\Mock;
use App\Models\MockStudent;
use App\Models\Test;
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

test('the mock list date filter is the exam date, "to" day included', function () {
    $this->travelTo(now()->setTime(15, 30));
    $admin = makeUser('Admin');
    // Created last week for an exam today at 18:00: listed.
    $this->travelTo(now()->subWeek());
    $today = plainMock($admin, ['started_at' => now()->addWeek()->setTime(18, 0), 'finished_at' => now()->addWeek()->setTime(22, 0)]);
    $this->travelBack();
    $this->travelTo(now()->setTime(15, 30));
    // Created today for an exam next week: not listed.
    plainMock($admin, ['started_at' => now()->addWeek(), 'finished_at' => now()->addWeek()->addHours(4)]);
    $date = now()->toDateString();

    $this->actingAs($admin)->get(route('mock.index', ['from' => $date, 'to' => $date]))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page->has('mock.data', 1)->where('mock.data.0.id', $today->id));
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

test('the attempts date filter uses the mock\'s exam date, or the attempt date without a mock', function () {
    $this->travelTo(now()->setTime(16, 0));
    $admin = makeUser('Admin');
    $exam = makeDesktopExam($admin);
    $mockAttempt = startAttempt($exam['student']);
    // Attempt of a mock held last week, created (late) today: not listed.
    $old = plainMock($admin, ['started_at' => now()->subWeek(), 'finished_at' => now()->subWeek()->addHours(4)]);
    $oldStudent = MockStudent::create(['mock_id' => $old->id, 'name' => 'Old', 'code' => 'MOCK-200002', 'phone' => '+998901234568']);
    Attempt::create(['name' => 'Old', 'test_id' => $exam['testL']->id, 'mock_id' => $old->id, 'mock_student_id' => $oldStudent->id, 'started_at' => now()]);
    // Practice attempt (no mock) of today: listed.
    $practice = Attempt::create(['name' => 'Practice', 'test_id' => $exam['testL']->id, 'user_id' => $admin->id, 'started_at' => now()]);
    $date = now()->toDateString();

    $this->actingAs($admin)->get(route('attempt.index', ['from' => $date, 'to' => $date]))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->has('attempt.data', 2)
            ->where('attempt.data', fn ($rows) => collect($rows)->pluck('id')->sort()->values()->all() === collect([$mockAttempt->id, $practice->id])->sort()->values()->all()));
});

test('test and folder filter dropdowns list the newest first and keep the filtered one', function () {
    $admin = makeUser('Admin');
    $content = makeTestContent($admin);
    foreach (range(1, 51) as $i) {
        Test::create(['folder_id' => $content['folder']->id, 'name' => "Test {$i}", 'active' => 1, 'open' => 1]);
        Folder::create(['name' => "Folder {$i}", 'user_id' => $admin->id, 'active' => 1]);
    }
    $newestTest = Test::query()->max('id');
    $oldTest = $content['test']->id;
    $oldFolder = $content['folder']->id;

    foreach (['mock.index', 'attempt.index'] as $route) {
        $this->actingAs($admin)->get(route($route, ['test_id' => $oldTest, 'folder_id' => $oldFolder]))
            ->assertOk()
            ->assertInertia(fn (Assert $page) => $page
                ->where('tests.0.id', $newestTest)
                ->where('tests', fn ($tests) => collect($tests)->contains('id', $oldTest))
                ->where('folders', fn ($folders) => collect($folders)->contains('id', $oldFolder)));
    }
});

test('user and test bank date filters include the "to" day', function () {
    $this->travelTo(now()->setTime(14, 0));
    $admin = makeUser('SuperAdmin');
    $student = makeUser('Student');
    $folder = Folder::create(['name' => 'Today folder', 'user_id' => $admin->id, 'active' => 1]);
    $date = now()->toDateString();

    $this->actingAs($admin)->get(route('user.index', ['from' => $date, 'to' => $date]))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('user.data', fn ($rows) => collect($rows)->contains('id', $student->id)));

    $this->actingAs($admin)->get(route('test-bank.index', ['from' => $date, 'to' => $date]))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('folder.data', fn ($rows) => collect($rows)->contains('id', $folder->id)));
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

test('reception picks the running mock when the day has several', function () {
    $this->travelTo(now()->setTime(12, 0));
    $admin = makeUser('Admin');
    plainMock($admin, ['started_at' => now()->setTime(8, 0), 'finished_at' => now()->setTime(11, 0)]);
    $running = plainMock($admin, ['started_at' => now()->setTime(11, 30), 'finished_at' => now()->setTime(15, 0)]);
    plainMock($admin, ['started_at' => now()->setTime(16, 0), 'finished_at' => now()->setTime(19, 0)]);

    $this->actingAs($admin)->get(route('reception.index'))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page->has('mocks', 3)->where('filters.mock_id', $running->id));

    $this->actingAs($admin)->get(route('reception.index', ['mock_id' => 'all']))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('filters.mock_id', 'all'));
});

test('reception picks the day\'s next mock when none is running', function () {
    $this->travelTo(now()->setTime(12, 0));
    $admin = makeUser('Admin');
    plainMock($admin, ['started_at' => now()->setTime(8, 0), 'finished_at' => now()->setTime(11, 0)]);
    $next = plainMock($admin, ['started_at' => now()->setTime(14, 0), 'finished_at' => now()->setTime(18, 0)]);
    plainMock($admin, ['started_at' => now()->setTime(16, 0), 'finished_at' => now()->setTime(19, 0)]);

    $this->actingAs($admin)->get(route('reception.index'))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('filters.mock_id', $next->id));
});

test('Speaking and Monitor default to today\'s mock over an older open mock', function () {
    $this->travelTo(now()->setTime(9, 0));
    $admin = makeUser('Admin');
    plainMock($admin, ['started_at' => now()->subMonths(2), 'finished_at' => now()->addMonth()]);
    $today = plainMock($admin, ['started_at' => now()->setTime(14, 0), 'finished_at' => now()->setTime(18, 0)]);

    foreach (['speaking.index', 'monitor.index'] as $route) {
        $this->actingAs($admin)->get(route($route))
            ->assertOk()
            ->assertInertia(fn (Assert $page) => $page->where('mock.id', $today->id));
    }
});
