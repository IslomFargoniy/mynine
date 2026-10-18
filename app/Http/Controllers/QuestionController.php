<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreQuestionRequest;
use App\Http\Requests\UpdateQuestionRequest;
use App\Models\Question;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class QuestionController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        //
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreQuestionRequest $request)
    {
        $this->authorize('update', \App\Models\Section::findOrFail($request->section_id));

        try {
            $data = $request->validated();

            DB::beginTransaction();
            // ✅ Create the Question
            $question = Question::create([
                'section_id' => $data['section_id'],
                'textarea' => $data['textarea'],
                'answer_text' => $data['answer_text'],
            ]);

            // ✅ Save options if provided
            if (! empty($data['options'])) {
                foreach ($data['options'] as $option) {
                    $question->options()->create([
                        'textarea' => $option['textarea'],
                        'is_correct' => $option['is_correct'] ? 1 : 0,
                    ]);
                }
            }

            DB::commit();

            return back()->with('success', __('updated_successfully'));
        } catch (\Exception $e) {
            throw ValidationException::withMessages([
                'error' => [$e->getMessage()],
            ]);
        }
    }

    /**
     * Display the specified resource.
     */
    public function show(Question $question)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Question $question)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateQuestionRequest $request, Question $question)
    {
        $this->authorize('update', $question);

        try {
            $data = $request->validated();

            DB::beginTransaction();

            $question->update([
                'textarea' => $data['textarea'],
                'answer_text' => $data['answer_text'] ?? null,
            ]);

            if (array_key_exists('options', $data) && is_array($data['options'])) {
                $existingOptions = $question->options()->get()->keyBy('id');
                $keptIds = [];

                foreach ($data['options'] as $optData) {
                    if (! isset($optData['textarea']) || trim($optData['textarea']) === '') {
                        continue;
                    }

                    $optId = isset($optData['id']) ? (int) $optData['id'] : null;
                    $isCorrect = ! empty($optData['is_correct']) ? 1 : 0;

                    if ($optId && $existingOptions->has($optId)) {
                        $existingOption = $existingOptions->get($optId);
                        $existingOption->update([
                            'textarea' => $optData['textarea'],
                            'is_correct' => $isCorrect,
                        ]);
                        $keptIds[] = $optId;
                    } else {
                        $newOption = $question->options()->create([
                            'textarea' => $optData['textarea'],
                            'is_correct' => $isCorrect,
                        ]);
                        $keptIds[] = $newOption->id;
                    }
                }

                // Remove options that were deleted in UI, if they have no attempt_answer_options references
                foreach ($existingOptions as $optId => $oldOption) {
                    if (! in_array($optId, $keptIds)) {
                        if (! $oldOption->attempt_answer_options()->exists()) {
                            $oldOption->delete();
                        } else {
                            $oldOption->update(['is_correct' => 0]);
                        }
                    }
                }
            }

            DB::commit();

            return back()->with('success', __('updated_successfully'));

        } catch (\Exception $e) {
            DB::rollBack();
            throw ValidationException::withMessages([
                'error' => [$e->getMessage()],
            ]);
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Question $question)
    {
        $this->authorize('delete', $question);

        $test = $question->section?->part?->test_type?->test;
        if ($test && ($test->attempts()->exists() || $test->mocks()->whereHas('attempts')->exists())) {
            throw ValidationException::withMessages([
                'error' => [__('test_has_attempts')],
            ]);
        }

        try {
            $question->delete();

            return back()->with('success', __('deleted_successfully'));
        } catch (\Exception $e) {
            // Proper Inertia error response
            throw ValidationException::withMessages([
                'error' => [$e->getMessage()],
            ]);
        }
    }
}
