<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreOptionRequest;
use App\Http\Requests\UpdateOptionRequest;
use App\Models\Option;
use Illuminate\Validation\ValidationException;

class OptionController extends Controller
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
    public function store(StoreOptionRequest $request)
    {
        $parent = $request->question_id
            ? \App\Models\Question::findOrFail($request->question_id)
            : \App\Models\Section::findOrFail($request->section_id);
        $this->authorize('update', $parent);

        try {
            $validated = $request->validated();

            \DB::transaction(function () use ($validated) {
                $option = Option::create($validated);

                if (! empty($validated['is_correct'])) {
                    $question = $option->question;
                    $qType = $question?->section?->question_type?->type;

                    $isSingular = in_array($qType, ['multiple_choice', 'true_false', 'yes_no']);
                    if ($isSingular) {
                        $question->options()
                            ->where('id', '!=', $option->id)
                            ->update(['is_correct' => 0]);
                    }
                }
            });

            return back()->with('success', __('updated_successfully'));
        } catch (\Exception $e) {
            // Proper Inertia error response
            throw ValidationException::withMessages([
                'error' => [$e->getMessage()],
            ]);
        }

    }

    /**
     * Display the specified resource.
     */
    public function show(Option $option)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Option $option)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateOptionRequest $request, Option $option)
    {
        $this->authorize('update', $option);

        try {
            $validated = $request->validated();

            \DB::transaction(function () use ($option, $validated) {
                $option->update($validated);

                if (! empty($validated['is_correct'])) {
                    $question = $option->question;
                    $qType = $question?->section?->question_type?->type;

                    $isSingular = in_array($qType, ['multiple_choice', 'true_false', 'yes_no']);
                    if ($isSingular) {
                        $question->options()
                            ->where('id', '!=', $option->id)
                            ->update(['is_correct' => 0]);
                    }
                }
            });

            return back()->with('success', __('updated_successfully'));
        } catch (\Exception $e) {
            // Proper Inertia error response
            throw ValidationException::withMessages([
                'error' => [$e->getMessage()],
            ]);
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Option $option)
    {
        $this->authorize('delete', $option);

        $test = $option->question?->section?->part?->test_type?->test;
        if ($test && ($test->attempts()->exists() || $test->mocks()->whereHas('attempts')->exists())) {
            throw ValidationException::withMessages([
                'error' => [__('test_has_attempts')],
            ]);
        }

        try {
            $option->delete();

            return back()->with('success', __('deleted_successfully'));
        } catch (\Exception $e) {
            // Proper Inertia error response
            throw ValidationException::withMessages([
                'error' => [$e->getMessage()],
            ]);
        }
    }
}
