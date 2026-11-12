<?php

namespace App\Models\Concerns;

use App\Models\Scopes\CenterScope;
use App\Models\User\User;
use App\Support\CurrentCenter;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A model with an owner_id column (the center's Admin user): scoped to the current center, and owner_id is
 * filled on create from the current center (else fallbackCenterId(), else the Mynine center).
 */
trait BelongsToCenter
{
    public static function bootBelongsToCenter(): void
    {
        static::addGlobalScope(new CenterScope);

        static::creating(function (self $model) {
            if (! $model->getAttribute('owner_id')) {
                $model->setAttribute('owner_id', $model->defaultCenterId());
            }
        });
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function applyCenterScope(Builder $builder, int $centerId): void
    {
        $builder->where($this->qualifyColumn('owner_id'), $centerId);
    }

    /**
     * Every row of one center, whatever the current center is.
     */
    public function scopeOfCenter(Builder $query, int $centerId): Builder
    {
        return $query->withoutGlobalScope(CenterScope::class)->where($this->qualifyColumn('owner_id'), $centerId);
    }

    public function belongsToCenter(?int $centerId): bool
    {
        return $centerId !== null && $centerId !== CurrentCenter::NONE && (int) $this->getAttribute('owner_id') === $centerId;
    }

    protected function defaultCenterId(): ?int
    {
        $center = app(CurrentCenter::class);
        $current = $center->id();

        if ($current !== null && $current !== CurrentCenter::NONE) {
            return $current;
        }

        return $this->fallbackCenterId() ?? $center->mynineId();
    }

    /**
     * Owner when the record is created outside a center context (console, jobs, tests).
     */
    protected function fallbackCenterId(): ?int
    {
        return null;
    }
}
