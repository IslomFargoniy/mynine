<?php

namespace App\Policies;

use App\Models\Attempt;
use App\Models\User\User;
use App\Policies\Concerns\ChecksContentOwnership;

class AttemptPolicy
{
    use ChecksContentOwnership;

    public function viewAny(User $user): bool
    {
        return true;
    }

    /**
     * Who may see an attempt and its results: the candidate (logged in or via candidate code),
     * admins, and the teacher who owns the mock or the test.
     */
    public function view(?User $user, Attempt $attempt): bool
    {
        if ($this->isCandidateSession($attempt)) {
            return true;
        }

        if (! $user) {
            return false;
        }

        if ($user->hasRole('Admin') || (int) $attempt->user_id === (int) $user->id) {
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
        return $user->hasRole('Admin') || $this->manages($user, $attempt);
    }

    public function delete(User $user, Attempt $attempt): bool
    {
        return $user->hasRole('Admin') || $this->manages($user, $attempt);
    }

    protected function manages(User $user, Attempt $attempt): bool
    {
        if (! $this->isContentManager($user)) {
            return false;
        }

        if ($attempt->mock && (int) $attempt->mock->user_id === (int) $user->id) {
            return true;
        }

        return $this->ownsTest($user, $attempt->test);
    }

    protected function isCandidateSession(Attempt $attempt): bool
    {
        $sessionStudentId = session('mock_student_id');

        return $sessionStudentId
            && $attempt->mock_student_id
            && (int) $attempt->mock_student_id === (int) $sessionStudentId;
    }
}
