<?php

namespace App\Services;

use App\Models\Attempt;
use App\Models\CenterSetting;
use Carbon\CarbonImmutable;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;

/**
 * Monthly usage of the centers: the billing numbers (candidates who sat the exam) and the AI cost.
 *
 * A candidate is BILLED to a month when:
 *  - they are a candidate (mock_students row) of a mock of the center, and
 *  - their exam attempt has at least one written module (Listening, Reading or Writing) started, i.e. an
 *    attempt_types row of that module exists (it is created when the candidate opens the module), and
 *  - the attempt was started (attempts.started_at, else created_at) inside the month, Asia/Tashkent time.
 * Each candidate (code) counts once. A candidate who only had Speaking, or never started a module, is not
 * counted. "Mocks held" = mocks of the center whose start time is inside the month.
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
     * Billed candidates (one row per candidate), optionally of one center.
     */
    public function candidatesQuery(string $month, ?int $centerId = null): Builder
    {
        [$from, $to] = self::monthRange($month);
        $startedAt = DB::raw('COALESCE(attempts.started_at, attempts.created_at)');

        return DB::table('mock_students')
            ->join('mocks', 'mocks.id', '=', 'mock_students.mock_id')
            ->join('attempts', 'attempts.mock_student_id', '=', 'mock_students.id')
            ->whereColumn('attempts.mock_id', 'mocks.id')
            ->whereBetween($startedAt, [$from->format('Y-m-d H:i:s'), $to->format('Y-m-d H:i:s')])
            ->whereExists(fn (Builder $q) => $q->selectRaw('1')
                ->from('attempt_types')
                ->join('types', 'types.id', '=', 'attempt_types.type_id')
                ->whereColumn('attempt_types.attempt_id', 'attempts.id')
                ->whereIn('types.name', Attempt::DESKTOP_MODULE_ORDER))
            ->when($centerId !== null, fn (Builder $q) => $q->where('mocks.owner_id', $centerId));
    }

    /**
     * The billed candidates of one center in a month, for checking an invoice.
     *
     * @return array<int, array{id: int, name: string, code: string, mock: string, mock_id: int, started_at: string}>
     */
    public function candidates(int $centerId, string $month): array
    {
        return $this->candidatesQuery($month, $centerId)
            ->selectRaw('mock_students.id, mock_students.name, mock_students.code, mocks.id as mock_id, mocks.name as mock, MIN(COALESCE(attempts.started_at, attempts.created_at)) as started_at')
            ->groupBy('mock_students.id', 'mock_students.name', 'mock_students.code', 'mocks.id', 'mocks.name')
            ->orderBy('started_at')
            ->orderBy('mock_students.name')
            ->get()
            ->map(fn ($row) => [
                'id' => (int) $row->id,
                'name' => (string) $row->name,
                'code' => (string) $row->code,
                'mock_id' => (int) $row->mock_id,
                'mock' => (string) $row->mock,
                'started_at' => CarbonImmutable::parse($row->started_at, config('app.timezone'))->format('Y-m-d H:i'),
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
            ->groupBy('mocks.owner_id')
            ->selectRaw('mocks.owner_id, COUNT(DISTINCT mock_students.id) as n')
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
