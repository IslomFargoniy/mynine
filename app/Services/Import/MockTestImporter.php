<?php

namespace App\Services\Import;

use App\Models\Option;
use App\Models\Part;
use App\Models\Question;
use App\Models\QuestionType;
use App\Models\Section;
use App\Models\TestType;
use Illuminate\Support\Facades\DB;
use RuntimeException;

/**
 * Writes normalised parts (MockImportNormalizer) into a module (test_types row).
 */
class MockTestImporter
{
    /**
     * Why the module cannot receive imported parts, or null when it can.
     */
    public function refusal(TestType $testType, bool $replace): ?string
    {
        $test = $testType->test;
        if ($test && ($test->attempts()->exists() || $test->mocks()->whereHas('attempts')->exists())) {
            return 'The test already has attempts; its content cannot be replaced.';
        }

        if (! $replace && Part::withoutEagerLoads()->where('test_type_id', $testType->id)->exists()) {
            return 'The module already has parts. Tick "Replace existing parts" to overwrite them.';
        }

        return null;
    }

    /**
     * @param  array<int, array<string, mixed>>  $parts
     * @return array{parts: int, questions: int}
     */
    public function import(TestType $testType, array $parts, bool $replace): array
    {
        if ($reason = $this->refusal($testType, $replace)) {
            throw new RuntimeException($reason);
        }

        $types = QuestionType::query()->pluck('id', 'type');

        return DB::transaction(function () use ($testType, $parts, $replace, $types) {
            if ($replace) {
                Part::where('test_type_id', $testType->id)->get()->each->delete();
            }

            $questionCount = 0;

            foreach ($parts as $partData) {
                $part = Part::create([
                    'test_type_id' => $testType->id,
                    'name' => $partData['name'],
                    'textarea' => $partData['textarea'] !== '' ? $partData['textarea'] : null,
                ]);

                foreach ($partData['sections'] as $sectionData) {
                    $typeId = $types->get($sectionData['question_type'])
                        ?? throw new RuntimeException("Question type {$sectionData['question_type']} is not set up (run QuestionTypeSeeder).");

                    $section = Section::create([
                        'part_id' => $part->id,
                        'question_type_id' => $typeId,
                        'textarea' => $sectionData['textarea'],
                        'from_option' => $sectionData['from_option'],
                        'to_option' => $sectionData['to_option'],
                    ]);

                    foreach ($sectionData['options'] as $text) {
                        Option::create(['section_id' => $section->id, 'textarea' => $text, 'is_correct' => false]);
                    }

                    foreach ($sectionData['questions'] as $questionData) {
                        $question = Question::create([
                            'section_id' => $section->id,
                            'order' => $questionData['order'] ?? null,
                            'textarea' => $questionData['textarea'],
                            'answer_text' => $questionData['answer_text'],
                        ]);
                        // Count question NUMBERS: a "choose TWO" question covers as many numbers as it has
                        // correct options (same rule as the exam payload and the readiness check).
                        $options = collect($questionData['options']);
                        $questionCount += $options->isEmpty() ? 1 : max(1, $options->where('is_correct', true)->count());

                        foreach ($questionData['options'] as $optionData) {
                            Option::create([
                                'question_id' => $question->id,
                                'textarea' => $optionData['textarea'],
                                'is_correct' => (bool) $optionData['is_correct'],
                            ]);
                        }
                    }
                }
            }

            return ['parts' => count($parts), 'questions' => $questionCount];
        });
    }
}
