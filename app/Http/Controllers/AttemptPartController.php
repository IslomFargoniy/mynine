<?php

namespace App\Http\Controllers;

use App\Models\Attempt;
use App\Models\AttemptPart;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AttemptPartController extends Controller
{
    /**
     * Full review payload (questions, correct answers, candidate answers) for one module.
     * Available to graders at any time and to the candidate once the attempt is finished.
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'attempt_id' => 'required|integer|exists:attempts,id',
            'type_id' => 'required|integer|exists:types,id',
        ]);

        $attempt = Attempt::findOrFail($request->attempt_id);
        $this->authorize('view', $attempt);

        $canGrade = Auth::check() && Auth::user()->can('grade', $attempt);
        abort_unless($canGrade || $attempt->finished_at !== null, 403, 'Results are available after the attempt is finished.');

        $attemptParts = AttemptPart::query()
            ->where('attempt_id', $attempt->id)
            ->whereHas('part.test_type', fn ($q) => $q->where('type_id', $request->type_id))
            ->with([
                'part.test_type',
                'part.attempt_part' => fn ($q) => $q->where('attempt_id', $attempt->id),
                'part.sections.questions.options',
            ])
            ->orderBy('part_id')
            ->get();

        $attemptParts->each(function (AttemptPart $attemptPart) {
            $attemptPart->part->sections->load([
                'questions.attempt_answer' => fn ($q) => $q->where('attempt_part_id', $attemptPart->id)
                    ->with('attempt_answer_options'),
            ]);
        });

        return response()->json([
            'data' => $attemptParts,
            'success' => true,
            'message' => 'Attempt parts retrieved successfully',
        ]);
    }
}
