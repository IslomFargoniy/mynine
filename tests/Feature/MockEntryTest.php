<?php

use App\Models\Attempt;
use App\Models\Mock;
use App\Models\MockStudent;

beforeEach(function () {
    $this->teacher = makeUser('Teacher');
    ['test' => $this->test] = makeTestContent($this->teacher, 'Listening');
});

function makeMock(array $overrides = []): Mock
{
    return Mock::create(array_merge([
        'name' => 'Mock', 'test_id' => test()->test->id, 'user_id' => test()->teacher->id, 'slug' => 'mock-'.uniqid(),
        'started_at' => now()->subHour(), 'finished_at' => now()->addHour(), 'active' => 1,
    ], $overrides));
}

test('a valid candidate code opens the exam and binds the session', function () {
    $mock = makeMock();
    $student = MockStudent::create(['mock_id' => $mock->id, 'name' => 'Ali', 'code' => 'MOCK-123456']);

    $response = $this->post(route('mock-student.enter'), ['code' => 'mock-123456']);

    $attempt = Attempt::where('mock_student_id', $student->id)->firstOrFail();
    $response->assertRedirect(route('practice.index', ['attempt_id' => $attempt->id]));
    $response->assertSessionHas('mock_student_id', $student->id);
    expect($student->fresh()->attended)->toBeTrue();
});

test('codes are rejected outside the mock window or when the mock is inactive', function () {
    $expired = makeMock(['started_at' => now()->subDays(2), 'finished_at' => now()->subDay()]);
    MockStudent::create(['mock_id' => $expired->id, 'name' => 'Late', 'code' => 'MOCK-000001']);
    $this->post(route('mock-student.enter'), ['code' => 'MOCK-000001'])->assertSessionHasErrors('code');

    $inactive = makeMock(['active' => 0]);
    MockStudent::create(['mock_id' => $inactive->id, 'name' => 'Off', 'code' => 'MOCK-000002']);
    $this->post(route('mock-student.enter'), ['code' => 'MOCK-000002'])->assertSessionHasErrors('code');

    $this->post(route('mock-student.enter'), ['code' => 'MOCK-999999'])->assertSessionHasErrors('code');
});

test('candidate code entry is rate limited', function () {
    makeMock();
    for ($i = 0; $i < 10; $i++) {
        $this->post(route('mock-student.enter'), ['code' => 'MOCK-'.str_pad((string) $i, 6, '0', STR_PAD_LEFT)]);
    }

    $this->post(route('mock-student.enter'), ['code' => 'MOCK-123456'])->assertStatus(429);
});

test('students cannot start an attempt on a test that is not open', function () {
    $student = makeUser('Student');
    $this->test->update(['open' => 0]);

    $this->actingAs($student)
        ->post(route('attempt.store'), ['test_id' => $this->test->id])
        ->assertSessionHasErrors('error');

    expect(Attempt::count())->toBe(0);

    $this->test->update(['open' => 1]);
    $this->actingAs($student)->post(route('attempt.store'), ['test_id' => $this->test->id])->assertRedirect();
    expect(Attempt::count())->toBe(1);
});
