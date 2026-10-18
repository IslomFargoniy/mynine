<?php

use App\Models\Folder;
use App\Models\Part;
use App\Models\QuestionType;
use App\Models\Section;
use App\Models\Test as ExamTest;
use App\Models\TestType;
use App\Models\Type;
use App\Models\User\User;
use Spatie\Permission\Models\Role;

pest()->extend(Tests\TestCase::class)
    ->use(Illuminate\Foundation\Testing\RefreshDatabase::class)
    ->in('Feature');

pest()->extend(Tests\TestCase::class)->in('Unit');

/*
|--------------------------------------------------------------------------
| Helpers
|--------------------------------------------------------------------------
*/

function seedRoles(): void
{
    foreach (['Admin', 'Teacher', 'Student'] as $role) {
        Role::findOrCreate($role);
    }
}

function makeUser(string $role): User
{
    seedRoles();
    $user = User::factory()->create();
    $user->assignRole($role);

    return $user;
}

function makeType(string $name, int $minute = 60): Type
{
    return Type::firstOrCreate(['name' => $name], ['minute' => $minute]);
}

function makeQuestionType(string $type, string $input = 'text'): QuestionType
{
    return QuestionType::firstOrCreate(['type' => $type], ['name' => ucfirst($type), 'input_type' => $input]);
}

/**
 * Folder -> Test -> TestType -> Part owned by the given teacher.
 *
 * @return array{folder: Folder, test: ExamTest, testType: TestType, part: Part}
 */
function makeTestContent(User $owner, string $typeName = 'Reading', array $testAttributes = []): array
{
    $folder = Folder::create(['name' => 'Folder', 'user_id' => $owner->id, 'active' => 1]);
    $test = ExamTest::create(array_merge(['folder_id' => $folder->id, 'name' => 'Test', 'active' => 1, 'open' => 1], $testAttributes));
    $testType = TestType::create(['test_id' => $test->id, 'type_id' => makeType($typeName)->id]);
    $part = Part::create(['test_type_id' => $testType->id, 'name' => 'Part 1', 'minute' => 20]);

    return compact('folder', 'test', 'testType', 'part');
}

function makeSection(Part $part, string $questionType, string $textarea = 'Section'): Section
{
    return Section::create([
        'part_id' => $part->id,
        'question_type_id' => makeQuestionType($questionType)->id,
        'textarea' => $textarea,
    ]);
}
