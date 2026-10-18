<?php

namespace App\Policies\Concerns;

use App\Models\Folder;
use App\Models\Option;
use App\Models\Part;
use App\Models\Question;
use App\Models\Section;
use App\Models\Test;
use App\Models\TestType;
use App\Models\User\User;

/**
 * Shared ownership rules for test content (folder -> test -> test type -> part -> section -> question -> option).
 * Admins manage everything; teachers manage only content inside their own folders.
 */
trait ChecksContentOwnership
{
    protected function isContentManager(User $user): bool
    {
        return $user->hasRole('Admin') || $user->hasRole('Teacher');
    }

    protected function ownsFolder(User $user, ?Folder $folder): bool
    {
        if ($user->hasRole('Admin')) {
            return true;
        }

        return $folder !== null && (int) $folder->user_id === (int) $user->id;
    }

    protected function ownsTest(User $user, ?Test $test): bool
    {
        return $test !== null && $this->ownsFolder($user, $test->folder);
    }

    protected function ownsTestType(User $user, ?TestType $testType): bool
    {
        return $testType !== null && $this->ownsTest($user, $testType->test);
    }

    protected function ownsPart(User $user, ?Part $part): bool
    {
        return $part !== null && $this->ownsTestType($user, $part->test_type);
    }

    protected function ownsSection(User $user, ?Section $section): bool
    {
        return $section !== null && $this->ownsPart($user, $section->part);
    }

    protected function ownsQuestion(User $user, ?Question $question): bool
    {
        return $question !== null && $this->ownsSection($user, $question->section);
    }

    protected function ownsOption(User $user, ?Option $option): bool
    {
        if ($option === null) {
            return false;
        }

        if ($option->question_id) {
            return $this->ownsQuestion($user, $option->question);
        }

        return $this->ownsSection($user, $option->section);
    }
}
