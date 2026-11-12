<?php

namespace App\Support;

use Carbon\Carbon;

/**
 * Date-only list filters (?from=2026-11-01&to=2026-11-12): whereBetween with the raw dates would stop at
 * 00:00 of the "to" day, hiding everything from that day.
 */
class DayRange
{
    /**
     * Inclusive [start of the "from" day, end of the "to" day] in server time, or null when a date is invalid.
     *
     * @return array{0: Carbon, 1: Carbon}|null
     */
    public static function from(mixed $from, mixed $to): ?array
    {
        if (! $from || ! $to) {
            return null;
        }

        try {
            return [Carbon::parse((string) $from)->startOfDay(), Carbon::parse((string) $to)->endOfDay()];
        } catch (\Throwable) {
            return null;
        }
    }
}
