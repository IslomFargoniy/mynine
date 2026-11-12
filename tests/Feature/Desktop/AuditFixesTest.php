<?php

use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\AttemptPart;
use App\Models\AttemptType;
use App\Models\Device;
use App\Models\Folder;
use App\Models\MockStudent;
use App\Models\Option;
use App\Services\ExamService;
use App\Services\Import\MockTestImporter;
use App\Services\MockResultService;
use Illuminate\Support\Facades\Queue;
use Laravel\Sanctum\PersonalAccessToken;

/*
|--------------------------------------------------------------------------
| Server-side audit fixes (Speaking-first attempts, "test in use" guards, delete / block guards,
| resume login, late-sync readiness, Writing confirm, register response).
|--------------------------------------------------------------------------
*/

beforeEach(function () {
    Queue::fake();
    $this->admin = makeUser('Admin');
    $this->exam = makeDesktopExam($this->admin);
});

function auditSpeakingScore(MockStudent $student): void
{
    test()->actingAs(test()->admin)
        ->post(route('speaking.score', $student), ['fluency' => 6, 'lexical' => 6, 'grammar' => 6, 'pronunciation' => 6])
        ->assertSessionHas('success');
}

/**
 * Listening + Reading submitted and a Writing module with one essay (scored unless $essayScore is null).
 */
function auditWrittenExam(MockStudent $student, ?float $essayScore = 6.0, bool $submitWriting = true): Attempt
{
    $exam = test()->exam;
    $attempt = app(ExamService::class)->findOrCreateMockAttempt($student);

    AttemptType::create(['attempt_id' => $attempt->id, 'type_id' => $exam['listeningType']->id, 'is_submitted' => true, 'is_correct_count' => 30, 'started_at' => now(), 'finished_at' => now()]);
    AttemptType::create(['attempt_id' => $attempt->id, 'type_id' => $exam['readingType']->id, 'is_submitted' => true, 'is_correct_count' => 27, 'started_at' => now(), 'finished_at' => now()]);
    AttemptType::create(['attempt_id' => $attempt->id, 'type_id' => $exam['writingType']->id, 'is_submitted' => $submitWriting, 'started_at' => now(), 'finished_at' => now()->addHour()]);

    $part = AttemptPart::create(['attempt_id' => $attempt->id, 'part_id' => $exam['partW']->id, 'started_at' => now()]);
    AttemptAnswer::create(['attempt_part_id' => $part->id, 'question_id' => $exam['essayQuestion']->id, 'answer_text' => str_repeat('word ', 260), 'score' => $essayScore]);

    return $attempt->fresh();
}

function auditWritingType(Attempt $attempt): AttemptType
{
    return AttemptType::where('attempt_id', $attempt->id)->where('type_id', test()->exam['writingType']->id)->firstOrFail();
}

// 1. Speaking before the written exam

test('1) a Speaking band given before the written exam does not let close-old finish the attempt', function () {
    $student = $this->exam['student'];
    auditSpeakingScore($student);

    $attempt = Attempt::where('mock_student_id', $student->id)->firstOrFail();
    Attempt::whereKey($attempt->id)->update(['created_at' => now()->subHours(4)]);

    $this->artisan('attempts:close-old')->assertSuccessful();
    expect($attempt->fresh()->finished_at)->toBeNull();

    $result = app(MockResultService::class)->result($student->fresh());
    expect($result['ready'])->toBeFalse()
        ->and($result['listening'])->toBeNull()
        ->and($result['missing'])->toContain('listening', 'reading', 'writing');

    // The candidate can still log in for the written exam.
    $device = registerDesktopDevice();
    desktopLogin($device, $student->code);

    // Already closed by the old bug: still not ready (no 0 bands) while the window is open.
    $attempt->fresh()->forceFill(['finished_at' => now(), 'device_id' => null])->save();
    expect(app(MockResultService::class)->result($student->fresh())['ready'])->toBeFalse();

    // Once the mock window is over, an abandoned Speaking-only attempt is closed as before.
    $other = MockStudent::create(['mock_id' => $this->exam['mock']->id, 'name' => 'Other', 'code' => 'MOCK-100002', 'phone' => '+998901234568']);
    auditSpeakingScore($other);
    $otherAttempt = Attempt::where('mock_student_id', $other->id)->firstOrFail();
    Attempt::whereKey($otherAttempt->id)->update(['created_at' => now()->subHours(4)]);
    $this->exam['mock']->update(['started_at' => now()->subHours(6), 'finished_at' => now()->subMinute()]);

    $this->artisan('attempts:close-old')->assertSuccessful();
    expect($otherAttempt->fresh()->finished_at)->not->toBeNull();
});

// 2. "Test in use" guards see every module of the mock

test('2) content guards refuse while a mock module (not only mocks.test_id) uses the test', function () {
    $testR = $this->exam['testR'];
    expect($this->exam['mock']->test_id)->toBeNull()->and($testR->inUse())->toBeTrue();

    $section = $this->exam['dragQ1']->section;
    $this->actingAs($this->admin)->delete(route('option.destroy', Option::where('section_id', $section->id)->firstOrFail()))->assertSessionHasErrors('error');
    $this->actingAs($this->admin)->delete(route('question.destroy', $this->exam['dragQ1']))->assertSessionHasErrors('error');
    $this->actingAs($this->admin)->delete(route('section.destroy', $section))->assertSessionHasErrors('error');
    $this->actingAs($this->admin)->delete(route('part.destroy', $this->exam['partR']))->assertSessionHasErrors('error');
    $this->assertDatabaseHas('parts', ['id' => $this->exam['partR']->id]);
    $this->assertDatabaseHas('questions', ['id' => $this->exam['dragQ1']->id]);

    expect(app(MockTestImporter::class)->refusal($this->exam['reading'], true))->not->toBeNull();

    // The mock ended without any attempt: the content is free again.
    $this->exam['mock']->update(['started_at' => now()->subDays(2), 'finished_at' => now()->subDay()]);
    expect($testR->fresh()->inUse())->toBeFalse()
        ->and(app(MockTestImporter::class)->refusal($this->exam['reading'], true))->toBeNull();
    $this->actingAs($this->admin)->delete(route('question.destroy', $this->exam['dragQ1']))->assertSessionHas('success');

    // An ended mock with attempts still protects it.
    app(ExamService::class)->findOrCreateMockAttempt($this->exam['student']);
    expect($testR->fresh()->inUse())->toBeTrue();
});

// 3. toPractice / test delete never touch mocks

test('3) a test used by a mock module is neither moved to practice nor deleted with its mocks', function () {
    $this->admin = makeSuperAdmin(); // moving to the practice Test Bank is the platform owner's
    $testW = $this->exam['testW'];
    $folder = Folder::create(['name' => 'Practice', 'user_id' => $this->admin->id, 'active' => 1]);

    $this->actingAs($this->admin)->post(route('mock-bank.to-practice', $testW), ['folder_id' => $folder->id])
        ->assertSessionHas('error', __('test_in_use_cannot_move'));
    expect($testW->fresh()->isMock())->toBeTrue();

    $this->actingAs($this->admin)->delete(route('test.destroy', $testW))->assertSessionHasErrors('error');

    // Even after the mock ended (no attempts) the test delete refuses instead of deleting the mock.
    $this->exam['mock']->update(['started_at' => now()->subDays(2), 'finished_at' => now()->subDay()]);
    $this->actingAs($this->admin)->delete(route('test.destroy', $testW))->assertSessionHasErrors(['error' => __('test_used_by_mock')]);
    $this->assertDatabaseHas('tests', ['id' => $testW->id]);
    $this->assertDatabaseHas('mocks', ['id' => $this->exam['mock']->id]);
    $this->assertDatabaseHas('mock_students', ['id' => $this->exam['student']->id]);

    expect(fn () => $testW->fresh()->delete())->toThrow(RuntimeException::class);
    $this->assertDatabaseHas('mocks', ['id' => $this->exam['mock']->id]);

    // The ended mock no longer blocks the move to practice.
    $this->actingAs($this->admin)->post(route('mock-bank.to-practice', $testW), ['folder_id' => $folder->id])->assertSessionHas('success');
});

// 4. Modules lock on the first attempt

test('4) mock modules lock as soon as a candidate logs in, before any module starts', function () {
    $mock = $this->exam['mock'];
    expect($mock->modulesLocked())->toBeFalse();

    desktopLogin(registerDesktopDevice(), $this->exam['student']->code);
    expect(AttemptType::count())->toBe(0)->and($mock->modulesLocked())->toBeTrue();

    $this->actingAs($this->admin)->put(route('mock.update', $mock), [
        'name' => $mock->name, 'started_at' => now()->subHour()->format('Y-m-d H:i'), 'finished_at' => now()->addHours(3)->format('Y-m-d H:i'),
        'modules' => [$this->exam['reading']->id, $this->exam['writing']->id],
    ])->assertSessionHasErrors('modules');
    expect($mock->modules()->count())->toBe(3);
});

// 5. Mock / candidate delete

test('5) a mock or candidate with an unfinished attempt cannot be deleted; deleting revokes exam tokens', function () {
    $mock = $this->exam['mock'];
    $student = $this->exam['student'];
    desktopLogin(registerDesktopDevice(), $student->code);
    expect($student->tokens()->count())->toBe(1);

    $this->actingAs($this->admin)->delete(route('mock-student.destroy', $student))->assertSessionHas('error', __('candidate_has_running_attempt'));
    $this->actingAs($this->admin)->delete(route('mock.destroy', $mock))->assertSessionHas('error', __('mock_has_running_attempt'));
    $this->assertDatabaseHas('mocks', ['id' => $mock->id]);
    $this->assertDatabaseHas('mock_students', ['id' => $student->id]);

    Attempt::where('mock_student_id', $student->id)->update(['finished_at' => now()]);

    // A second candidate (no attempt) with a token: deleted with the mock, token revoked.
    $other = MockStudent::create(['mock_id' => $mock->id, 'name' => 'Other', 'code' => 'MOCK-100003', 'phone' => '+998901234569']);
    $other->createToken('exam:test', ['exam']);

    $this->actingAs($this->admin)->delete(route('mock-student.destroy', $student))->assertSessionHas('success');
    expect(PersonalAccessToken::where('tokenable_type', MockStudent::class)->where('tokenable_id', $student->id)->count())->toBe(0);

    $this->actingAs($this->admin)->delete(route('mock.destroy', $mock))->assertRedirect(route('mock.index'));
    $this->assertDatabaseMissing('mocks', ['id' => $mock->id]);
    expect(PersonalAccessToken::count())->toBe(0);
});

// 6. Device block

test('6) a PC cannot be blocked or deleted while an exam runs on it', function () {
    $token = registerDesktopDevice();
    desktopLogin($token, $this->exam['student']->code);
    $device = Device::where('machine_id', 'MACHINE-1')->firstOrFail();
    $attempt = Attempt::findOrFail($device->current_attempt_id);
    $attempt->forceFill(['last_heartbeat_at' => now()])->save();

    $this->actingAs($this->admin)->post(route('desktop.devices.block', $device))
        ->assertSessionHas('error', __('device_has_running_exam', ['name' => $device->name]));
    expect($device->fresh()->is_blocked)->toBeFalse();
    $this->actingAs($this->admin)->delete(route('desktop.devices.destroy', $device))->assertSessionHas('error');
    $this->assertDatabaseHas('devices', ['id' => $device->id]);

    // The PC went silent: blocking is allowed again.
    $attempt->forceFill(['last_heartbeat_at' => now()->subMinutes(10)])->save();
    $this->actingAs($this->admin)->post(route('desktop.devices.block', $device))->assertSessionHas('success');
    expect($device->fresh()->is_blocked)->toBeTrue();
});

// 7. Attempt delete

test('7) an unfinished attempt cannot be deleted', function () {
    $attempt = app(ExamService::class)->findOrCreateMockAttempt($this->exam['student']);

    $this->actingAs($this->admin)->delete(route('attempt.destroy', $attempt))->assertSessionHas('error', __('attempt_not_finished'));
    $this->assertDatabaseHas('attempts', ['id' => $attempt->id]);
});

// 8. Resume login

test('8) a candidate with an unfinished attempt resumes even when the mock is inactive or rescheduled', function () {
    $device = registerDesktopDevice();
    $student = $this->exam['student'];
    desktopLogin($device, $student->code);

    $this->exam['mock']->update(['active' => 0]);
    desktopApi('POST', 'exam/login', ['code' => $student->code], $device)->assertOk();

    $this->exam['mock']->update(['active' => 1, 'started_at' => now()->addHour(), 'finished_at' => now()->addHours(4)]);
    desktopApi('POST', 'exam/login', ['code' => $student->code], $device)->assertOk();

    // An attempt that only holds an early Speaking band is not a resume: the window still applies.
    $other = MockStudent::create(['mock_id' => $this->exam['mock']->id, 'name' => 'Other', 'code' => 'MOCK-100004', 'phone' => '+998901234560']);
    auditSpeakingScore($other);
    desktopApi('POST', 'exam/login', ['code' => $other->code], $device)->assertStatus(422)->assertJsonPath('code', 'mock_not_started');
});

// 9. Late sync window / late essays

test('9) the result is not ready while late offline answers may still arrive; a late essay reopens the Writing review', function () {
    $student = $this->exam['student'];
    $attempt = auditWrittenExam($student);
    $writing = auditWritingType($attempt);
    $writing->forceFill(['reviewed_at' => now(), 'reviewed_by' => $this->admin->id, 'score' => 6.0])->save();
    auditSpeakingScore($student);
    $attempt->forceFill(['finished_at' => now()])->save();

    $results = app(MockResultService::class);
    expect($results->result($student->fresh())['ready'])->toBeTrue();

    // Listening ended while the PC was offline, within the late-sync cap.
    AttemptType::where('attempt_id', $attempt->id)->where('type_id', $this->exam['listeningType']->id)
        ->update(['offline_at_end' => true, 'finished_at' => now()->subMinutes(5)]);
    expect($results->result($student->fresh())['ready'])->toBeFalse();

    // A late essay arrives after the Writing confirmation: the confirmation is dropped.
    $answer = AttemptAnswer::where('question_id', $this->exam['essayQuestion']->id)->firstOrFail();
    app(ExamService::class)->afterLateSync([['answer' => $answer, 'attempt_type' => $writing]]);
    expect($writing->fresh()->reviewed_at)->toBeNull()->and($writing->fresh()->reviewed_by)->toBeNull();
});

// 10. Writing confirm

test('10) Writing is confirmed only when submitted and scored, unless a manual band is given', function () {
    $attempt = auditWrittenExam($this->exam['student'], essayScore: null, submitWriting: false);
    $writing = auditWritingType($attempt);

    $this->actingAs($this->admin)->post(route('writing-review.confirm', $writing))->assertSessionHas('error', __('writing_not_submitted'));

    $writing->forceFill(['is_submitted' => true])->save();
    $this->actingAs($this->admin)->post(route('writing-review.confirm', $writing))->assertSessionHas('error', __('writing_ai_pending'));
    expect($writing->fresh()->reviewed_at)->toBeNull();

    // Task bands typed in by the Admin cover the pending essay.
    $answer = AttemptAnswer::where('question_id', $this->exam['essayQuestion']->id)->firstOrFail();
    $this->actingAs($this->admin)->post(route('writing-review.confirm', $writing), ['scores' => [$answer->id => 6.5]])->assertSessionHas('success');
    expect($writing->fresh()->reviewed_at)->not->toBeNull();

    // An explicit module band is accepted even before submission.
    $other = MockStudent::create(['mock_id' => $this->exam['mock']->id, 'name' => 'Other', 'code' => 'MOCK-100005', 'phone' => '+998901234561']);
    $otherWriting = AttemptType::create([
        'attempt_id' => app(ExamService::class)->findOrCreateMockAttempt($other)->id,
        'type_id' => $this->exam['writingType']->id, 'is_submitted' => false, 'started_at' => now(),
    ]);
    $this->actingAs($this->admin)->post(route('writing-review.confirm', $otherWriting), ['band' => 5.5])->assertSessionHas('success');
    expect((float) $otherWriting->fresh()->score)->toBe(5.5);
});

// 11. Register response

test('11) device registration returns the offline exit password check value', function () {
    desktopCenterPassword();

    desktopApi('POST', 'device/register', ['machine_id' => 'GUID-X', 'password' => 'center-pass'])
        ->assertOk()
        ->assertJsonPath('approved', false)
        ->assertJsonPath('exit_password_offline', centerSettings()->exit_password_offline);

    expect(centerSettings()->exit_password_offline)->not->toBeNull();
});
