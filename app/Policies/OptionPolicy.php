<?php

namespace App\Policies;

use App\Models\Option;
use App\Models\User\User;
use App\Policies\Concerns\ChecksContentOwnership;

class OptionPolicy
{
    use ChecksContentOwnership;

    public function update(User $user, Option $option): bool
    {
        return $this->ownsOption($user, $option);
    }

    public function delete(User $user, Option $option): bool
    {
        return $this->ownsOption($user, $option);
    }
}
