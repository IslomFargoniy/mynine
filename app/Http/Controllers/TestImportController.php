<?php

namespace App\Http\Controllers;

use App\Models\AiUsageLog;
use App\Models\Option;
use App\Models\Part;
use App\Models\Question;
use App\Models\QuestionType;
use App\Models\Section;
use App\Services\OpenAIService;
use App\Support\AiUsage;
use App\Support\UserFacingError;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class TestImportController extends Controller
{
    protected $openAIService;

    public function __construct(OpenAIService $openAIService)
    {
        $this->openAIService = $openAIService;
    }

    public function importAI(Request $request, Part $part)
    {
        $this->authorize('update', $part);

        $request->validate([
            'text' => 'nullable|string',
            'file' => 'nullable|file|mimes:txt,docx',
        ]);

        $text = $request->input('text') ?? '';

        if ($request->hasFile('file')) {
            $file = $request->file('file');
            $extension = strtolower($file->getClientOriginalExtension());

            if ($extension === 'txt') {
                $text = file_get_contents($file->getRealPath());
            } elseif ($extension === 'docx') {
                $zip = new \ZipArchive;
                if ($zip->open($file->getRealPath()) === true) {
                    if (($index = $zip->locateName('word/document.xml')) !== false) {
                        $xml = $zip->getFromIndex($index);
                        $text = strip_tags($xml);
                    }
                    $zip->close();
                }
            }
        }

        if (empty(trim($text))) {
            throw ValidationException::withMessages([
                'error' => [__('import_input_required')],
            ]);
        }

        try {
            // Text / Word import into a part: logged as "other", for the center that owns the test.
            $parsedData = app(AiUsage::class)->during([
                'owner_id' => $part->test_type?->test?->owner_id,
                'user_id' => $request->user()?->id,
                'purpose' => AiUsageLog::PURPOSE_OTHER,
            ], fn () => $this->openAIService->parseTestDocument($text));

            if (isset($parsedData['error'])) {
                throw new \Exception($parsedData['error']);
            }

            if (empty($parsedData['sections'])) {
                throw new \Exception(__('import_nothing_parsed'));
            }

            DB::beginTransaction();

            $questionTypes = QuestionType::all()->pluck('id', 'type');

            foreach ($parsedData['sections'] as $sectionData) {
                $questionTypeSlug = $sectionData['question_type'] ?? 'multiple_choice';
                $typeId = $questionTypes->get($questionTypeSlug) ?? $questionTypes->first();

                $section = Section::create([
                    'part_id' => $part->id,
                    'question_type_id' => $typeId,
                    'textarea' => $sectionData['textarea'] ?? '',
                    'from_option' => $sectionData['from_option'] ?? null,
                    'to_option' => $sectionData['to_option'] ?? null,
                ]);

                // Import section-level options (e.g. incorrect options for drag_and_drop)
                if (! empty($sectionData['options'])) {
                    foreach ($sectionData['options'] as $optionText) {
                        Option::create([
                            'section_id' => $section->id,
                            'textarea' => $optionText,
                            'is_correct' => false,
                        ]);
                    }
                }

                // Import questions
                if (! empty($sectionData['questions'])) {
                    foreach ($sectionData['questions'] as $qData) {
                        $question = Question::create([
                            'section_id' => $section->id,
                            'textarea' => $qData['textarea'] ?? '',
                            'answer_text' => $qData['answer_text'] ?? null,
                        ]);

                        // Import question-level options (for choices, true/false, etc.)
                        if (! empty($qData['options'])) {
                            foreach ($qData['options'] as $optData) {
                                Option::create([
                                    'question_id' => $question->id,
                                    'textarea' => $optData['textarea'] ?? '',
                                    'is_correct' => (bool) ($optData['is_correct'] ?? false),
                                ]);
                            }
                        }
                    }
                }
            }

            DB::commit();

            return redirect()->route('test-type.show', [
                'test_type' => $part->test_type_id,
                'tab' => $part->id,
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            throw ValidationException::withMessages([
                'error' => [__('import_failed', ['message' => UserFacingError::message($e)])],
            ]);
        }
    }
}
