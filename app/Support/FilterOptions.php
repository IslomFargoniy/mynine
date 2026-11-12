<?php

namespace App\Support;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Model;

/**
 * Options of a list filter dropdown: the first $limit rows of the query (callers order newest first), plus the
 * currently filtered row when it is older, so the dropdown always shows what the list is filtered on.
 */
class FilterOptions
{
    /**
     * @param  Builder<Model>  $query  already restricted to what the user may see
     */
    public static function keep(Builder $query, ?int $selectedId, int $limit = 50): Collection
    {
        $options = (clone $query)->limit($limit)->get();

        if ($selectedId && ! $options->contains('id', $selectedId)) {
            $selected = (clone $query)->whereKey($selectedId)->first();
            if ($selected) {
                $options->push($selected);
            }
        }

        return $options;
    }
}
