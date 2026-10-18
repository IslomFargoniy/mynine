<?php

namespace App\Http\Controllers;

use App\Http\Requests\StorePartRequest;
use App\Http\Requests\UpdatePartRequest;
use App\Models\Part;
use App\Models\TestType;
use App\Services\AudioUploadService;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;

class PartController extends Controller
{
    public function __construct(private readonly AudioUploadService $audio) {}

    public function create(Request $request)
    {
        $request->validate(['test_type_id' => 'required|exists:test_types,id']);

        $testType = TestType::with(['test.folder', 'type'])->findOrFail($request->test_type_id);
        $this->authorize('update', $testType);

        return Inertia::render('part/create-part', ['testType' => $testType]);
    }

    public function store(StorePartRequest $request)
    {
        $this->authorize('update', TestType::findOrFail($request->test_type_id));

        try {
            $data = $request->validated();
            if ($request->hasFile('audio_path')) {
                $audioData = $this->audio->store($request->file('audio_path'));
                $data['audio_path'] = $audioData['path'];
                $data['minute'] = $audioData['playtime'] ? (int) ceil($audioData['playtime'] / 60) : null;
            }

            $part = Part::create($data);

            return redirect()->route('test-type.show', [
                'test_type' => $request->test_type_id,
                'tab' => $part->id,
            ]);
        } catch (\Exception $e) {
            throw ValidationException::withMessages(['error' => [$e->getMessage()]]);
        }
    }

    public function show(Part $part)
    {
        $this->authorize('view', $part);

        $part->load(['test_type.test.folder', 'sections', 'images']);

        return Inertia::render('part/edit-part', ['part' => $part]);
    }

    public function update(UpdatePartRequest $request, Part $part)
    {
        $this->authorize('update', $part);

        try {
            $data = $request->validated();
            if ($request->hasFile('audio_path')) {
                $audioData = $this->audio->store($request->file('audio_path'), $part->audio_path);
                $data['audio_path'] = $audioData['path'];
                $data['minute'] = $audioData['playtime'] ? (int) ceil($audioData['playtime'] / 60) : null;
            } else {
                $data['audio_path'] = $part->audio_path;
            }

            $part->update($data);

            return redirect()->route('test-type.show', $part->test_type_id);
        } catch (\Exception $e) {
            throw ValidationException::withMessages(['error' => [$e->getMessage()]]);
        }
    }

    public function destroy(Part $part)
    {
        $this->authorize('delete', $part);

        $test = $part->test_type?->test;
        if ($test && ($test->attempts()->exists() || $test->mocks()->whereHas('attempts')->exists())) {
            throw ValidationException::withMessages(['error' => [__('test_has_attempts')]]);
        }

        try {
            $audioPath = $part->audio_path;
            $part->delete();
            $this->audio->delete($audioPath);

            return back()->with('success', __('deleted_successfully'));
        } catch (\Exception $e) {
            throw ValidationException::withMessages(['error' => [$e->getMessage()]]);
        }
    }
}
