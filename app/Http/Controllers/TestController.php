<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreTestRequest;
use App\Http\Requests\UpdateTestRequest;
use App\Models\Folder;
use App\Models\Test;
use App\Models\Type;
use App\Services\AudioUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;

class TestController extends Controller
{
    public function __construct(private readonly AudioUploadService $audio) {}

    public function index(Request $request)
    {
        $this->authorize('viewAny', Test::class);

        $per_page = $request->per_page === 'all' ? 100 : min((int) ($request->per_page ?? 10), 100);

        $test = Test::with(['folder'])->withCount('attempts');

        if ($request->search) {
            $test->where(function ($query) use ($request) {
                $query->whereLike('name', "%$request->search%")
                    ->orWhereLike('comment', "%$request->search%");
            });
        }

        if (! Auth::user()->hasRole('Admin')) {
            $test->whereHas('folder', fn ($query) => $query->where('user_id', Auth::id()));
        }

        return Inertia::render('test/index', [
            'test' => $test->paginate($per_page),
        ]);
    }

    public function store(StoreTestRequest $request)
    {
        $folder = Folder::findOrFail($request->folder_id);
        $this->authorize('update', $folder);

        try {
            $user = Auth::user();
            if (! $user->hasRole('Admin')) {
                $userTestsCount = DB::table('tests')
                    ->join('folders', 'tests.folder_id', '=', 'folders.id')
                    ->where('folders.user_id', $user->id)
                    ->count();

                if ($userTestsCount >= $user->create_test_limit) {
                    throw ValidationException::withMessages([
                        'error' => [__('Sizning test yaratish limitingiz tugagan. Jami ruxsat: :limit ta', ['limit' => $user->create_test_limit])],
                    ]);
                }
            }

            $data = $request->validated();
            if ($request->hasFile('audio_path')) {
                $audioData = $this->audio->store($request->file('audio_path'));
                $data['audio_path'] = $audioData['path'];
                $data['playtime_seconds'] = $audioData['playtime'];
            } else {
                $data['audio_path'] = null;
            }

            $test = Test::create($data);

            $test->types()->createMany(
                Type::all()->map(fn ($type) => ['type_id' => $type->id])->toArray()
            );

            return back()->with('success', __('updated_successfully'));
        } catch (ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            throw ValidationException::withMessages(['error' => [$e->getMessage()]]);
        }
    }

    public function show(Request $request, Test $test)
    {
        $this->authorize('view', $test);

        $test->load(['folder', 'types.type']);

        return Inertia::render('test/show', ['test' => $test]);
    }

    public function update(UpdateTestRequest $request, Test $test)
    {
        $this->authorize('update', $test);

        try {
            $data = $request->validated();
            if ($request->hasFile('audio_path')) {
                $audioData = $this->audio->store($request->file('audio_path'), $test->audio_path);
                $data['audio_path'] = $audioData['path'];
                $data['playtime_seconds'] = $audioData['playtime'];
            } else {
                $data['audio_path'] = $test->audio_path;
            }

            $test->update($data);

            return back()->with('success', __('updated_successfully'));
        } catch (\Exception $e) {
            throw ValidationException::withMessages(['error' => [$e->getMessage()]]);
        }
    }

    public function destroy(Test $test)
    {
        $this->authorize('delete', $test);

        if ($test->attempts()->exists() || $test->mocks()->whereHas('attempts')->exists()) {
            return back()->withErrors([
                'error' => __('test_has_attempts'),
            ]);
        }

        try {
            $folderId = $test->folder_id;
            DB::transaction(function () use ($test) {
                $test->mocks()->delete();
                $test->delete();
            });
            $this->audio->delete($test->audio_path);

            if ($folderId) {
                return redirect()->route('folder.show', $folderId)->with('success', __('deleted_successfully'));
            }

            return redirect()->route('all-test.index')->with('success', __('deleted_successfully'));
        } catch (\Exception $e) {
            return back()->withErrors(['error' => $e->getMessage()]);
        }
    }
}
