<?php

use App\Models\Attempt;
use App\Models\Test as ExamTest;

beforeEach(function () {
    $this->admin = makeUser('Admin');
    $this->exam = makeDesktopExam($this->admin, ['require_desktop' => false]);
});

test('mock bank tests are hidden from practice listings', function () {
    $practice = makeTestContent($this->admin, 'Reading', ['name' => 'Practice One']);
    $student = makeUser('Student');

    $this->actingAs($student)->get(route('all-test.index'))->assertOk()
        ->assertInertia(fn ($page) => $page->where('folder.data', fn ($folders) => collect($folders)->pluck('tests')->flatten(1)->pluck('id')->all() === [$practice['test']->id]));

    $ids = collect($this->getJson(route('landing-page-tests'))->assertOk()->json('data'))->pluck('id')->all();
    expect($ids)->toBe([$practice['test']->id]);
});

test('mock bank tests cannot be started through attempt.store, even when marked open', function () {
    $student = makeUser('Student');
    $this->exam['testL']->update(['open' => 1]);

    $this->actingAs($student)->post(route('attempt.store'), ['test_id' => $this->exam['testL']->id])->assertSessionHasErrors('error');
    $this->actingAs($this->admin)->post(route('attempt.store'), ['test_id' => $this->exam['testL']->id])->assertSessionHasErrors('error');

    expect(Attempt::count())->toBe(0);
});

test('the web candidate entry refuses desktop-only mocks', function () {
    $this->exam['mock']->update(['require_desktop' => true]);

    $this->post(route('mock-student.enter'), ['code' => 'MOCK-100001'])->assertSessionHasErrors('code');
    expect(Attempt::count())->toBe(0);
});

test('web candidates of a module mock may open only the mock\'s modules', function () {
    $this->post(route('mock-student.enter'), ['code' => 'MOCK-100001'])->assertRedirect();

    $attempt = Attempt::firstOrFail();
    expect((int) $attempt->test_id)->toBe((int) $this->exam['testL']->id)
        ->and($attempt->examModules()->pluck('id')->all())->toBe([$this->exam['listening']->id, $this->exam['reading']->id, $this->exam['writing']->id]);

    $session = ['mock_student_id' => $this->exam['student']->id];

    // Reading comes from a different test than attempts.test_id but belongs to the mock.
    $this->withSession($session)
        ->getJson(route('practice-part', ['part' => $this->exam['partR']->id, 'attempt_id' => $attempt->id]))
        ->assertOk();

    $this->withSession($session)
        ->getJson(route('practice-attempt', $attempt->id))
        ->assertOk()
        ->assertJsonCount(3, 'data.test.types');

    $unrelated = makeTestContent($this->admin, 'Reading');
    $this->withSession($session)
        ->getJson(route('practice-part', ['part' => $unrelated['part']->id, 'attempt_id' => $attempt->id]))
        ->assertForbidden();
});

test('tests default to practice purpose and draft bank status', function () {
    $test = makeTestContent($this->admin)['test']->fresh();

    expect($test->purpose)->toBe(ExamTest::PURPOSE_PRACTICE)
        ->and($test->bank_status)->toBe(ExamTest::BANK_DRAFT)
        ->and(ExamTest::mock()->pluck('id')->sort()->values()->all())->toBe(collect([$this->exam['testL']->id, $this->exam['testR']->id, $this->exam['testW']->id])->sort()->values()->all());
});

test('test.show redirects to the folder editor instead of a missing page', function () {
    $admin = makeUser('Admin');
    ['test' => $test] = makeTestContent($admin);

    $this->actingAs($admin)->get(route('test.show', $test))
        ->assertRedirect(route('folder.show', ['folder' => $test->folder_id, 'search' => $test->name]));
});

test('moving a test to practice twice does not fail', function () {
    $admin = makeUser('Admin');
    ['test' => $test] = makeTestContent($admin, 'Reading', ['purpose' => 'mock', 'open' => 0]);

    $this->actingAs($admin)->post(route('mock-bank.to-practice', $test))->assertSessionHas('success');
    $this->actingAs($admin)->post(route('mock-bank.to-practice', $test))->assertSessionHas('success');

    expect($test->fresh()->purpose)->toBe('practice')->and((int) $test->fresh()->open)->toBe(1);
});
