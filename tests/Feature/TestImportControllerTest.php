<?php

use App\Models\Folder;
use App\Models\Part;
use App\Models\QuestionType;
use App\Models\Test as TestModel;
use App\Models\TestType;
use App\Models\Type;
use App\Services\OpenAIService;

test('it imports sections, questions, and options successfully from raw text via AI', function () {
    // 1. Arrange
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

    // Ensure question type exists
    QuestionType::firstOrCreate(
        ['type' => 'multiple_choice'],
        ['name' => 'Multiple Choice', 'input_type' => 'radio']
    );

    $mockData = [
        'sections' => [
            [
                'textarea' => 'Section Instruction 1',
                'question_type' => 'multiple_choice',
                'questions' => [
                    [
                        'textarea' => 'Question 1 description',
                        'options' => [
                            ['textarea' => 'Choice A', 'is_correct' => false],
                            ['textarea' => 'Choice B', 'is_correct' => true],
                        ],
                    ],
                ],
            ],
        ],
    ];

    $this->mock(OpenAIService::class, function ($mock) use ($mockData) {
        $mock->shouldReceive('parseTestDocument')
            ->once()
            ->andReturn($mockData);
    });

    // 2. Act
    $response = $this->actingAs($user)
        ->post(route('part.import-ai', $part->id), [
            'text' => 'Some raw text containing questions',
        ]);

    // 3. Assert
    $response->assertRedirect(route('test-type.show', [
        'test_type' => $part->test_type_id,
        'tab' => $part->id,
    ]));

    $this->assertDatabaseHas('sections', [
        'part_id' => $part->id,
        'textarea' => 'Section Instruction 1',
    ]);

    $this->assertDatabaseHas('questions', [
        'textarea' => 'Question 1 description',
    ]);

    $this->assertDatabaseHas('options', [
        'textarea' => 'Choice B',
        'is_correct' => true,
    ]);
});
