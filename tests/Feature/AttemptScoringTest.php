<?php

use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\AttemptPart;
use App\Models\AttemptType;
use App\Models\Option;
use App\Models\Question;

test('is_correct_count accepts alternative answers and number formatting', function () {
    $teacher = makeUser('Teacher');
    ['test' => $test, 'testType' => $testType, 'part' => $part] = makeTestContent($teacher, 'Listening');
    $section = makeSection($part, 'fill_blank');

    $q1 = Question::create(['section_id' => $section->id, 'textarea' => '1', 'answer_text' => 'colour / color']);
    $q2 = Question::create(['section_id' => $section->id, 'textarea' => '2', 'answer_text' => '14,000']);
    $q3 = Question::create(['section_id' => $section->id, 'textarea' => '3', 'answer_text' => 'Monday']);

    $mc = makeSection($part, 'multiple_response');
    $q4 = Question::create(['section_id' => $mc->id, 'textarea' => '4-5']);
    $a = Option::create(['question_id' => $q4->id, 'textarea' => 'A', 'is_correct' => 1]);
    $b = Option::create(['question_id' => $q4->id, 'textarea' => 'B', 'is_correct' => 1]);
    $c = Option::create(['question_id' => $q4->id, 'textarea' => 'C', 'is_correct' => 0]);

    $student = makeUser('Student');
    $attempt = Attempt::create(['user_id' => $student->id, 'test_id' => $test->id, 'started_at' => now()]);
    $attemptPart = AttemptPart::create(['attempt_id' => $attempt->id, 'part_id' => $part->id, 'started_at' => now()]);
    $attemptType = AttemptType::create(['attempt_id' => $attempt->id, 'type_id' => $testType->type_id, 'started_at' => now()]);

    AttemptAnswer::create(['attempt_part_id' => $attemptPart->id, 'question_id' => $q1->id, 'answer_text' => ' Color ']);
    AttemptAnswer::create(['attempt_part_id' => $attemptPart->id, 'question_id' => $q2->id, 'answer_text' => '14000']);
    AttemptAnswer::create(['attempt_part_id' => $attemptPart->id, 'question_id' => $q3->id, 'answer_text' => 'Tuesday']);
    $answer4 = AttemptAnswer::create(['attempt_part_id' => $attemptPart->id, 'question_id' => $q4->id]);
    $answer4->attempt_answer_options()->create(['option_id' => $a->id, 'is_correct' => 1]);
    $answer4->attempt_answer_options()->create(['option_id' => $c->id, 'is_correct' => 0]);

    expect($attemptType->recalculateIsCorrectCount())->toBe(3.0);
});

test('writing modules sum the essay band scores instead of counting answers', function () {
    $teacher = makeUser('Teacher');
    ['test' => $test, 'testType' => $testType, 'part' => $part] = makeTestContent($teacher, 'Writing');
    $section = makeSection($part, 'essay');
    $task1 = Question::create(['section_id' => $section->id, 'textarea' => 'Task 1']);
    $task2 = Question::create(['section_id' => $section->id, 'textarea' => 'Task 2']);

    $student = makeUser('Student');
    $attempt = Attempt::create(['user_id' => $student->id, 'test_id' => $test->id, 'started_at' => now()]);
    $attemptPart = AttemptPart::create(['attempt_id' => $attempt->id, 'part_id' => $part->id, 'started_at' => now()]);
    $attemptType = AttemptType::create(['attempt_id' => $attempt->id, 'type_id' => $testType->type_id, 'started_at' => now()]);

    AttemptAnswer::create(['attempt_part_id' => $attemptPart->id, 'question_id' => $task1->id, 'answer_text' => str_repeat('word ', 60), 'score' => 6]);
    AttemptAnswer::create(['attempt_part_id' => $attemptPart->id, 'question_id' => $task2->id, 'answer_text' => str_repeat('word ', 60), 'score' => 7]);

    expect($attemptType->recalculateIsCorrectCount())->toBe(13.0);
});
