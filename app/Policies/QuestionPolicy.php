<?php

namespace App\Policies;

use App\Models\Question;
use App\Models\User\User;
use App\Policies\Concerns\ChecksContentOwnership;

class QuestionPolicy
{
    use ChecksContentOwnership;

    public function update(User $user, Question $question): bool
    {
        return $this->ownsQuestion($user, $question);
    }

    public function delete(User $user, Question $question): bool
    {
        return $this->ownsQuestion($user, $question);
    }
}
