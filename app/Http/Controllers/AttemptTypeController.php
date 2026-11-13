<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreAttemptTypeRequest;
use App\Models\Attempt;
use App\Services\ExamService;
use App\Support\UserFacingError;
use Illuminate\Validation\ValidationException;

class AttemptTypeController extends Controller
{
    /**
     * Manual (examiner) score for a module, e.g. Speaking.
     */
    public function store(StoreAttemptTypeRequest $request, ExamService $exam)
    {
        $attempt = Attempt::findOrFail($request->attempt_id);
        $this->authorize('grade', $attempt);

        try {
            $exam->storeManualScore($attempt, (int) $request->type_id, (float) $request->score, $request->comment);

            return back()->with('success', __('updated_successfully'));
        } catch (\Exception $e) {
            throw ValidationException::withMessages(['error' => [UserFacingError::message($e)]]);
        }
    }
}
