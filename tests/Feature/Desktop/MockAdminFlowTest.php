<?php

use App\Http\Controllers\SpeakingController;
use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\AttemptPart;
use App\Models\AttemptType;
use App\Models\Device;
use App\Models\Folder;
use App\Models\Mock;
use App\Models\MockModule;
use App\Models\MockStudent;
use App\Models\Option;
use App\Models\Part;
use App\Models\Question;
use App\Models\Setting;
use App\Models\Test as ExamTest;
use App\Models\TestType;
use App\Services\CandidateService;
use App\Services\ExamService;
use App\Services\IeltsScoreConverter;
use App\Services\MockBankService;
use App\Services\MockResultService;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Queue;

beforeEach(function () {
    $this->admin = makeUser('Admin');
    $this->exam = makeDesktopExam($this->admin);
});

/**
 * A ready Mock Bank test with one Listening module (one keyed question, audio present).
 */
/**
 * A ready Listening bank module; $usedOn = date of a mock that uses it (reuse rule input).
 */
function bankListening(string $name, ?Carbon\Carbon $usedOn = null): TestType
{
    $test = ExamTest::create([
        'folder_id' => test()->exam['testL']->folder_id, 'name' => $name, 'active' => 1, 'open' => 0, 'audio_path' => 'audio/'.$name.'.mp3',
        'purpose' => ExamTest::PURPOSE_MOCK, 'bank_status' => ExamTest::BANK_READY,
    ]);
    $module = TestType::create(['test_id' => $test->id, 'type_id' => test()->exam['listeningType']->id]);
    $part = Part::create(['test_type_id' => $module->id, 'name' => 'Part 1', 'minute' => 30]);
    $section = makeSection($part, 'fill_blank');
    Question::create(['section_id' => $section->id, 'order' => 1, 'textarea' => 'Q', 'answer_text' => 'x']);

    if ($usedOn) {
        useModuleOn($module, $usedOn);
    }

    return $module;
}

function useModuleOn(TestType $module, Carbon\Carbon $date): Mock
{
    $mock = Mock::create([
        'name' => 'Used '.$module->id.' '.$date->format('Ymd'), 'test_id' => null, 'user_id' => test()->admin->id,
        'slug' => 'used-'.uniqid(), 'started_at' => $date, 'finished_at' => $date->copy()->addHours(4), 'active' => 1,
    ]);
    MockModule::create(['mock_id' => $mock->id, 'type_id' => $module->type_id, 'test_type_id' => $module->id]);

    return $mock;
}

/**
 * Listening 30/40 (7.0), Reading 27/40 (6.5), Writing task band 6.0 (confirmed or not).
 */
function finishWrittenExam(MockStudent $student, bool $reviewWriting = true): Attempt
{
    $exam = test()->exam;
    $attempt = app(ExamService::class)->findOrCreateMockAttempt($student);

    AttemptType::create(['attempt_id' => $attempt->id, 'type_id' => $exam['listeningType']->id, 'is_submitted' => true, 'is_correct_count' => 30, 'started_at' => now(), 'finished_at' => now()]);
    AttemptType::create(['attempt_id' => $attempt->id, 'type_id' => $exam['readingType']->id, 'is_submitted' => true, 'is_correct_count' => 27, 'started_at' => now(), 'finished_at' => now()]);
    $writing = AttemptType::create(['attempt_id' => $attempt->id, 'type_id' => $exam['writingType']->id, 'is_submitted' => true, 'started_at' => now(), 'finished_at' => now()]);

    $part = AttemptPart::create(['attempt_id' => $attempt->id, 'part_id' => $exam['partW']->id, 'started_at' => now(), 'finished_at' => now()]);
    AttemptAnswer::create(['attempt_part_id' => $part->id, 'question_id' => $exam['essayQuestion']->id, 'answer_text' => str_repeat('word ', 260), 'score' => 6.0, 'review_note_ai' => 'AI feedback']);
    AttemptPart::create(['attempt_id' => $attempt->id, 'part_id' => $exam['partL']->id, 'started_at' => now(), 'finished_at' => now()]);
    $writing->recalculateIsCorrectCount();

    if ($reviewWriting) {
        $writing->forceFill(['reviewed_at' => now(), 'reviewed_by' => test()->admin->id])->save();
    }

    return $attempt->fresh();
}

/*
|--------------------------------------------------------------------------
| Mock Bank
|--------------------------------------------------------------------------
*/

test('a test is marked ready only when every module passes the readiness check', function () {
    config(['desktop.questions_per_paper' => null]); // small fixtures, not a full 40-question paper
    $test = $this->exam['testL'];
    $test->update(['bank_status' => ExamTest::BANK_DRAFT, 'audio_path' => 'audio/l.mp3']);

    // The multiple-choice question has a correct option and the fill question an answer_text: ready.
    expect(app(MockBankService::class)->testReadiness($test)['ready'])->toBeTrue();

    // A question without any key blocks it.
    $section = makeSection($this->exam['partL'], 'fill_blank');
    $unkeyed = Question::create(['section_id' => $section->id, 'order' => 3, 'textarea' => 'No key']);

    $this->actingAs($this->admin)->post(route('mock-bank.status', $test), ['status' => 'ready'])->assertSessionHas('error');
    expect($test->fresh()->bank_status)->toBe(ExamTest::BANK_DRAFT);

    Option::create(['question_id' => $unkeyed->id, 'textarea' => 'A', 'is_correct' => 1]);
    $this->actingAs($this->admin)->post(route('mock-bank.status', $test), ['status' => 'ready'])->assertSessionHas('success');
    expect($test->fresh()->bank_status)->toBe(ExamTest::BANK_READY);

    // Listening without audio is not ready.
    $test->update(['audio_path' => null]);
    expect(app(MockBankService::class)->moduleIssues($this->exam['listening']->fresh()))->toContain('no_audio');

    $this->actingAs($this->admin)->post(route('mock-bank.status', $test), ['status' => 'archived'])->assertSessionHas('success');
    expect($test->fresh()->bank_status)->toBe(ExamTest::BANK_ARCHIVED);
});

test('moving a bank test to practice makes it an open practice test in the chosen folder', function () {
    $folder = Folder::create(['name' => 'Practice folder', 'user_id' => $this->admin->id, 'active' => 1]);

    // A folderless bank test needs a target folder.
    $this->actingAs($this->admin)->post(route('mock-bank.to-practice', $this->exam['testR']))->assertSessionHasErrors('folder_id');
    $this->actingAs($this->admin)->post(route('mock-bank.to-practice', $this->exam['testR']), ['folder_id' => 999999])->assertSessionHasErrors('folder_id');
    expect($this->exam['testR']->fresh()->purpose)->toBe(ExamTest::PURPOSE_MOCK);

    $this->actingAs($this->admin)->post(route('mock-bank.to-practice', $this->exam['testR']), ['folder_id' => $folder->id])->assertSessionHas('success');

    $test = $this->exam['testR']->fresh();
    expect($test->purpose)->toBe(ExamTest::PURPOSE_PRACTICE)->and((int) $test->open)->toBe(1)->and((int) $test->folder_id)->toBe($folder->id);

    // Repeating it (e.g. a double click) is a harmless no-op.
    $this->actingAs($this->admin)->post(route('mock-bank.to-practice', $test))->assertSessionHas('success');
    expect($test->fresh()->purpose)->toBe(ExamTest::PURPOSE_PRACTICE);
});

test('the mock bank page lists only mock tests with their modules', function () {
    makeTestContent($this->admin, 'Reading', ['name' => 'Practice only']);

    $this->actingAs($this->admin)->get(route('mock-bank.index'))->assertOk()
        ->assertInertia(fn ($page) => $page->component('mock-bank/index')
            ->has('tests', 3)
            ->where('tests', fn ($tests) => collect($tests)->pluck('name')->sort()->values()->all() === ['Bank L', 'Bank R', 'Bank W']));
});

test('mock tests are created without a folder, even when one is sent', function () {
    $folder = Folder::create(['name' => 'Some folder', 'user_id' => $this->admin->id, 'active' => 1]);

    $this->actingAs($this->admin)->post(route('test.store'), ['name' => 'New bank test', 'purpose' => 'mock', 'open' => 1])
        ->assertSessionHasNoErrors();
    $this->actingAs($this->admin)->post(route('test.store'), ['folder_id' => $folder->id, 'name' => 'Second bank test', 'purpose' => 'mock'])
        ->assertSessionHasNoErrors();

    foreach (['New bank test', 'Second bank test'] as $name) {
        $test = ExamTest::where('name', $name)->firstOrFail();
        expect($test->purpose)->toBe('mock')->and((int) $test->open)->toBe(0)->and($test->bank_status)->toBe('draft')
            ->and($test->folder_id)->toBeNull()
            ->and($test->types()->count())->toBeGreaterThan(0);
    }
});

test('practice tests still require a folder', function () {
    $this->actingAs($this->admin)->post(route('test.store'), ['name' => 'Loose practice test', 'purpose' => 'practice'])
        ->assertSessionHasErrors('folder_id');
    expect(ExamTest::where('name', 'Loose practice test')->exists())->toBeFalse();
});

test('reception and students cannot create mock bank tests', function () {
    foreach (['Reception', 'Student'] as $role) {
        $this->actingAs(makeUser($role))->post(route('test.store'), ['name' => "Bank by {$role}", 'purpose' => 'mock'])->assertForbidden();
    }
    expect(ExamTest::where('name', 'like', 'Bank by%')->exists())->toBeFalse();
});

test('admins edit the content of folderless bank tests; reception and students cannot', function () {
    $part = $this->exam['partR'];
    expect($this->exam['testR']->fresh()->folder_id)->toBeNull();

    $this->actingAs($this->admin)->get(route('test-type.show', $this->exam['reading']->id))->assertOk();
    $this->actingAs($this->admin)->post(route('part.update', $part), ['name' => 'Renamed passage', 'test_type_id' => $part->test_type_id])
        ->assertSessionHasNoErrors();
    expect($part->fresh()->name)->toBe('Renamed passage');

    foreach (['Reception', 'Student'] as $role) {
        $user = makeUser($role);
        $this->actingAs($user)->get(route('test-type.show', $this->exam['reading']->id))->assertForbidden();
        $this->actingAs($user)->post(route('part.update', $part), ['name' => 'Hacked', 'test_type_id' => $part->test_type_id])->assertForbidden();
    }
    expect($part->fresh()->name)->toBe('Renamed passage');
});

/*
|--------------------------------------------------------------------------
| Module picking (14-day reuse rule)
|--------------------------------------------------------------------------
*/

test('auto pick takes the least recently used module and skips modules used within 14 days', function () {
    $bank = app(MockBankService::class);
    // $this->exam['listening'] is used by the running mock (started an hour ago).

    $old = bankListening('Old', now()->subDays(20));
    $older = bankListening('Older', now()->subDays(40));
    $recent = bankListening('Recent', now()->subDays(13));

    expect($bank->autoPick()['Listening']?->id)->toBe($older->id);

    $never = bankListening('Never');
    expect($bank->autoPick()['Listening']?->id)->toBe($never->id);

    // Nothing outside the 14-day window: no automatic pick.
    foreach ([$old, $older, $never] as $module) {
        useModuleOn($module, now()->subDays(2));
    }
    expect($bank->autoPick()['Listening'])->toBeNull()
        ->and($bank->isRecentlyUsed($recent))->toBeTrue()
        ->and($bank->isRecentlyUsed($recent, now()->addDays(2)))->toBeFalse();
});

test('the reuse rule looks at the exam dates of other mocks in both directions', function () {
    $bank = app(MockBankService::class);
    $planned = bankListening('Planned');
    useModuleOn($planned, now()->addDays(10));

    // A mock in 10 days blocks an exam today, but not one in 30 days.
    expect($bank->isRecentlyUsed($planned))->toBeTrue()
        ->and($bank->isRecentlyUsed($planned, now()->addDays(30)))->toBeFalse()
        ->and($bank->autoPick(now()->addDays(30))['Listening']?->id)->not->toBeNull();

    // The mock being edited does not count against itself.
    $own = useModuleOn(bankListening('Own'), now()->addDays(60));
    $ownModule = TestType::find($own->modules()->value('test_type_id'));
    expect($bank->isRecentlyUsed($ownModule, now()->addDays(60)))->toBeTrue()
        ->and($bank->isRecentlyUsed($ownModule, now()->addDays(60), $own->id))->toBeFalse();

    // last_used_at = latest exam date (display only), recomputed from the mocks.
    $bank->refreshLastUsed([$planned->id]);
    expect($planned->fresh()->last_used_at->isSameDay(now()->addDays(10)))->toBeTrue();
});

test('draft and archived bank tests are never picked', function () {
    $draft = bankListening('Draft', null);
    $draft->test->update(['bank_status' => ExamTest::BANK_DRAFT]);
    $this->exam['mock']->update(['started_at' => now()->subDays(30), 'finished_at' => now()->subDays(30)->addHours(4)]);

    expect(app(MockBankService::class)->autoPick()['Listening']?->id)->toBe($this->exam['listening']->id);
});

test('creating a mock saves its modules, the legacy test_id and last_used_at', function () {
    $this->actingAs($this->admin)->post(route('mock.store'), [
        'name' => 'Mock 20.11',
        'started_at' => now()->addDay()->format('Y-m-d H:i'),
        'finished_at' => now()->addDay()->addHours(4)->format('Y-m-d H:i'),
        'active' => 1,
        'modules' => [$this->exam['writing']->id, $this->exam['listening']->id, $this->exam['reading']->id],
        'speaking_starts_at' => now()->addDay()->addHours(4)->format('Y-m-d H:i'),
        'speaking_slot_minutes' => 12,
    ])->assertSessionHasNoErrors()->assertRedirect();

    $mock = Mock::where('name', 'Mock 20.11')->firstOrFail();
    expect($mock->require_desktop)->toBeTrue()
        ->and((int) $mock->test_id)->toBe($this->exam['testL']->id)
        ->and($mock->speaking_slot_minutes)->toBe(12)
        ->and($mock->modules()->pluck('test_type_id')->sort()->values()->all())->toBe(collect([$this->exam['listening']->id, $this->exam['reading']->id, $this->exam['writing']->id])->sort()->values()->all())
        ->and($this->exam['listening']->fresh()->last_used_at)->not->toBeNull();
});

test('a mock refuses modules that are not ready and two modules of one type', function () {
    $draft = bankListening('Draft');
    $draft->test->update(['bank_status' => ExamTest::BANK_DRAFT]);
    $other = bankListening('Other');

    $payload = fn (array $modules) => [
        'name' => 'Bad', 'started_at' => now()->format('Y-m-d H:i'), 'finished_at' => now()->addHour()->format('Y-m-d H:i'), 'modules' => $modules,
    ];

    $this->actingAs($this->admin)->post(route('mock.store'), $payload([$draft->id]))->assertSessionHasErrors('modules');
    $this->actingAs($this->admin)->post(route('mock.store'), $payload([$other->id, $this->exam['listening']->id]))->assertSessionHasErrors('modules');
    $this->actingAs($this->admin)->post(route('mock.store'), $payload([]))->assertSessionHasErrors('modules');
});

test('changing a module recomputes last_used_at from the exam dates and keeps legacy mocks editable', function () {
    $mock = $this->exam['mock'];
    $replacement = bankListening('Replacement');

    $this->actingAs($this->admin)->put(route('mock.update', $mock), [
        'name' => $mock->name, 'started_at' => now()->format('Y-m-d H:i'), 'finished_at' => now()->addHours(3)->format('Y-m-d H:i'),
        'modules' => [$replacement->id, $this->exam['reading']->id, $this->exam['writing']->id],
    ])->assertSessionHasNoErrors();

    expect(MockModule::where('mock_id', $mock->id)->where('type_id', $this->exam['listeningType']->id)->value('test_type_id'))->toBe($replacement->id)
        ->and($replacement->fresh()->last_used_at)->not->toBeNull()
        ->and($this->exam['listening']->fresh()->last_used_at)->toBeNull()
        ->and((int) $mock->fresh()->test_id)->toBe($replacement->test_id);

    $legacyContent = makeTestContent($this->admin, 'Reading');
    $legacy = Mock::create(['name' => 'Legacy', 'test_id' => $legacyContent['test']->id, 'user_id' => $this->admin->id, 'slug' => 'legacy-1', 'started_at' => now(), 'finished_at' => now()->addHour(), 'active' => 1]);

    $this->actingAs($this->admin)->get(route('mock.show', $legacy))->assertOk();
    $this->actingAs($this->admin)->put(route('mock.update', $legacy), [
        'name' => 'Legacy renamed', 'started_at' => now()->format('Y-m-d H:i'), 'finished_at' => now()->addHour()->format('Y-m-d H:i'),
    ])->assertSessionHasNoErrors();
    expect($legacy->fresh()->name)->toBe('Legacy renamed')->and($legacy->modules()->count())->toBe(0);
});

/*
|--------------------------------------------------------------------------
| Candidates
|--------------------------------------------------------------------------
*/

test('phones are normalized to +998XXXXXXXXX', function (string $input, ?string $expected) {
    expect(CandidateService::normalizePhone($input))->toBe($expected);
})->with([
    ['90 123 45 67', '+998901234567'],
    ['+998 (90) 123-45-67', '+998901234567'],
    ['998901234567', '+998901234567'],
    ['12345', null],
    ['+7 901 234 56 78', null],
    ['', null],
]);

test('reception adds candidates in bulk with normalized phones; a phone is mandatory', function () {
    $reception = makeUser('Reception');
    $mock = $this->exam['mock'];

    $this->actingAs($reception)->post(route('mock-student.store'), [
        'mock_id' => $mock->id,
        'candidates' => [['name' => 'Anvar', 'phone' => '90 111 22 33'], ['name' => 'Malika', 'phone' => '+998 93 444 55 66']],
    ])->assertSessionHasNoErrors()->assertSessionHas('success');

    expect(MockStudent::where('mock_id', $mock->id)->pluck('phone', 'name')->all())
        ->toMatchArray(['Anvar' => '+998901112233', 'Malika' => '+998934445566']);

    $this->actingAs($reception)->post(route('mock-student.store'), ['mock_id' => $mock->id, 'candidates' => [['name' => 'No phone', 'phone' => '']]])
        ->assertSessionHasErrors('candidates.0.phone');
    $this->actingAs($reception)->post(route('mock-student.store'), ['mock_id' => $mock->id, 'candidates' => [['name' => 'Bad', 'phone' => '123']]])
        ->assertSessionHasErrors('candidates.0.phone');
});

test('a phone that already sat one of the mock modules is reported as a repeat candidate', function () {
    // Ali (+998901234567) sat Listening of the first mock.
    finishWrittenExam($this->exam['student']);

    $next = Mock::create(['name' => 'Next', 'user_id' => $this->admin->id, 'slug' => 'next-1', 'started_at' => now(), 'finished_at' => now()->addHours(3), 'active' => 1]);
    MockModule::create(['mock_id' => $next->id, 'type_id' => $this->exam['listeningType']->id, 'test_type_id' => $this->exam['listening']->id]);
    $fresh = bankListening('Fresh');
    $other = Mock::create(['name' => 'Other', 'user_id' => $this->admin->id, 'slug' => 'other-1', 'started_at' => now(), 'finished_at' => now()->addHours(3), 'active' => 1]);
    MockModule::create(['mock_id' => $other->id, 'type_id' => $fresh->type_id, 'test_type_id' => $fresh->id]);

    $response = $this->actingAs(makeUser('Reception'))->postJson(route('mock-student.check-repeats'), [
        'mock_id' => $next->id, 'phones' => ['90 123 45 67', '+998935556677', 'bad'],
    ])->assertOk();

    expect($response->json('data.0.repeats.0.test_type_id'))->toBe($this->exam['listening']->id)
        ->and($response->json('data.0.repeats.0.type'))->toBe('Listening')
        ->and($response->json('data.1.repeats'))->toBe([])
        ->and($response->json('data.2.valid'))->toBeFalse();

    // A different module: no repeat. Adding the repeat candidate warns.
    expect(app(CandidateService::class)->repeatModules($other, '+998901234567'))->toBe([]);

    $this->actingAs($this->admin)->post(route('mock-student.store'), ['mock_id' => $next->id, 'candidates' => [['name' => 'Ali again', 'phone' => '901234567']]])
        ->assertSessionHas('warning');
});

test('only admins delete candidates', function () {
    $student = $this->exam['student'];

    $this->actingAs(makeUser('Reception'))->delete(route('mock-student.destroy', $student))->assertForbidden();
    $this->actingAs($this->admin)->delete(route('mock-student.destroy', $student))->assertSessionHas('success');
    expect(MockStudent::find($student->id))->toBeNull();
});

/*
|--------------------------------------------------------------------------
| Reception, results
|--------------------------------------------------------------------------
*/

test('check-in, statuses, readiness, result sheets and delivery', function () {
    $reception = makeUser('Reception');
    $student = $this->exam['student'];
    $results = app(MockResultService::class);

    expect($results->status($student->fresh()))->toBe('not_arrived');

    $this->actingAs($reception)->post(route('reception.check-in', $student))->assertSessionHas('success');
    expect($results->status($student->fresh()))->toBe('checked_in');

    finishWrittenExam($student, reviewWriting: false);
    $student->refresh()->load('attempt.attempt_types.type');
    $result = $results->result($student);
    expect($result['ready'])->toBeFalse()
        ->and($result['missing'])->toBe(['writing_review', 'speaking'])
        ->and($results->status($student))->toBe('written_done');

    $student->forceFill(['speaking_at' => now()->addHour()])->save();
    expect($results->status($student->fresh()))->toBe('speaking_waiting');

    // Not ready: no sheet, no delivery.
    $this->actingAs($reception)->get(route('reception.result-sheets', ['ids' => $student->id]))->assertStatus(422);
    $this->actingAs($reception)->post(route('reception.deliver', $student))->assertSessionHas('error');

    // Writing confirmed by the Admin, Speaking 6.0 → L 7.0, R 6.5, W 6.0, S 6.0 = 6.375 → 6.5
    $writing = AttemptType::where('attempt_id', $student->attempt->id)->where('type_id', $this->exam['writingType']->id)->firstOrFail();
    $this->actingAs($this->admin)->post(route('writing-review.confirm', $writing))->assertSessionHas('success');
    $this->actingAs($this->admin)->post(route('speaking.score', $student), ['fluency' => 6, 'lexical' => 6, 'grammar' => 6, 'pronunciation' => 6])->assertSessionHas('success');

    $result = $results->result($student->fresh());
    expect($result['ready'])->toBeTrue()
        ->and([$result['listening'], $result['reading'], $result['writing'], $result['speaking'], $result['overall']])->toBe([7.0, 6.5, 6.0, 6.0, 6.5])
        ->and($results->status($student->fresh()))->toBe('result_ready');

    $this->actingAs($reception)->get(route('reception.result-sheets', ['ids' => $student->id]))
        ->assertOk()->assertHeader('Content-Type', 'application/pdf');
    expect($student->fresh()->result_printed_at)->not->toBeNull();

    $this->actingAs($reception)->post(route('reception.deliver', $student))->assertSessionHas('success');
    $student->refresh();
    expect($student->result_delivered_at)->not->toBeNull()
        ->and((int) $student->delivered_by)->toBe($reception->id)
        ->and($results->status($student))->toBe('delivered');
});

test('the reception page lists the day\'s candidates with their status', function () {
    $this->actingAs(makeUser('Reception'))->get(route('reception.index', ['search' => '1234567']))->assertOk()
        ->assertInertia(fn ($page) => $page->component('reception/index')
            ->has('mocks', 1)
            ->has('candidates', 1)
            ->where('candidates.0.status', 'not_arrived')
            ->where('candidates.0.code', 'MOCK-100001'));

    $this->actingAs(makeUser('Reception'))->get(route('reception.index', ['date' => now()->addDays(5)->toDateString()]))
        ->assertInertia(fn ($page) => $page->has('mocks', 0)->has('candidates', 0));
});

test('overall band uses IELTS rounding', function (array $bands, float $expected) {
    expect(IeltsScoreConverter::calculateOverallBand($bands))->toBe($expected);
})->with([
    'x.0' => [[6.0, 6.0, 6.0, 6.0], 6.0],
    '.125 down' => [[6.0, 6.0, 6.0, 6.5], 6.0],
    '.25 up to .5' => [[6.0, 6.0, 6.5, 6.5], 6.5],
    '.375 to .5' => [[7.0, 6.5, 6.0, 6.0], 6.5],
    '.625 to .5' => [[6.5, 6.5, 6.5, 7.0], 6.5],
    '.75 up to whole' => [[7.0, 7.0, 6.5, 6.5], 7.0],
    '.875 up' => [[7.0, 7.0, 7.0, 6.5], 7.0],
]);

/*
|--------------------------------------------------------------------------
| Speaking, Writing
|--------------------------------------------------------------------------
*/

test('speaking band is the IELTS-rounded average of the four criteria', function (array $criteria, float $expected) {
    expect(SpeakingController::band($criteria))->toBe($expected);
})->with([
    [[6.0, 6.0, 6.5, 6.5], 6.5],
    [[7.0, 7.0, 7.0, 6.5], 7.0],
    [[5.0, 5.0, 5.0, 5.5], 5.0],
    [[6.0, 6.5, 6.5, 6.5], 6.5],
    [[8.0, 8.5, 8.5, 8.0], 8.5],
]);

test('scoring speaking creates the attempt and the Speaking attempt_type with the criteria', function () {
    $student = $this->exam['student'];
    expect(Attempt::where('mock_student_id', $student->id)->exists())->toBeFalse();

    $this->actingAs($this->admin)->post(route('speaking.score', $student), [
        'fluency' => 6.5, 'lexical' => 6, 'grammar' => 6, 'pronunciation' => 7, 'note' => 'Good',
    ])->assertSessionHas('success');

    $type = AttemptType::whereHas('type', fn ($q) => $q->where('name', 'Speaking'))->firstOrFail();
    expect((float) $type->score)->toBe(6.5)
        ->and($type->comment)->toContain('Fluency & Coherence: 6.5')->toContain('Pronunciation: 7.0')->toContain('Good')
        ->and((int) $type->attempt->mock_student_id)->toBe($student->id);

    $this->actingAs($this->admin)->post(route('speaking.score', $student), ['fluency' => 6.3, 'lexical' => 6, 'grammar' => 6, 'pronunciation' => 7])
        ->assertSessionHasErrors('fluency');
});

test('speaking slots are assigned consecutively from the speaking start', function () {
    $mock = $this->exam['mock'];
    $mock->update(['speaking_starts_at' => now()->setTime(15, 0), 'speaking_slot_minutes' => 15]);
    MockStudent::create(['mock_id' => $mock->id, 'name' => 'Bobur', 'code' => 'MOCK-100002', 'phone' => '+998901111111']);
    MockStudent::create(['mock_id' => $mock->id, 'name' => 'Aziz', 'code' => 'MOCK-100003', 'phone' => '+998902222222']);

    $this->actingAs($this->admin)->post(route('speaking.auto-assign', $mock), ['order' => 'name'])->assertSessionHas('success');

    $slots = MockStudent::where('mock_id', $mock->id)->orderBy('name')->get()->mapWithKeys(fn ($s) => [$s->name => $s->speaking_at->format('H:i')])->all();
    expect($slots)->toBe(['Ali Valiyev' => '15:00', 'Aziz' => '15:15', 'Bobur' => '15:30']);

    $this->actingAs($this->admin)->post(route('speaking.slot', $this->exam['student']), ['speaking_at' => now()->format('Y-m-d').' 16:45'])->assertSessionHas('success');
    expect($this->exam['student']->fresh()->speaking_at->format('H:i'))->toBe('16:45');
});

test('writing review shows AI bands and confirm may adjust the task band', function () {
    $attempt = finishWrittenExam($this->exam['student'], reviewWriting: false);
    $writing = AttemptType::where('attempt_id', $attempt->id)->where('type_id', $this->exam['writingType']->id)->firstOrFail();
    $answer = AttemptAnswer::where('question_id', $this->exam['essayQuestion']->id)->firstOrFail();

    $this->actingAs($this->admin)->get(route('writing-review.index'))->assertOk()
        ->assertInertia(fn ($page) => $page->component('writing-review/index')
            ->has('items', 1)
            ->where('items.0.ai_band', fn ($band) => (float) $band === 6.0)
            ->where('items.0.essays.0.feedback', 'AI feedback'));

    $this->actingAs($this->admin)->post(route('writing-review.confirm', $writing), ['scores' => [$answer->id => 7.0]])->assertSessionHas('success');

    $writing->refresh();
    expect($writing->reviewed_at)->not->toBeNull()
        ->and((int) $writing->reviewed_by)->toBe($this->admin->id)
        ->and((float) $writing->score)->toBe(7.0)
        ->and((float) $answer->fresh()->score)->toBe(7.0);

    $this->actingAs($this->admin)->get(route('writing-review.index'))->assertInertia(fn ($page) => $page->has('items', 0));

    // A direct band override wins.
    $this->actingAs($this->admin)->post(route('writing-review.confirm', $writing), ['band' => 5.5])->assertSessionHas('success');
    expect(app(MockResultService::class)->writingBand($writing->fresh()))->toBe(5.5);
});

/*
|--------------------------------------------------------------------------
| Monitor JSON
|--------------------------------------------------------------------------
*/

test('monitor actions answer JSON to fetch requests', function () {
    $attempt = app(ExamService::class)->findOrCreateMockAttempt($this->exam['student']);
    app(ExamService::class)->startModule($attempt, $this->exam['listening']);

    $this->actingAs($this->admin)->postJson(route('monitor.pause', $attempt))
        ->assertOk()->assertJsonPath('ok', true)->assertJsonPath('attempt.paused', true)->assertJsonPath('attempt.module', 'Listening');

    $this->actingAs($this->admin)->postJson(route('monitor.resume', $attempt))->assertOk()->assertJsonPath('attempt.paused', false);
    $this->actingAs($this->admin)->postJson(route('monitor.extra-time', $attempt), ['minutes' => 0])->assertStatus(422);
    $this->actingAs($this->admin)->postJson(route('monitor.extra-time', $attempt), ['minutes' => 10])->assertOk()->assertJsonPath('ok', true);

    $this->actingAs(makeUser('Reception'))->postJson(route('monitor.pause', $attempt))->assertForbidden();
    $this->actingAs(makeUser('Reception'))->postJson(route('monitor.unlock', $attempt))->assertOk()->assertJsonPath('attempt.unlock_requested', true);

    $this->actingAs($this->admin)->postJson(route('monitor.force-submit', $attempt))->assertOk()->assertJsonPath('attempt.finished', true);
    $this->actingAs($this->admin)->postJson(route('monitor.pause', $attempt))->assertStatus(409)->assertJsonPath('ok', false);

    // Inertia / form requests still redirect.
    $this->actingAs($this->admin)->post(route('monitor.resume', $attempt))->assertRedirect();
});

test('the monitor page shows module, time left, online state and violations', function () {
    $attempt = app(ExamService::class)->findOrCreateMockAttempt($this->exam['student']);
    app(ExamService::class)->startModule($attempt, $this->exam['listening']);
    $device = Device::factory()->create(['name' => 'PC-07']);
    $attempt->forceFill(['device_id' => $device->id, 'last_heartbeat_at' => now()->subSeconds(20)])->save();
    $attempt->violations()->create(['type' => 'focus_lost', 'occurred_at' => now(), 'detail' => ['seconds' => 3]]);
    $attempt->violations()->create(['type' => 'focus_lost', 'occurred_at' => now()]);

    $this->actingAs(makeUser('Reception'))->get(route('monitor.index', ['mock_id' => $this->exam['mock']->id]))->assertOk()
        ->assertInertia(fn ($page) => $page->component('monitor/index')
            ->where('canControl', false)
            ->where('attempts.0.device', 'PC-07')
            ->where('attempts.0.module', 'Listening')
            ->where('attempts.0.online', true)
            ->where('attempts.0.violations_count', 2)
            ->where('attempts.0.violation_counts.focus_lost', 2)
            ->where('attempts.0.time_left', fn ($left) => $left > 0));
});

/*
|--------------------------------------------------------------------------
| Devices, settings
|--------------------------------------------------------------------------
*/

test('admins approve, block, unblock, rename and delete PCs', function () {
    $device = Device::factory()->create(['is_approved' => false, 'name' => 'PC-01']);

    $this->actingAs($this->admin)->get(route('desktop.devices.index'))->assertOk()
        ->assertInertia(fn ($page) => $page->component('desktop/devices')->where('devices.0.is_approved', false));

    $this->actingAs($this->admin)->post(route('desktop.devices.approve', $device), ['number' => 4])->assertSessionHas('success');
    expect($device->fresh()->is_approved)->toBeTrue()->and($device->fresh()->approved_at)->not->toBeNull()
        ->and($device->fresh()->number)->toBe(4);

    $this->actingAs($this->admin)->post(route('desktop.devices.block', $device));
    expect($device->fresh()->is_blocked)->toBeTrue()->and($device->fresh()->number)->toBe(4);
    $this->actingAs($this->admin)->post(route('desktop.devices.unblock', $device));
    expect($device->fresh()->is_blocked)->toBeFalse();

    $this->actingAs($this->admin)->patch(route('desktop.devices.update', $device), ['name' => 'PC-99']);
    expect($device->fresh()->name)->toBe('PC-99')->and($device->fresh()->number)->toBe(4);

    $this->actingAs($this->admin)->delete(route('desktop.devices.destroy', $device));
    expect(Device::find($device->id))->toBeNull();
});

test('approving a PC requires a free number from 1 to 999', function () {
    Device::factory()->approved(1)->create(['name' => 'A']);
    Device::factory()->approved(2)->create(['name' => 'B']);
    Device::factory()->approved(4)->create(['name' => 'D']);
    $pending = Device::factory()->create(['name' => 'New', 'is_approved' => false]);

    // The page suggests the lowest free number and lists pending PCs first, then by number.
    $this->actingAs($this->admin)->get(route('desktop.devices.index'))->assertOk()
        ->assertInertia(fn ($page) => $page->component('desktop/devices')
            ->where('nextNumber', 3)
            ->where('devices.0.name', 'New')->where('devices.0.number', null)
            ->where('devices.1.number', 1)->where('devices.2.number', 2)->where('devices.3.number', 4));

    foreach ([[], ['number' => null], ['number' => 0], ['number' => 1000], ['number' => 'x'], ['number' => 2]] as $body) {
        $this->actingAs($this->admin)->post(route('desktop.devices.approve', $pending), $body)->assertSessionHasErrors('number');
    }
    expect($pending->fresh()->is_approved)->toBeFalse();

    $this->actingAs($this->admin)->post(route('desktop.devices.approve', $pending), ['number' => 3])->assertSessionHas('success');
    expect($pending->fresh()->number)->toBe(3)->and($pending->fresh()->is_approved)->toBeTrue()
        ->and(Device::nextFreeNumber())->toBe(5);
});

test('admins change the number of a PC (unique among PCs)', function () {
    $a = Device::factory()->approved(1)->create();
    $b = Device::factory()->approved(2)->create();

    $this->actingAs($this->admin)->patch(route('desktop.devices.update', $b), ['number' => 1])->assertSessionHasErrors('number');
    $this->actingAs($this->admin)->patch(route('desktop.devices.update', $b), ['number' => 0])->assertSessionHasErrors('number');
    expect($b->fresh()->number)->toBe(2);

    // Keeping its own number is fine.
    $this->actingAs($this->admin)->patch(route('desktop.devices.update', $a), ['number' => 1])->assertSessionHasNoErrors();
    $this->actingAs($this->admin)->patch(route('desktop.devices.update', $b), ['number' => 7])->assertSessionHasNoErrors();
    expect($b->fresh()->number)->toBe(7)->and($b->fresh()->is_approved)->toBeTrue();
});

test('reception and students cannot approve or renumber PCs', function () {
    $device = Device::factory()->create(['is_approved' => false]);

    foreach ([makeUser('Reception'), makeUser('Student')] as $user) {
        $this->actingAs($user)->post(route('desktop.devices.approve', $device), ['number' => 5])->assertForbidden();
        $this->actingAs($user)->patch(route('desktop.devices.update', $device), ['number' => 5])->assertForbidden();
    }

    expect($device->fresh()->is_approved)->toBeFalse()->and($device->fresh()->number)->toBeNull();
});

test('the monitor and reception show the PC number and the monitor is ordered by it', function () {
    $other = MockStudent::create([
        'mock_id' => $this->exam['mock']->id, 'name' => 'Aaron First', 'code' => 'MOCK-100002', 'phone' => '+998900000002',
    ]);
    $exam = app(ExamService::class);
    $a1 = $exam->findOrCreateMockAttempt($this->exam['student']);
    $a2 = $exam->findOrCreateMockAttempt($other);
    $a1->forceFill(['device_id' => Device::factory()->approved(3)->create(['name' => 'PC-C'])->id])->save();
    $a2->forceFill(['device_id' => Device::factory()->approved(9)->create(['name' => 'PC-I'])->id])->save();

    $this->actingAs($this->admin)->get(route('monitor.index', ['mock_id' => $this->exam['mock']->id]))->assertOk()
        ->assertInertia(fn ($page) => $page
            ->where('attempts.0.device_number', 3)->where('attempts.0.device', 'PC-C')
            ->where('attempts.1.device_number', 9));

    $this->actingAs(makeUser('Reception'))->get(route('reception.index', ['mock_id' => $this->exam['mock']->id]))->assertOk()
        ->assertInertia(fn ($page) => $page->where('candidates', fn ($rows) => collect($rows)->contains(fn ($r) => ($r['device']['number'] ?? null) === 3)));
});

test('the devices page shows the latest version from version.json', function () {
    Device::factory()->create(['name' => 'PC-01', 'app_version' => '1.1.0']);
    Device::factory()->create(['name' => 'PC-02', 'app_version' => '1.2.0']);

    useReleaseManifest(releaseManifestData(['version' => '1.2.0']));
    $this->actingAs($this->admin)->get(route('desktop.devices.index'))->assertOk()
        ->assertInertia(fn ($page) => $page->component('desktop/devices')
            ->where('latestVersion', '1.2.0')
            ->where('devices.0.name', 'PC-01')->where('devices.0.outdated', true)
            ->where('devices.1.outdated', false));

    useReleaseManifest(null);
    $this->actingAs($this->admin)->get(route('desktop.devices.index'))->assertOk()
        ->assertInertia(fn ($page) => $page->where('latestVersion', null)->where('devices.0.outdated', false));

    useReleaseManifest('{invalid');
    $this->actingAs($this->admin)->get(route('desktop.devices.index'))->assertOk()
        ->assertInertia(fn ($page) => $page->where('latestVersion', null));
});

test('the exit password is stored in both online and offline formats', function () {
    $this->actingAs($this->admin)->post(route('desktop.settings.exit-password'), ['password' => 'secret1', 'password_confirmation' => 'other'])
        ->assertSessionHasErrors('password');
    $this->actingAs($this->admin)->post(route('desktop.settings.exit-password'), ['password' => 'secret12', 'password_confirmation' => 'secret12'])
        ->assertSessionHas('success');

    expect(Setting::checkExitPassword('secret12'))->toBeTrue()
        ->and(Hash::check('secret12', Setting::get(Setting::DESKTOP_EXIT_PASSWORD)))->toBeTrue()
        ->and(Setting::get(Setting::DESKTOP_EXIT_PASSWORD_OFFLINE))->toStartWith('pbkdf2_sha256$');
});

test('writing band weights Task 2 twice as much as Task 1', function () {
    $exam = $this->exam;
    $attempt = finishWrittenExam($exam['student'], reviewWriting: false);

    // Task 2 in a second Writing part (task order = part order)
    $partW2 = Part::create(['test_type_id' => $exam['writing']->id, 'name' => 'Task 2', 'minute' => 40]);
    $task2 = Question::create(['section_id' => makeSection($partW2, 'essay')->id, 'order' => 1, 'textarea' => 'Task 2']);
    $attemptPart2 = AttemptPart::create(['attempt_id' => $attempt->id, 'part_id' => $partW2->id, 'started_at' => now(), 'finished_at' => now()]);

    AttemptAnswer::where('question_id', $exam['essayQuestion']->id)->update(['score' => 5.0]);
    AttemptAnswer::create(['attempt_part_id' => $attemptPart2->id, 'question_id' => $task2->id, 'answer_text' => 'essay', 'score' => 7.0]);

    $writing = AttemptType::where('attempt_id', $attempt->id)->where('type_id', $exam['writingType']->id)->firstOrFail();
    $results = app(MockResultService::class);

    // (5 + 2*7) / 3 = 6.33 -> 6.5 (a plain average would give 6.0)
    expect($results->writingTaskBands($writing))->toBe([5.0, 7.0])
        ->and($results->computedWritingBand($writing))->toBe(6.5);

    // Unanswered Task 2 counts as 0: (5 + 0) / 3 = 1.67 -> 1.5
    AttemptAnswer::where('question_id', $task2->id)->delete();
    expect($results->computedWritingBand($writing))->toBe(1.5);
});

test('re-running AI on a confirmed Writing clears the confirmation', function () {
    Queue::fake();
    $attempt = finishWrittenExam($this->exam['student']);
    $writing = AttemptType::where('attempt_id', $attempt->id)->where('type_id', $this->exam['writingType']->id)->firstOrFail();
    expect($writing->reviewed_at)->not->toBeNull();

    $answer = AttemptAnswer::where('question_id', $this->exam['essayQuestion']->id)->firstOrFail();
    $this->actingAs($this->admin)->post(route('attempt-answer.re-evaluate-ai', $answer))->assertSessionHas('success');

    expect($writing->fresh()->reviewed_at)->toBeNull();
});

test('the devices page offers the published installer for download', function () {
    useReleaseManifest(releaseManifestData(['version' => '9.9.9', 'file' => 'mynine-setup-9.9.9.exe', 'size' => 3]));

    $this->actingAs($this->admin)->get(route('desktop.devices.index'))->assertOk()
        ->assertInertia(fn ($page) => $page->where('installer.version', '9.9.9')
            ->where('installer.url', asset('desktop/mynine-setup-9.9.9.exe'))
            ->where('installer.available', false));

    $file = public_path('desktop/mynine-setup-9.9.9.exe');
    file_put_contents($file, 'exe');
    try {
        $this->actingAs($this->admin)->get(route('desktop.devices.index'))
            ->assertInertia(fn ($page) => $page->where('installer.available', true));
    } finally {
        @unlink($file);
    }

    useReleaseManifest(null);
    $this->actingAs($this->admin)->get(route('desktop.devices.index'))
        ->assertInertia(fn ($page) => $page->where('installer', null));
});
