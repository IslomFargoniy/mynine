<?php

use App\Models\Attempt;
use App\Models\AttemptType;
use App\Models\CenterBillableCandidate;
use App\Models\Mock;
use App\Models\MockStudent;
use App\Services\CenterReportService;
use App\Services\ExamService;
use App\Support\CurrentCenter;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

beforeEach(function () {
    Carbon::setTestNow('2026-11-15 12:00:00');
    $this->superAdmin = makeSuperAdmin();
    $this->partner = makeCenter('BETA');
    $this->exam = makeDesktopExam($this->partner, ['name' => 'Beta November']);
});

afterEach(fn () => Carbon::setTestNow());

function finishedAttempt(array $exam, ?MockStudent $student = null): Attempt
{
    $student ??= $exam['student'];

    return Attempt::create([
        'name' => $student->name, 'mock_id' => $exam['mock']->id, 'mock_student_id' => $student->id,
        'test_id' => $exam['testL']->id, 'started_at' => now()->subHour(), 'finished_at' => now(),
    ]);
}

function partnerCount(int $centerId): int
{
    return collect(app(CenterReportService::class)->summary('2026-11', $centerId)['rows'])->sum('candidates');
}

test('the first written module started records the candidate once; Speaking alone does not', function () {
    $attempt = finishedAttempt($this->exam);
    AttemptType::create(['attempt_id' => $attempt->id, 'type_id' => makeType('Speaking')->id, 'started_at' => now()]);
    expect(CenterBillableCandidate::count())->toBe(0);

    app(ExamService::class)->startModule($attempt, $this->exam['listening']);
    app(ExamService::class)->startModule($attempt, $this->exam['reading']);

    $row = CenterBillableCandidate::sole();
    expect($row->owner_id)->toBe($this->partner->id)
        ->and($row->mock_student_id)->toBe($this->exam['student']->id)
        ->and($row->code)->toBe($this->exam['student']->code)
        ->and($row->mock_name)->toBe('Beta November');

    // Web exam room (startPart) records too.
    $other = MockStudent::create(['mock_id' => $this->exam['mock']->id, 'name' => 'Web Candidate', 'code' => '555001']);
    app(ExamService::class)->startPart(finishedAttempt($this->exam, $other), $this->exam['partR']);
    expect(CenterBillableCandidate::count())->toBe(2)
        ->and(fn () => $row->update(['name' => 'x']))->toThrow(LogicException::class)
        ->and(fn () => $row->delete())->toThrow(LogicException::class);
});

test('a center Admin cannot delete a billed mock or candidate; deleting an attempt does not lower the bill', function () {
    $attempt = finishedAttempt($this->exam);
    app(ExamService::class)->startModule($attempt, $this->exam['writing']);
    expect(partnerCount($this->partner->id))->toBe(1);

    $this->actingAs($this->partner)->delete(route('mock-student.destroy', $this->exam['student']))
        ->assertSessionHas('error', __('candidate_has_exam_results'));
    $this->actingAs($this->partner)->delete(route('mock.destroy', $this->exam['mock']))
        ->assertSessionHas('error', __('mock_has_exam_results'));
    expect(MockStudent::withoutGlobalScopes()->whereKey($this->exam['student']->id)->exists())->toBeTrue()
        ->and(Mock::withoutGlobalScopes()->whereKey($this->exam['mock']->id)->exists())->toBeTrue();

    // A candidate who never started a written module can still be removed.
    $absent = MockStudent::create(['mock_id' => $this->exam['mock']->id, 'name' => 'Absent', 'code' => '555002']);
    $this->actingAs($this->partner)->delete(route('mock-student.destroy', $absent))->assertSessionHas('success');

    $this->actingAs($this->partner)->delete(route('attempt.destroy', $attempt->id))->assertRedirect(route('attempt.index'));
    expect(Attempt::withoutGlobalScopes()->whereKey($attempt->id)->exists())->toBeFalse()
        ->and(partnerCount($this->partner->id))->toBe(1);
});

test('the SuperAdmin may delete a billed mock: billing rows stay and its attempts keep their center', function () {
    $attempt = finishedAttempt($this->exam);
    app(ExamService::class)->startModule($attempt, $this->exam['listening']);
    expect($attempt->fresh()->owner_id)->toBe($this->partner->id);

    $this->actingAs($this->superAdmin)->withSession([CurrentCenter::SESSION_KEY => $this->partner->id])
        ->delete(route('mock.destroy', $this->exam['mock']))->assertSessionHas('success');

    $attempt = Attempt::withoutGlobalScopes()->findOrFail($attempt->id);
    expect($attempt->mock_id)->toBeNull()
        ->and($attempt->owner_id)->toBe($this->partner->id)
        ->and($attempt->centerId())->toBe($this->partner->id)
        ->and(partnerCount($this->partner->id))->toBe(1);

    $data = $this->actingAs($this->superAdmin)->getJson(route('reports.candidates', ['center' => $this->partner->id, 'month' => '2026-11']))
        ->assertOk()->json('data');
    expect($data)->toHaveCount(1)->and($data[0]['mock'])->toBe('Beta November');

    // Still the partner's attempt, not part of the Mynine / practice bucket.
    $center = app(CurrentCenter::class);
    expect($center->runAs($this->partner->id, fn () => Attempt::whereKey($attempt->id)->exists()))->toBeTrue()
        ->and($center->runAs($this->superAdmin->id, fn () => Attempt::whereKey($attempt->id)->exists()))->toBeFalse();
});

test('the migration backfills billing rows and attempt owners from existing data', function () {
    $attempt = finishedAttempt($this->exam);
    app(ExamService::class)->startModule($attempt, $this->exam['reading']);

    $migration = require database_path('migrations/2026_11_13_000002_create_center_billable_candidates_and_attempt_owner.php');
    $migration->down();
    $migration->up();

    expect(DB::table('center_billable_candidates')->pluck('mock_student_id')->all())->toBe([$this->exam['student']->id])
        ->and((int) DB::table('attempts')->where('id', $attempt->id)->value('owner_id'))->toBe($this->partner->id)
        ->and(partnerCount($this->partner->id))->toBe(1);
});
