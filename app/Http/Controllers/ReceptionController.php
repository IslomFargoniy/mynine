<?php

namespace App\Http\Controllers;

use App\Models\Mock;
use App\Models\MockStudent;
use App\Services\CandidateService;
use App\Services\MockResultService;
use App\Support\CenterBranding;
use App\Support\Pdf;
use Carbon\Carbon;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Reception desk (Admin + Reception): candidates of the day's mocks, check-in, code cards,
 * result sheets and delivery. Never exposes answers or per-question data.
 */
class ReceptionController extends Controller
{
    public function __construct(
        private readonly MockResultService $results,
        private readonly CandidateService $candidates,
    ) {}

    public function index(Request $request): Response
    {
        $this->authorize('operate', Mock::class);

        $date = $this->parseDate($request->query('date'));
        $search = trim((string) $request->query('search', ''));
        // mock_id=all lists every mock of the day; no mock_id = automatic choice below.
        $showAll = $request->query('mock_id') === 'all';
        $mockId = $showAll ? null : ($request->integer('mock_id') ?: null);

        $mocks = Mock::query()
            ->withoutEagerLoads()
            ->where(function ($q) use ($date) {
                $q->whereBetween('started_at', [$date->copy()->startOfDay(), $date->copy()->endOfDay()])
                    ->orWhere(fn ($w) => $w->where('started_at', '<=', $date->copy()->endOfDay())
                        ->where('finished_at', '>=', $date->copy()->startOfDay()));
            })
            ->withCount('students')
            ->orderBy('started_at')
            ->get(['id', 'name', 'started_at', 'finished_at', 'active', 'require_desktop', 'speaking_starts_at']);

        // A mock_id of another day (stale link, date changed) is dropped: all of the day's mocks are listed.
        if ($mockId && ! $mocks->contains('id', $mockId)) {
            $mockId = null;
        }
        // Several mocks that day and none chosen: the running one, else the next one, so "Add candidates" has a target.
        if (! $mockId && ! $showAll && $mocks->count() > 1) {
            $mockId = Mock::pickRunningOrNext($mocks)?->id;
        }
        $mockIds = $mockId ? [$mockId] : $mocks->pluck('id')->all();

        $students = MockStudent::query()
            ->with(['mock' => fn ($q) => $q->withoutEagerLoads(), 'attempt.attempt_types.type', 'attempt.device:id,name,number,last_seen_at', 'deliveredBy:id,name'])
            ->whereIn('mock_id', $mockIds)
            ->when($search !== '', function ($q) use ($search) {
                $digits = preg_replace('/\D+/', '', $search);
                $q->where(function ($w) use ($search, $digits) {
                    $w->where('name', 'like', "%{$search}%")
                        ->orWhere('code', 'like', '%'.strtoupper($search).'%');
                    if (strlen($digits) >= 3) {
                        $w->orWhere('phone', 'like', "%{$digits}%");
                    }
                });
            })
            ->orderBy('name')
            ->get();

        return Inertia::render('reception/index', [
            'date' => $date->toDateString(),
            'mocks' => $mocks->map(fn (Mock $m) => [
                'id' => $m->id,
                'name' => $m->name,
                'started_at' => $m->started_at,
                'finished_at' => $m->finished_at,
                'status' => $m->status,
                'require_desktop' => $m->require_desktop,
                'students_count' => $m->students_count,
            ]),
            'candidates' => $this->rows($students),
            'filters' => ['mock_id' => $showAll ? 'all' : $mockId, 'search' => $search],
            'canDelete' => $request->user()->isCenterAdmin(),
        ]);
    }

    public function checkIn(MockStudent $mockStudent): RedirectResponse
    {
        $this->authorize('manageStudents', $mockStudent->mock);

        $mockStudent->forceFill([
            'attended' => true,
            'checked_in_at' => $mockStudent->checked_in_at ?? now(),
        ])->save();

        return back()->with('success', $mockStudent->name.' keldi deb belgilandi.');
    }

    public function deliver(Request $request, MockStudent $mockStudent): RedirectResponse
    {
        $this->authorize('operate', $mockStudent->mock);

        if (! $this->results->result($mockStudent)['ready']) {
            return back()->with('error', __('result_not_ready'));
        }

        $mockStudent->forceFill([
            'result_delivered_at' => now(),
            'delivered_by' => $request->user()->id,
        ])->save();

        return back()->with('success', __('result_delivered'));
    }

    /**
     * One A4 result sheet per ready candidate (?ids=1,2,3). Not-ready candidates are skipped.
     */
    public function resultSheets(Request $request)
    {
        $this->authorize('operate', Mock::class);

        $ids = array_filter(array_map('intval', explode(',', (string) $request->query('ids', ''))));
        abort_if($ids === [], 422, 'Nomzod tanlanmagan.');

        // Scoped to the current center: ids of other centers' candidates are silently skipped.
        $students = MockStudent::query()
            ->with(['mock' => fn ($q) => $q->withoutEagerLoads(), 'attempt.attempt_types.type'])
            ->whereIn('id', $ids)
            ->orderBy('name')
            ->get();

        $sheets = [];
        $brandings = [];
        foreach ($students as $student) {
            $this->authorize('operate', $student->mock);
            $result = $this->results->result($student);
            if (! $result['ready']) {
                continue;
            }

            $ownerId = (int) ($student->mock?->owner_id ?? 0);
            if (! array_key_exists($ownerId, $brandings)) {
                $brandings[$ownerId] = CenterBranding::forCenter($ownerId ?: null);
            }

            $branding = $brandings[$ownerId];
            $testDate = $student->mock?->started_at ? Carbon::parse($student->mock->started_at) : null;
            $variant = $student->mock?->test?->variant === 'general' ? 'general' : 'academic';
            $centreNumber = strtoupper($branding?->code ?: 'MYNINE');

            $sheets[] = [
                'branding' => $branding,
                'center_name' => $branding?->name ?: 'Mynine',
                'centre_number' => $centreNumber,
                'module' => $variant === 'general' ? 'GENERAL TRAINING' : 'ACADEMIC',
                'name' => $student->name,
                ...self::splitName((string) $student->name),
                'code' => $student->code,
                'mock' => $student->mock?->name,
                'date' => $testDate ? strtoupper($testDate->format('d/M/Y')) : '',
                'issued' => now()->format('d/m/Y'),
                'form_number' => ($testDate ?? now())->format('y').preg_replace('/[^A-Z0-9]/', '', $centreNumber).$student->code.'M'.$student->id.($variant === 'general' ? 'G' : 'A'),
                'cefr' => self::cefr((float) $result['overall']),
                'listening' => $result['listening'],
                'reading' => $result['reading'],
                'writing' => $result['writing'],
                'speaking' => $result['speaking'],
                'overall' => $result['overall'],
            ];

            $student->forceFill(['result_printed_at' => now()])->saveQuietly();
        }

        abort_if($sheets === [], 422, __('results_not_ready_selected'));

        return Pdf::render('pdf.result-sheet', compact('sheets'), 'Results_'.now()->format('Ymd_His'));
    }

    /**
     * Family name / first name(s) for the report form. Uzbek names are usually written "Family First"; a surname
     * suffix (-ov, -eva, -iy …) at the end means "First Family".
     *
     * @return array{family: string, first: string}
     */
    private static function splitName(string $name): array
    {
        $words = preg_split('/\s+/u', trim($name), -1, PREG_SPLIT_NO_EMPTY) ?: [];
        if (count($words) < 2) {
            return ['family' => '-', 'first' => $words[0] ?? '-'];
        }
        $surname = '/(ov|ova|ev|eva|yev|yeva|iy|aya|in|ina|zoda|dze|yan|enko)$/iu';
        if (preg_match($surname, end($words)) && ! preg_match($surname, $words[0])) {
            return ['family' => array_pop($words), 'first' => implode(' ', $words)];
        }

        return ['family' => array_shift($words), 'first' => implode(' ', $words)];
    }

    /** CEFR level of an overall band (as on the web result page). */
    private static function cefr(float $overall): string
    {
        return match (true) {
            $overall >= 8.5 => 'C2',
            $overall >= 7.0 => 'C1',
            $overall >= 5.5 => 'B2',
            $overall >= 4.0 => 'B1',
            default => 'A2',
        };
    }

    /**
     * @param  Collection<int, MockStudent>  $students
     * @return array<int, array<string, mixed>>
     */
    private function rows(Collection $students): array
    {
        $online = (int) config('desktop.online_seconds', 60);

        return $students->map(function (MockStudent $s) use ($online) {
            $result = $this->results->result($s);
            $attempt = $s->attempt;
            $device = $attempt?->device;

            return [
                'id' => $s->id,
                'mock_id' => $s->mock_id,
                'mock_name' => $s->mock?->name,
                'name' => $s->name,
                'code' => $s->code,
                'phone' => $s->phone,
                'status' => $this->results->status($s, $result),
                'current_module' => $this->results->currentModule($attempt),
                'missing' => $result['missing'],
                'result_ready' => $result['ready'],
                'checked_in_at' => $s->checked_in_at?->toIso8601String(),
                'speaking_at' => $s->speaking_at?->toIso8601String(),
                'result_printed_at' => $s->result_printed_at?->toIso8601String(),
                'result_delivered_at' => $s->result_delivered_at?->toIso8601String(),
                'delivered_by' => $s->deliveredBy?->name,
                'attempt_id' => $attempt?->id,
                'device' => $device ? [
                    'name' => $device->name,
                    'number' => $device->number,
                    'online' => $device->last_seen_at !== null && $device->last_seen_at->gt(now()->subSeconds($online)),
                ] : null,
                'repeats' => $this->candidates->repeatModules($s->mock, $s->phone, $s->id),
            ];
        })->values()->all();
    }

    private function parseDate(mixed $value): Carbon
    {
        try {
            return is_string($value) && preg_match('/^\d{4}-\d{2}-\d{2}$/', $value) ? Carbon::parse($value) : today();
        } catch (\Throwable) {
            return today();
        }
    }
}
