<?php

use App\Models\Folder;
use App\Models\Option;
use App\Models\Part;
use App\Models\Question;
use App\Models\QuestionType;
use App\Models\Section;
use App\Models\Test as TestModel;
use App\Models\TestType;
use App\Models\Type;

test('it automatically unchecks other options for singular choice question types on update', function () {
    $user = makeUser('Teacher');

    $folder = Folder::create(['name' => 'Test Folder', 'user_id' => $user->id]);
    $test = TestModel::create([
        'folder_id' => $folder->id,
        'name' => 'Test Title',
    ]);
    $type = Type::create([
        'name' => 'Reading',
        'minute' => 60,
    ]);
    $testType = TestType::create([
        'test_id' => $test->id,
        'type_id' => $type->id,
    ]);
    $part = Part::create([
        'test_type_id' => $testType->id,
        'name' => 'Part 1',
    ]);

    $qType = QuestionType::create([
        'type' => 'true_false',
        'name' => 'True / False',
        'input_type' => 'radio',
    ]);

    $section = Section::create([
        'part_id' => $part->id,
        'question_type_id' => $qType->id,
        'textarea' => 'Section Instruction 1',
    ]);

    $question = Question::create([
        'section_id' => $section->id,
        'textarea' => 'Is this true?',
    ]);

    $opt1 = Option::create([
        'question_id' => $question->id,
        'textarea' => 'True',
        'is_correct' => true,
    ]);

    $opt2 = Option::create([
        'question_id' => $question->id,
        'textarea' => 'False',
        'is_correct' => false,
    ]);

    // Update opt2 to be the correct answer
    $response = $this->actingAs($user)
        ->put(route('option.update', $opt2->id), [
            'textarea' => 'False',
            'is_correct' => true,
        ]);

    $response->assertRedirect();

    // Assert opt2 is correct, and opt1 was automatically unchecked
    expect($opt2->fresh()->is_correct)->toBeTrue();
    expect($opt1->fresh()->is_correct)->toBeFalse();
});
