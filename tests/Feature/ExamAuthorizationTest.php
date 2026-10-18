<?php

use App\Models\Attempt;
use App\Models\AttemptType;
use App\Models\Mock;
use App\Models\MockStudent;
use App\Models\Option;
use App\Models\Question;

beforeEach(function () {
    $this->teacher = makeUser('Teacher');
    $this->otherTeacher = makeUser('Teacher');
    $this->student = makeUser('Student');
    $this->otherStudent = makeUser('Student');

    ['test' => $this->test, 'testType' => $this->testType, 'part' => $this->part] = makeTestContent($this->teacher);

    $section = makeSection($this->part, 'drag_and_drop', 'The {cave} was {dark}.');
    $this->q1 = Question::create(['section_id' => $section->id, 'order' => 1, 'answer_text' => 'cave']);
    $this->q2 = Question::create(['section_id' => $section->id, 'order' => 2, 'answer_text' => 'dark']);
    Option::create(['section_id' => $section->id, 'textarea' => 'bright', 'is_correct' => 0]);

    $mc = makeSection($this->part, 'multiple_choice', 'Choose');
    $this->mcQuestion = Question::create(['section_id' => $mc->id, 'textarea' => 'Q?']);
    Option::create(['question_id' => $this->mcQuestion->id, 'textarea' => 'A', 'is_correct' => 1]);
    Option::create(['question_id' => $this->mcQuestion->id, 'textarea' => 'B', 'is_correct' => 0]);

    $this->attempt = Attempt::create([
        'user_id' => $this->student->id,
        'test_id' => $this->test->id,
        'started_at' => now(),
    ]);
});

test('a candidate only receives questions without the answer key', function () {
    $response = $this->actingAs($this->student)
        ->getJson(route('practice-part', ['part' => $this->part->id, 'attempt_id' => $this->attempt->id]))
        ->assertOk();

    $json = $response->json('data');
    $payload = json_encode($json);

    expect($payload)->not->toContain('"answer_text"')
        ->and($payload)->not->toContain('"is_correct"');

    $dragSection = collect($json['sections'])->firstWhere('question_type.type', 'drag_and_drop');
    expect(collect($dragSection['drag_options'])->pluck('label')->all())->toBe(['bright', 'cave', 'dark'])
        ->and(collect($dragSection['drag_options'])->pluck('id')->all())->toBe(['d1', 'd2', 'd3']);
});

test('another student cannot open, answer or submit someone else\'s attempt', function () {
    $this->actingAs($this->otherStudent)
        ->getJson(route('practice-part', ['part' => $this->part->id, 'attempt_id' => $this->attempt->id]))
        ->assertForbidden();

    $this->actingAs($this->otherStudent)
        ->postJson(route('attempt-answer.store', ['part_id' => $this->part->id, 'attempt_id' => $this->attempt->id]), [
            'question_id' => $this->q1->id,
            'answer_text' => 'cave',
        ])->assertForbidden();

    $this->actingAs($this->otherStudent)
        ->post(route('practice-attempt-submit', $this->attempt->id))
        ->assertForbidden();

    expect($this->attempt->fresh()->finished_at)->toBeNull();
});

test('submitting an attempt requires POST', function () {
    $this->actingAs($this->student)
        ->get(route('practice-attempt-submit', $this->attempt->id))
        ->assertStatus(405);
});

test('the owner can answer and the stored option records correctness server-side', function () {
    // Create the attempt part first (what the exam room does when a part is opened)
    $this->actingAs($this->student)
        ->getJson(route('practice-part', ['part' => $this->part->id, 'attempt_id' => $this->attempt->id]))
        ->assertOk();

    $correct = Option::where('question_id', $this->mcQuestion->id)->where('is_correct', 1)->first();

    $this->actingAs($this->student)
        ->postJson(route('attempt-answer.store', ['part_id' => $this->part->id, 'attempt_id' => $this->attempt->id]), [
            'question_id' => $this->mcQuestion->id,
            'options' => [$correct->id],
        ])->assertOk()->assertJsonPath('success', true);

    $this->assertDatabaseHas('attempt_answer_options', ['option_id' => $correct->id, 'is_correct' => 1]);
});

test('students cannot set module scores, the owning teacher can', function () {
    $speaking = makeType('Speaking');

    $this->actingAs($this->student)
        ->post(route('attempt-type.store'), ['attempt_id' => $this->attempt->id, 'type_id' => $speaking->id, 'score' => 9])
        ->assertForbidden();

    $this->actingAs($this->otherTeacher)
        ->post(route('attempt-type.store'), ['attempt_id' => $this->attempt->id, 'type_id' => $speaking->id, 'score' => 9])
        ->assertForbidden();

    $this->actingAs($this->teacher)
        ->post(route('attempt-type.store'), ['attempt_id' => $this->attempt->id, 'type_id' => $speaking->id, 'score' => 7.5])
        ->assertRedirect();

    expect(AttemptType::where('attempt_id', $this->attempt->id)->where('type_id', $speaking->id)->value('score'))->toBe(7.5);
});

test('tab-switch violations always increment by exactly one', function () {
    $this->actingAs($this->student)
        ->postJson(route('practice-attempt-violation', $this->attempt->id), ['count' => -50])
        ->assertOk()
        ->assertJsonPath('tab_switch_count', 1);
});

test('content editing is limited to admins and the owning teacher', function () {
    $payload = ['textarea' => 'Edited', 'answer_text' => 'cave'];

    $this->actingAs($this->student)->put(route('question.update', $this->q1->id), $payload)->assertForbidden();
    $this->actingAs($this->otherTeacher)->put(route('question.update', $this->q1->id), $payload)->assertForbidden();
    $this->actingAs($this->teacher)->put(route('question.update', $this->q1->id), $payload)->assertRedirect();

    expect($this->q1->fresh()->textarea)->toBe('Edited');
});

test('attempt results are only visible to the candidate, the owning teacher and admins', function () {
    $this->attempt->finish();

    $this->actingAs($this->otherStudent)->get(route('attempt.show', $this->attempt->id))->assertForbidden();
    $this->actingAs($this->otherTeacher)->get(route('attempt.show', $this->attempt->id))->assertForbidden();
    $this->actingAs($this->student)->get(route('attempt.show', $this->attempt->id))->assertOk();
    $this->actingAs($this->teacher)->get(route('attempt.show', $this->attempt->id))->assertOk();
    $this->actingAs(makeUser('Admin'))->get(route('attempt.show', $this->attempt->id))->assertOk();
});

test('the PDF needs a signed link or permission to view the attempt', function () {
    $this->get(route('attempt.pdf', $this->attempt->id))->assertForbidden();
    $this->actingAs($this->otherStudent)->get(route('attempt.pdf', $this->attempt->id))->assertForbidden();

    $this->get(\Illuminate\Support\Facades\URL::signedRoute('attempt.pdf', ['attempt' => $this->attempt->id], null, false))
        ->assertOk()
        ->assertHeader('Content-Type', 'application/pdf');
});

test('a mock owner can delete an attempt together with its answers', function () {
    $mock = Mock::create([
        'name' => 'Mock', 'test_id' => $this->test->id, 'user_id' => $this->teacher->id, 'slug' => 'mock-1',
        'started_at' => now()->subHour(), 'finished_at' => now()->addHour(), 'active' => 1,
    ]);
    $attempt = Attempt::create(['mock_id' => $mock->id, 'user_id' => $this->student->id, 'test_id' => $this->test->id, 'started_at' => now()]);

    $this->actingAs($this->student)
        ->getJson(route('practice-part', ['part' => $this->part->id, 'attempt_id' => $attempt->id]))->assertOk();
    $this->actingAs($this->student)
        ->postJson(route('attempt-answer.store', ['part_id' => $this->part->id, 'attempt_id' => $attempt->id]), [
            'question_id' => $this->q1->id, 'answer_text' => 'cave',
        ])->assertOk();

    $this->actingAs($this->otherTeacher)->delete(route('attempt.destroy', $attempt->id))->assertForbidden();

    $this->actingAs($this->teacher)->delete(route('attempt.destroy', $attempt->id))->assertRedirect(route('attempt.index'));

    $this->assertDatabaseMissing('attempts', ['id' => $attempt->id]);
    $this->assertDatabaseCount('attempt_answers', 0);
    $this->assertDatabaseCount('attempt_parts', 0);
});

test('a candidate code session is bound to its own attempt', function () {
    $mock = Mock::create([
        'name' => 'Mock', 'test_id' => $this->test->id, 'user_id' => $this->teacher->id, 'slug' => 'mock-2',
        'started_at' => now()->subHour(), 'finished_at' => now()->addHour(), 'active' => 1,
    ]);
    $me = MockStudent::create(['mock_id' => $mock->id, 'name' => 'Me', 'code' => 'MOCK-111111']);
    $other = MockStudent::create(['mock_id' => $mock->id, 'name' => 'Other', 'code' => 'MOCK-222222']);
    $myAttempt = Attempt::create(['mock_id' => $mock->id, 'mock_student_id' => $me->id, 'test_id' => $this->test->id, 'started_at' => now(), 'name' => 'Me']);
    $otherAttempt = Attempt::create(['mock_id' => $mock->id, 'mock_student_id' => $other->id, 'test_id' => $this->test->id, 'started_at' => now(), 'name' => 'Other']);

    $this->withSession(['mock_student_id' => $me->id])
        ->getJson(route('practice-part', ['part' => $this->part->id, 'attempt_id' => $myAttempt->id]))->assertOk();

    $this->withSession(['mock_student_id' => $me->id])
        ->getJson(route('practice-part', ['part' => $this->part->id, 'attempt_id' => $otherAttempt->id]))->assertForbidden();
});
