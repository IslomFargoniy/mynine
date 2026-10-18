<?php

namespace App\Policies;

use App\Models\Folder;
use App\Models\User\User;
use App\Policies\Concerns\ChecksContentOwnership;

class FolderPolicy
{
    use ChecksContentOwnership;

    public function viewAny(User $user): bool
    {
        return $this->isContentManager($user);
    }

    public function view(User $user, Folder $folder): bool
    {
        return $this->ownsFolder($user, $folder);
    }

    public function create(User $user): bool
    {
        return $this->isContentManager($user);
    }

    public function update(User $user, Folder $folder): bool
    {
        return $this->ownsFolder($user, $folder);
    }

    public function delete(User $user, Folder $folder): bool
    {
        return $this->ownsFolder($user, $folder);
    }
}
