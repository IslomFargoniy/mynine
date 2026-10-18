<?php

namespace App\Policies;

use App\Models\TestType;
use App\Models\User\User;
use App\Policies\Concerns\ChecksContentOwnership;

class TestTypePolicy
{
    use ChecksContentOwnership;

    public function view(User $user, TestType $testType): bool
    {
        return $this->ownsTestType($user, $testType);
    }

    public function update(User $user, TestType $testType): bool
    {
        return $this->ownsTestType($user, $testType);
    }
}
