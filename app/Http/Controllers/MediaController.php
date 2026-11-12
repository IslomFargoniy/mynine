<?php

namespace App\Http\Controllers;

use App\Models\Attempt;
use App\Models\MockModule;
use App\Models\Part;
use App\Models\Test;
use App\Models\TestType;
use App\Models\User\User;
use App\Services\AudioUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\Response;

class MediaController extends Controller
{
    /**
     * Stream exam audio to authenticated users / candidates only.
     * New uploads live on the private "local" disk; files uploaded before the
     * switch may still sit on the public disk, so both are checked.
     *
     * - SuperAdmin: everything. Staff: the audio of their own center's tests (Mock Bank and, for the Mynine
     *   center, practice tests).
     * - Candidates (code session) and students: only the audio of tests in their own attempts' modules (a mock's
     *   modules, else the attempt's test).
     * - Audio that belongs to no test: staff only. Anyone else gets 404.
     */
    public function audio(Request $request, string $filename, AudioUploadService $audio): Response
    {
        $relative = 'audio/'.$filename;
        abort_unless($this->mayHear($request, $relative), 404);

        foreach (['local', 'public'] as $disk) {
            if (Storage::disk($disk)->exists($relative)) {
                $path = Storage::disk($disk)->path($relative);

                return $audio->response($path, Storage::disk($disk)->mimeType($relative) ?: 'audio/mpeg');
            }
        }

        abort(404);
    }

    private function mayHear(Request $request, string $relative): bool
    {
        $user = $request->user();
        $user = $user instanceof User ? $user : null;

        if ($user?->isSuperAdmin()) {
            return true;
        }

        $paths = ['media/'.$relative, '/media/'.$relative, 'storage/'.$relative, '/storage/'.$relative];

        $partTestIds = TestType::withoutEagerLoads()
            ->whereIn('id', Part::withoutEagerLoads()->whereIn('audio_path', $paths)->select('test_type_id'))
            ->pluck('test_id');

        $tests = Test::withoutGlobalScopes()
            ->where(fn ($q) => $q->whereIn('audio_path', $paths)->orWhereIn('id', $partTestIds))
            ->get(['id', 'purpose', 'owner_id']);

        if ($tests->isEmpty()) {
            // Not the audio of a known test (legacy upload embedded in content): staff only.
            return (bool) $user?->isStaff();
        }

        if ($user?->isStaff()) {
            $owners = $tests->pluck('owner_id')->filter()->map(fn ($id) => (int) $id)->all();

            return in_array($user->centerId(), $owners, true);
        }

        $studentId = $request->hasSession() ? $request->session()->get('mock_student_id') : null;
        if (! $user && ! $studentId) {
            return false;
        }

        $attempts = Attempt::withoutGlobalScopes()->withoutEagerLoads()
            ->where(fn ($q) => $q
                ->when($user, fn ($w) => $w->orWhere('user_id', $user->id))
                ->when($studentId, fn ($w) => $w->orWhere('mock_student_id', (int) $studentId)))
            ->get(['id', 'mock_id', 'test_id']);

        if ($attempts->isEmpty()) {
            return false;
        }

        // Same rule as Attempt::allowsTestType: a mock's modules, else the attempt's own test.
        $modules = MockModule::query()->whereIn('mock_id', $attempts->pluck('mock_id')->filter()->unique())
            ->get(['mock_id', 'test_type_id']);
        $mocksWithModules = $modules->pluck('mock_id')->map(fn ($id) => (int) $id)->unique()->all();

        $allowed = TestType::withoutEagerLoads()->whereIn('id', $modules->pluck('test_type_id'))->pluck('test_id')
            ->merge($attempts->reject(fn ($a) => $a->mock_id && in_array((int) $a->mock_id, $mocksWithModules, true))->pluck('test_id'))
            ->filter()
            ->map(fn ($id) => (int) $id)
            ->all();

        return $tests->contains(fn (Test $test) => in_array((int) $test->id, $allowed, true));
    }
}
