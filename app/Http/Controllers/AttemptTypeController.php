<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreAttemptTypeRequest;
use App\Models\Attempt;
use App\Models\AttemptType;
use Illuminate\Validation\ValidationException;

class AttemptTypeController extends Controller
{
    /**
     * Manual (examiner) score for a module, e.g. Speaking.
     */
    public function store(StoreAttemptTypeRequest $request)
    {
        $attempt = Attempt::findOrFail($request->attempt_id);
        $this->authorize('grade', $attempt);

        try {
            $attemptType = AttemptType::updateOrCreate(
                ['attempt_id' => $attempt->id, 'type_id' => $request->type_id],
                [
                    'score' => $request->score,
                    'comment' => $request->comment,
                    'started_at' => now(),
                    'finished_at' => now(),
                    'is_submitted' => true,
                ]
            );

            $attemptType->recalculateIsCorrectCount();

            return back()->with('success', __('updated_successfully'));
        } catch (\Exception $e) {
            throw ValidationException::withMessages(['error' => [$e->getMessage()]]);
        }
    }
}
