<?php

namespace App\Http\Controllers;

use App\Models\Attempt;
use App\Models\Mock;
use App\Models\MockStudent;
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
     * Audio of a practice test is open to every logged-in user / candidate. Audio of a Mock Bank test only to
     * the staff of the owning center and to candidates of that center's mocks; anyone else gets 404.
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
        $paths = ['media/'.$relative, '/media/'.$relative, 'storage/'.$relative, '/storage/'.$relative];

        $partTestIds = TestType::withoutEagerLoads()
            ->whereIn('id', Part::withoutEagerLoads()->whereIn('audio_path', $paths)->select('test_type_id'))
            ->pluck('test_id');

        $tests = Test::withoutGlobalScopes()
            ->where(fn ($q) => $q->whereIn('audio_path', $paths)->orWhereIn('id', $partTestIds))
            ->get(['id', 'purpose', 'owner_id']);

        // Not the audio of a known test (legacy upload embedded in content): as before.
        if ($tests->isEmpty() || $tests->contains(fn (Test $t) => ! $t->isMock())) {
            return true;
        }

        $owners = $tests->pluck('owner_id')->filter()->map(fn ($id) => (int) $id)->unique()->values()->all();
        $user = $request->user();

        if ($user instanceof User && ($user->isSuperAdmin() || ($user->isStaff() && in_array($user->centerId(), $owners, true)))) {
            return true;
        }

        $centerMocks = Mock::withoutGlobalScopes()->whereIn('owner_id', $owners)->select('id');

        if ($studentId = $request->session()->get('mock_student_id')) {
            if (MockStudent::withoutGlobalScopes()->whereKey($studentId)->whereIn('mock_id', $centerMocks)->exists()) {
                return true;
            }
        }

        return $user instanceof User
            && Attempt::withoutGlobalScopes()->where('user_id', $user->id)->whereIn('mock_id', $centerMocks)->exists();
    }
}
