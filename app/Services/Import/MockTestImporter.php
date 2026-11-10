<?php

namespace App\Services\Import;

use App\Models\Image;
use App\Models\Option;
use App\Models\Part;
use App\Models\Question;
use App\Models\QuestionType;
use App\Models\Section;
use App\Models\TestType;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use RuntimeException;
use Throwable;

/**
 * Writes normalised parts (MockImportNormalizer, WritingPaperNormalizer) into a module (test_types row).
 *
 * A part may carry an "image" (Writing Task 1 picture in a temporary file): it is stored on the public
 * disk under images/imports/ (served as /storage/images/imports/…, like other exam pictures, so the desktop
 * app prefetches it), WritingPaperNormalizer::IMAGE_TOKEN in the part / section HTML becomes the <img> tag,
 * and an images row links it to the part.
 */
class MockTestImporter
{
    public const IMAGE_DISK = 'public';

    public const IMAGE_DIRECTORY = 'images/imports';

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
        $stored = [];
        $replaced = [];

        try {
            $counts = DB::transaction(function () use ($testType, $parts, $replace, $types, &$stored, &$replaced) {
                if ($replace) {
                    $old = Part::where('test_type_id', $testType->id)->get();
                    $replaced = Image::whereIn('part_id', $old->pluck('id'))->pluck('image_path')
                        ->filter(fn ($path) => str_starts_with((string) $path, self::IMAGE_DIRECTORY.'/'))->all();
                    $old->each->delete();
                }

                return $this->write($testType, $parts, $types, $stored);
            });
        } catch (Throwable $e) {
            Storage::disk(self::IMAGE_DISK)->delete($stored);

            throw $e;
        }

        // Pictures of replaced imports are only removed once the new content is committed.
        Storage::disk(self::IMAGE_DISK)->delete($replaced);
        foreach ($parts as $partData) {
            if (! empty($partData['image']['path'])) {
                @unlink($partData['image']['path']);
            }
        }

        return $counts;
    }

    /**
     * @param  array<int, array<string, mixed>>  $parts
     * @param  Collection<string, int>  $types
     * @param  array<int, string>  $stored  public-disk paths written (for clean-up after a failure)
     * @return array{parts: int, questions: int}
     */
    private function write(TestType $testType, array $parts, $types, array &$stored): array
    {
        $questionCount = 0;

        foreach ($parts as $partData) {
            $picture = $this->storeImage($partData['image'] ?? null);
            if ($picture) {
                $stored[] = $picture['path'];
            }
            $html = fn (?string $value) => $value === null ? null
                : str_replace(WritingPaperNormalizer::IMAGE_TOKEN, $picture['tag'] ?? '', $value);

            $part = Part::create(array_filter([
                'test_type_id' => $testType->id,
                'name' => $partData['name'],
                'textarea' => $partData['textarea'] !== '' ? $html($partData['textarea']) : null,
                'minute' => $partData['minute'] ?? null,
            ], fn ($value) => $value !== null));

            if ($picture) {
                Image::create(['part_id' => $part->id, 'image_path' => $picture['path']]);
            }

            foreach ($partData['sections'] as $sectionData) {
                $typeId = $types->get($sectionData['question_type'])
                    ?? throw new RuntimeException("Question type {$sectionData['question_type']} is not set up (run QuestionTypeSeeder).");

                $section = Section::create([
                    'part_id' => $part->id,
                    'question_type_id' => $typeId,
                    'textarea' => $html($sectionData['textarea']),
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
    }

    /**
     * Copy a picture from its temporary file to the public disk.
     *
     * @param  array<string, mixed>|null  $image  {path, extension, alt, width, height}
     * @return array{path: string, tag: string}|null
     */
    private function storeImage(?array $image): ?array
    {
        $source = (string) ($image['path'] ?? '');
        if ($source === '' || ! is_file($source)) {
            return null;
        }

        $extension = in_array($image['extension'] ?? '', ['png', 'jpg', 'jpeg'], true) ? $image['extension'] : 'png';
        $path = self::IMAGE_DIRECTORY.'/'.Str::uuid().'.'.$extension;
        Storage::disk(self::IMAGE_DISK)->put($path, (string) file_get_contents($source));

        $alt = e((string) ($image['alt'] ?? ''));

        return [
            'path' => $path,
            'tag' => '<p><img src="/storage/'.$path.'" alt="'.$alt.'" style="max-width: 100%; height: auto;"></p>',
        ];
    }
}
