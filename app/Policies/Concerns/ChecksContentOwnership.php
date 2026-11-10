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
 * Shared ownership rules for test content ([folder] -> test -> test type -> part -> section -> question -> option).
 * Only admins manage content (the Teacher role was removed: the system has Admin, Reception and Student).
 */
trait ChecksContentOwnership
{
    protected function isContentManager(User $user): bool
    {
        return $user->hasRole('Admin');
    }

    protected function ownsFolder(User $user, ?Folder $folder): bool
    {
        return $folder !== null && $user->hasRole('Admin');
    }

    /**
     * Mock Bank tests have no folder (folder_id = null): content managers own them directly.
     */
    protected function ownsTest(User $user, ?Test $test): bool
    {
        if ($test === null) {
            return false;
        }

        return $test->folder_id === null
            ? $this->isContentManager($user)
            : $this->ownsFolder($user, $test->folder);
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
