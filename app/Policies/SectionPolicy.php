<?php

namespace App\Policies;

use App\Models\Section;
use App\Models\User\User;
use App\Policies\Concerns\ChecksContentOwnership;

class SectionPolicy
{
    use ChecksContentOwnership;

    public function update(User $user, Section $section): bool
    {
        return $this->ownsSection($user, $section);
    }

    public function delete(User $user, Section $section): bool
    {
        return $this->ownsSection($user, $section);
    }
}
