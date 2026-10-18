<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreSectionRequest;
use App\Http\Requests\UpdateSectionRequest;
use App\Models\Section;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class SectionController extends Controller
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
    public function store(StoreSectionRequest $request)
    {
        $this->authorize('update', \App\Models\Part::findOrFail($request->part_id));

        try {
            DB::beginTransaction();

            $section = Section::create($request->validated());

            if ($section->question_type->type === 'complete_section' || $section->question_type->type === 'drag_and_drop') {
                $this->syncQuestions($section, $request->textarea);
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
     * Display the specified resource.
     */
    public function show(Section $section)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Section $section)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateSectionRequest $request, Section $section)
    {
        $this->authorize('update', $section);

        try {
            DB::beginTransaction();

            $section->update($request->validated());

            if ($section->question_type->type === 'complete_section' || $section->question_type->type === 'drag_and_drop') {
                $this->syncQuestions($section, $request->textarea);
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
    public function destroy(Section $section)
    {
        $this->authorize('delete', $section);

        $test = $section->part?->test_type?->test;
        if ($test && ($test->attempts()->exists() || $test->mocks()->whereHas('attempts')->exists())) {
            throw ValidationException::withMessages([
                'error' => [__('test_has_attempts')],
            ]);
        }

        try {
            $section->delete();

            return back()->with('success', __('deleted_successfully'));
        } catch (\Exception $e) {
            // Proper Inertia error response
            throw ValidationException::withMessages([
                'error' => [$e->getMessage()],
            ]);
        }
    }

    private function syncQuestions(Section $section, string $textarea): void
    {
        preg_match_all(
            '/\{([^\}]+)\}/', // {…} orasidagi matnni olish
            preg_replace(
                '/\s*data-v-[a-z0-9-]+="[^"]*"/i', // TinyMCE (yoki Vue) tomonidan qo‘shilgan data-v-xxxx atributlarini olib tashlash
                '',
                $textarea // TinyMCE’dan kelgan content
            ),
            $matches // Natijalar bu massivga tushadi
        );

        $currentOrders = [];

        foreach ($matches[1] as $index => $rawAnswer) {
            // TinyMCE tomonidan qavs ichiga tushib qolgan HTML teglarni tozalash (masalan <span>caves</span>)
            $cleanAnswer = trim(strip_tags($rawAnswer));
            // Ketma-ket kelgan bo'shliqlarni bitta bo'shliqqa keltirish
            $cleanAnswer = preg_replace('/\s+/', ' ', $cleanAnswer);

            if ($cleanAnswer === '') {
                continue;
            }

            $question = $section->questions()->updateOrCreate(
                [
                    'section_id' => $section->id,
                    'order' => $index + 1,
                ],
                [
                    'answer_text' => $cleanAnswer,
                ]
            );

            $currentOrders[] = $question->order;
        }

        // Eski, ishlatilmay qolgan `questions`ni o‘chirish
        $section->questions()->whereNotIn('order', $currentOrders)->delete();
    }

    public function syncOptions(\Illuminate\Http\Request $request, Section $section)
    {
        $this->authorize('update', $section);

        $request->validate([
            'options' => 'present|array',
            'options.*' => 'nullable|string',
        ]);

        try {
            DB::beginTransaction();

            $section->options()->delete();

            foreach ($request->input('options', []) as $text) {
                $trimmed = trim((string) $text);
                if ($trimmed !== '') {
                    $section->options()->create([
                        'textarea' => $trimmed,
                        'is_correct' => 0,
                    ]);
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
}
