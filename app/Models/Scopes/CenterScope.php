<?php

namespace App\Models\Scopes;

use App\Support\CurrentCenter;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Scope;

/**
 * Limits center-owned models to the current center (App\Support\CurrentCenter). No current center
 * (students, guests, console, jobs) → no restriction.
 */
class CenterScope implements Scope
{
    public function apply(Builder $builder, Model $model): void
    {
        $centerId = app(CurrentCenter::class)->id();

        if ($centerId !== null) {
            $model->applyCenterScope($builder, $centerId);
        }
    }
}
