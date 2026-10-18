<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreTestTypeRequest;
use App\Http\Requests\UpdateTestTypeRequest;
use App\Models\QuestionType;
use App\Models\TestType;
use Inertia\Inertia;

class TestTypeController extends Controller
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
    public function store(StoreTestTypeRequest $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(TestType $testType)
    {
        $this->authorize('view', $testType);

        $testType->load([
            'test.folder',
            'type',
            'parts',
        ]);

        $question_types = QuestionType::all();

        return Inertia::render('test-type/show', [
            'testType' => $testType,
            'question_types' => $question_types,
        ]);
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(TestType $testType)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateTestTypeRequest $request, TestType $testType)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(TestType $testType)
    {
        //
    }
}
