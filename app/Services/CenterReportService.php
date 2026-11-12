<?php

namespace App\Services;

use App\Models\CenterSetting;
use Carbon\CarbonImmutable;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;

/**
 * Monthly usage of the centers: the billing numbers (candidates who sat the exam) and the AI cost.
 *
 * A candidate is BILLED to a month when they have a center_billable_candidates row counted inside the month
 * (Asia/Tashkent time). The row is written once, the first time the candidate's mock attempt starts a
 * written module (Listening, Reading or Writing), with counted_at = the attempt's start (attempts.started_at,
 * else created_at), and it is never changed or deleted — deleting the mock, the candidate or the attempt later
 * does not lower the count. A candidate who only had Speaking, or never started a module, is not counted.
 * "Mocks held" = mocks of the center whose start time is inside the month.
 */
class CenterReportService
{
    /**
     * [first moment, last moment] of a "YYYY-MM" month in the app time zone (Asia/Tashkent).
     *
     * @return array{0: CarbonImmutable, 1: CarbonImmutable}
     */
    public static function monthRange(string $month): array
    {
        $start = CarbonImmutable::createFromFormat('!Y-m', $month, config('app.timezone'))->startOfMonth();

        return [$start, $start->endOfMonth()];
    }

    public static function currentMonth(): string
    {
        return now(config('app.timezone'))->format('Y-m');
    }

    /**
     * Billed candidates (one center_billable_candidates row per candidate), optionally of one center.
     */
    public function candidatesQuery(string $month, ?int $centerId = null): Builder
    {
        [$from, $to] = self::monthRange($month);

        return DB::table('center_billable_candidates')
            ->whereBetween('counted_at', [$from->format('Y-m-d H:i:s'), $to->format('Y-m-d H:i:s')])
            ->when($centerId !== null, fn (Builder $q) => $q->where('owner_id', $centerId));
    }

    /**
     * The billed candidates of one center in a month, for checking an invoice (also those whose mock or
     * candidate row was deleted later: mock_id / id may point to a deleted row).
     *
     * @return array<int, array{id: int|null, name: string, code: string, mock: string, mock_id: int|null, started_at: string}>
     */
    public function candidates(int $centerId, string $month): array
    {
        return $this->candidatesQuery($month, $centerId)
            ->orderBy('counted_at')
            ->orderBy('name')
            ->get()
            ->map(fn ($row) => [
                'id' => $row->mock_student_id !== null ? (int) $row->mock_student_id : null,
                'name' => (string) $row->name,
                'code' => (string) $row->code,
                'mock_id' => $row->mock_id !== null ? (int) $row->mock_id : null,
                'mock' => (string) $row->mock_name,
                'started_at' => CarbonImmutable::parse($row->counted_at, config('app.timezone'))->format('Y-m-d H:i'),
            ])
            ->all();
    }

    /**
     * One row per center (or only $centerId), the AI usage without a center ("Mynine practice") and totals.
     *
     * @return array{rows: array<int, array<string, mixed>>, practice: array<string, mixed>, totals: array<string, mixed>}
     */
    public function summary(string $month, ?int $centerId = null): array
    {
        [$from, $to] = self::monthRange($month);
        $range = [$from->format('Y-m-d H:i:s'), $to->format('Y-m-d H:i:s')];

        $centers = CenterSetting::query()
            ->when($centerId !== null, fn ($q) => $q->where('owner_id', $centerId))
            ->orderByRaw('CASE WHEN code = ? THEN 0 ELSE 1 END', [CenterSetting::MYNINE_CODE])
            ->orderBy('name')
            ->get();

        $candidates = $this->candidatesQuery($month, $centerId)
            ->groupBy('owner_id')
            ->selectRaw('owner_id, COUNT(*) as n')
            ->pluck('n', 'owner_id');

        $mocks = DB::table('mocks')
            ->whereBetween('started_at', $range)
            ->when($centerId !== null, fn ($q) => $q->where('owner_id', $centerId))
            ->groupBy('owner_id')
            ->selectRaw('owner_id, COUNT(*) as n')
            ->pluck('n', 'owner_id');

        $ai = DB::table('ai_usage_logs')
            ->whereBetween('created_at', $range)
            ->when($centerId !== null, fn ($q) => $q->where('owner_id', $centerId))
            ->groupBy('owner_id', 'purpose')
            ->selectRaw('owner_id, purpose, COUNT(*) as calls, SUM(input_tokens) as input_tokens, SUM(output_tokens) as output_tokens, SUM(estimated_cost_usd) as cost, SUM(CASE WHEN estimated_cost_usd IS NULL THEN 1 ELSE 0 END) as unpriced')
            ->get()
            ->groupBy(fn ($row) => (string) ($row->owner_id ?? ''));

        $rows = $centers->map(fn (CenterSetting $c) => [
            'id' => (int) $c->owner_id,
            'name' => $c->name,
            'code' => $c->code,
            'status' => $c->status,
            'suspended' => $c->isSuspended(),
            'is_mynine' => $c->isMynine(),
            'candidates' => (int) ($candidates[$c->owner_id] ?? 0),
            'mocks' => (int) ($mocks[$c->owner_id] ?? 0),
            'ai' => self::aiTotals($ai->get((string) $c->owner_id, collect())->all()),
        ])->values()->all();

        $practice = ['ai' => self::aiTotals($centerId === null ? $ai->get('', collect())->all() : [])];

        $totals = [
            'candidates' => array_sum(array_column($rows, 'candidates')),
            'mocks' => array_sum(array_column($rows, 'mocks')),
            'ai' => self::sumAi([...array_column($rows, 'ai'), $practice['ai']]),
        ];

        return compact('rows', 'practice', 'totals');
    }

    /**
     * @param  array<int, object>  $rows  ai_usage_logs aggregates of one owner, one row per purpose
     * @return array<string, mixed>
     */
    private static function aiTotals(array $rows): array
    {
        $empty = ['calls' => 0, 'input_tokens' => 0, 'output_tokens' => 0, 'cost' => 0.0];
        $out = ['writing_eval' => $empty, 'pdf_import' => $empty, 'other' => $empty, 'unpriced_calls' => 0];

        foreach ($rows as $row) {
            $key = in_array($row->purpose, ['writing_eval', 'pdf_import'], true) ? $row->purpose : 'other';
            $out[$key] = [
                'calls' => $out[$key]['calls'] + (int) $row->calls,
                'input_tokens' => $out[$key]['input_tokens'] + (int) $row->input_tokens,
                'output_tokens' => $out[$key]['output_tokens'] + (int) $row->output_tokens,
                'cost' => round($out[$key]['cost'] + (float) $row->cost, 6),
            ];
            $out['unpriced_calls'] += (int) $row->unpriced;
        }

        $out['total'] = self::sumParts([$out['writing_eval'], $out['pdf_import'], $out['other']]);

        return $out;
    }

    /**
     * @param  array<int, array<string, mixed>>  $items
     * @return array<string, mixed>
     */
    private static function sumAi(array $items): array
    {
        $out = ['unpriced_calls' => array_sum(array_column($items, 'unpriced_calls'))];
        foreach (['writing_eval', 'pdf_import', 'other', 'total'] as $key) {
            $out[$key] = self::sumParts(array_column($items, $key));
        }

        return $out;
    }

    /**
     * @param  array<int, array{calls: int, input_tokens: int, output_tokens: int, cost: float}>  $parts
     * @return array{calls: int, input_tokens: int, output_tokens: int, cost: float}
     */
    private static function sumParts(array $parts): array
    {
        return [
            'calls' => array_sum(array_column($parts, 'calls')),
            'input_tokens' => array_sum(array_column($parts, 'input_tokens')),
            'output_tokens' => array_sum(array_column($parts, 'output_tokens')),
            'cost' => round(array_sum(array_column($parts, 'cost')), 6),
        ];
    }
}
