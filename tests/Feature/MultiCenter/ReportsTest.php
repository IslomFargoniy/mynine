<?php

use App\Models\AiUsageLog;
use App\Models\Attempt;
use App\Models\AttemptType;
use App\Models\MockStudent;
use App\Services\CenterReportService;
use Illuminate\Support\Carbon;
use Inertia\Testing\AssertableInertia as Assert;

/**
 * A candidate of $exam's mock whose attempt started at $startedAt with these modules opened.
 *
 * @param  array<int, string>  $modules
 */
function billedCandidate(array $exam, string $name, string $code, ?string $startedAt, array $modules): MockStudent
{
    $student = MockStudent::create(['mock_id' => $exam['mock']->id, 'name' => $name, 'code' => $code]);
    if ($startedAt === null) {
        return $student;
    }

    $attempt = Attempt::create([
        'name' => $name, 'mock_id' => $exam['mock']->id, 'mock_student_id' => $student->id,
        'test_id' => $exam['testL']->id, 'started_at' => $startedAt,
    ]);
    foreach ($modules as $module) {
        AttemptType::create(['attempt_id' => $attempt->id, 'type_id' => makeType($module)->id, 'started_at' => $startedAt]);
    }

    return $student;
}

function aiLog(?int $owner, string $purpose, string $at, int $in, int $out, ?float $cost): void
{
    AiUsageLog::create([
        'owner_id' => $owner, 'provider' => 'openai', 'model' => 'gpt-4o-mini', 'purpose' => $purpose,
        'input_tokens' => $in, 'output_tokens' => $out, 'estimated_cost_usd' => $cost, 'created_at' => $at,
    ]);
}

beforeEach(function () {
    Carbon::setTestNow('2026-11-15 12:00:00');

    $this->superAdmin = makeSuperAdmin();          // owns the Mynine center
    $this->mynine = $this->superAdmin;
    $this->partner = makeCenter('BETA', ['name' => 'Beta Center']);

    $this->examA = makeDesktopExam($this->mynine, ['name' => 'Mynine November', 'started_at' => '2026-11-03 09:00:00'], '300001');
    $this->examB = makeDesktopExam($this->partner, ['name' => 'Beta November', 'started_at' => '2026-11-01 09:00:00'], '400001');
    $this->examBOct = makeDesktopExam($this->partner, ['name' => 'Beta October', 'started_at' => '2026-10-31 09:00:00'], '400002');

    // Beta: one in October (last minutes of the month), two in November, plus three that are never billed.
    billedCandidate($this->examBOct, 'Late October', '410001', '2026-10-31 23:59:00', ['Listening']);
    billedCandidate($this->examB, 'First of November', '410002', '2026-11-01 00:00:00', ['Writing']);
    billedCandidate($this->examB, 'All modules', '410003', '2026-11-20 10:00:00', ['Listening', 'Reading', 'Writing', 'Speaking']);
    billedCandidate($this->examB, 'Speaking only', '410004', '2026-11-05 10:00:00', ['Speaking']);
    billedCandidate($this->examB, 'Never started', '410005', '2026-11-05 10:00:00', []);
    billedCandidate($this->examB, 'No attempt', '410006', null, []);
    // The fixture candidates of makeDesktopExam have no attempt: not billed.

    // Mynine: one in November, one on the first of December.
    billedCandidate($this->examA, 'Mynine Nov', '310001', '2026-11-30 23:59:59', ['Reading']);
    billedCandidate($this->examA, 'Mynine Dec', '310002', '2026-12-01 00:00:00', ['Reading']);

    aiLog($this->partner->id, 'writing_eval', '2026-11-02 10:00:00', 1000, 200, 0.00027);
    aiLog($this->partner->id, 'writing_eval', '2026-11-03 10:00:00', 1000, 200, 0.00027);
    aiLog($this->partner->id, 'pdf_import', '2026-11-04 10:00:00', 50000, 10000, 0.04);
    aiLog($this->partner->id, 'pdf_import', '2026-10-31 23:00:00', 99999, 0, 1.0);
    aiLog($this->partner->id, 'other', '2026-11-04 10:00:00', 10, 10, null);
    aiLog(null, 'writing_eval', '2026-11-10 10:00:00', 500, 100, 0.5);
});

afterEach(fn () => Carbon::setTestNow());

test('the month range is the whole month in Tashkent time', function () {
    [$from, $to] = CenterReportService::monthRange('2026-02');
    expect($from->format('Y-m-d H:i:s'))->toBe('2026-02-01 00:00:00')
        ->and($to->format('Y-m-d H:i:s'))->toBe('2026-02-28 23:59:59')
        ->and($from->getTimezone()->getName())->toBe('Asia/Tashkent')
        ->and(CenterReportService::currentMonth())->toBe('2026-11');
});

test('the SuperAdmin report counts candidates who started a written module in the month, mocks held and AI cost per center', function () {
    $this->actingAs($this->superAdmin)->get(route('reports.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->component('reports/index')
            ->where('month', '2026-11')
            ->has('rows', 2)
            // Mynine first
            ->where('rows.0.code', 'MYNINE')
            ->where('rows.0.candidates', 1)
            ->where('rows.0.mocks', 1)
            ->where('rows.0.ai.total.calls', 0)
            ->where('rows.1.code', 'BETA')
            ->where('rows.1.name', 'Beta Center')
            ->where('rows.1.status', 'active')
            ->where('rows.1.candidates', 2)
            ->where('rows.1.mocks', 1)
            ->where('rows.1.ai.writing_eval.calls', 2)
            ->where('rows.1.ai.writing_eval.input_tokens', 2000)
            ->where('rows.1.ai.writing_eval.output_tokens', 400)
            ->where('rows.1.ai.writing_eval.cost', 0.00054)
            ->where('rows.1.ai.pdf_import.calls', 1)
            ->where('rows.1.ai.pdf_import.cost', 0.04)
            ->where('rows.1.ai.other.calls', 1)
            ->where('rows.1.ai.total.calls', 4)
            ->where('rows.1.ai.unpriced_calls', 1)
            ->where('practice.ai.writing_eval.calls', 1)
            ->where('practice.ai.total.cost', 0.5)
            ->where('totals.candidates', 3)
            ->where('totals.mocks', 2)
            ->where('totals.ai.total.calls', 5)
            ->where('totals.ai.total.cost', 0.54054));
});

test('month boundaries: the last minute of October and the first second of December are not in November', function () {
    $this->actingAs($this->superAdmin)->get(route('reports.index', ['month' => '2026-10']))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('rows.1.candidates', 1)->where('rows.1.mocks', 1)->where('rows.1.ai.pdf_import.cost', 1)->where('rows.0.candidates', 0));

    $this->actingAs($this->superAdmin)->get(route('reports.index', ['month' => '2026-12']))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('rows.0.candidates', 1)->where('rows.1.candidates', 0)->where('totals.ai.total.calls', 0));

    $this->actingAs($this->superAdmin)->get(route('reports.index', ['month' => 'november']))->assertSessionHasErrors('month');
});

test('the drill-down lists exactly the counted candidates', function () {
    $data = $this->actingAs($this->superAdmin)->getJson(route('reports.candidates', ['center' => $this->partner->id, 'month' => '2026-11']))
        ->assertOk()->json('data');

    expect(collect($data)->pluck('code')->all())->toBe(['410002', '410003'])
        ->and($data[0])->toMatchArray(['name' => 'First of November', 'mock' => 'Beta November', 'started_at' => '2026-11-01 00:00']);

    $this->actingAs($this->superAdmin)->getJson(route('reports.candidates', ['center' => 999999]))->assertNotFound();
});

test('a center Admin cannot open the SuperAdmin report or another center\'s numbers; Usage shows only their own', function () {
    $this->actingAs($this->partner)->get(route('reports.index'))->assertForbidden();
    $this->actingAs($this->partner)->getJson(route('reports.candidates', ['center' => $this->mynine->id, 'month' => '2026-11']))->assertForbidden();
    $this->actingAs($this->partner)->getJson(route('reports.candidates', ['center' => $this->partner->id, 'month' => '2026-11']))
        ->assertOk()->assertJsonCount(2, 'data');

    $this->actingAs($this->partner)->get(route('usage.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->component('reports/usage')
            ->where('month', '2026-11')
            ->where('row.code', 'BETA')
            ->where('row.candidates', 2)
            ->where('row.ai.total.calls', 4)
            ->has('candidates', 2)
            ->missing('rows')
            ->missing('practice'));

    // Mynine's Admin page shows only Mynine's numbers.
    $this->actingAs($this->superAdmin)->get(route('usage.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('row.code', 'MYNINE')->has('candidates', 1));

    $reception = makeUser('Reception', $this->partner);
    $this->actingAs($reception)->get(route('reports.index'))->assertForbidden();
    $this->actingAs($reception)->get(route('usage.index'))->assertForbidden();
    $this->actingAs($reception)->getJson(route('reports.candidates', ['center' => $this->partner->id]))->assertForbidden();
    $this->actingAs(makeUser('Student'))->get(route('usage.index'))->assertForbidden();
});
