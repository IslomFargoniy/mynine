<?php

namespace App\Policies;

use App\Models\Attempt;
use App\Models\User\User;
use App\Policies\Concerns\ChecksCenter;
use App\Support\CurrentCenter;

class AttemptPolicy
{
    use ChecksCenter;

    public function viewAny(User $user): bool
    {
        return true;
    }

    /**
     * Who may see an attempt and its results: the candidate (logged in or via candidate code),
     * and the Admin of the attempt's center (mock attempts: the mock's center; practice: Mynine).
     */
    public function view(?User $user, Attempt $attempt): bool
    {
        if ($this->isCandidateSession($attempt)) {
            return true;
        }

        if (! $user) {
            return false;
        }

        if ($attempt->user_id !== null && (int) $attempt->user_id === (int) $user->id) {
            return true;
        }

        return $this->manages($user, $attempt);
    }

    /**
     * Who may answer questions / submit this attempt: only the candidate taking it.
     */
    public function participate(?User $user, Attempt $attempt): bool
    {
        if ($attempt->finished_at !== null) {
            return false;
        }

        if ($this->isCandidateSession($attempt)) {
            return true;
        }

        return $user !== null && $attempt->user_id !== null && (int) $attempt->user_id === (int) $user->id;
    }

    /**
     * Who may set manual scores (Speaking/Writing) or re-run AI evaluation.
     */
    public function grade(User $user, Attempt $attempt): bool
    {
        return $this->manages($user, $attempt);
    }

    /**
     * The center's Admin, or the user themself for their own practice attempt (a test-bank test, no mock).
     */
    public function delete(User $user, Attempt $attempt): bool
    {
        if ($attempt->mock_id === null && $attempt->user_id !== null && (int) $attempt->user_id === (int) $user->id) {
            return true;
        }

        return $this->manages($user, $attempt);
    }

    protected function manages(User $user, Attempt $attempt): bool
    {
        if (! $user->isCenterAdmin()) {
            return false;
        }

        $owner = $attempt->centerId();
        if ($owner === null) {
            // Practice attempt (website): the platform's own center.
            return app(CurrentCenter::class)->isMynine($user->centerId());
        }

        return $this->inCenter($user, $owner);
    }

    protected function isCandidateSession(Attempt $attempt): bool
    {
        $sessionStudentId = session('mock_student_id');

        return $sessionStudentId
            && $attempt->mock_student_id
            && (int) $attempt->mock_student_id === (int) $sessionStudentId;
    }
}
