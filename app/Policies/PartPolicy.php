<?php

namespace App\Policies;

use App\Models\Part;
use App\Models\User\User;
use App\Policies\Concerns\ChecksContentOwnership;

class PartPolicy
{
    use ChecksContentOwnership;

    public function view(User $user, Part $part): bool
    {
        return $this->ownsPart($user, $part);
    }

    public function update(User $user, Part $part): bool
    {
        return $this->ownsPart($user, $part);
    }

    public function delete(User $user, Part $part): bool
    {
        return $this->ownsPart($user, $part);
    }
}
