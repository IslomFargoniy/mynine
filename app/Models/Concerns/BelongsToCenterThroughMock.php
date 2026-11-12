<?php

namespace App\Models\Concerns;

use App\Models\Mock;
use App\Models\Scopes\CenterScope;
use Illuminate\Database\Eloquent\Builder;

/**
 * A model owned through its mock (mock_id): mock_students, mock_modules. Scoped to the current center.
 */
trait BelongsToCenterThroughMock
{
    public static function bootBelongsToCenterThroughMock(): void
    {
        static::addGlobalScope(new CenterScope);
    }

    public function applyCenterScope(Builder $builder, int $centerId): void
    {
        $builder->whereIn($this->qualifyColumn('mock_id'), Mock::centerMockIds($centerId));
    }

    public function belongsToCenter(?int $centerId): bool
    {
        if ($centerId === null || $centerId === 0 || ! $this->getAttribute('mock_id')) {
            return false;
        }

        return (int) Mock::withoutGlobalScope(CenterScope::class)->withoutEagerLoads()->whereKey($this->getAttribute('mock_id'))->value('owner_id') === $centerId;
    }
}
