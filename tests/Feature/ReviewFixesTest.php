<?php

use App\Jobs\EvaluateEssayJob;
use App\Jobs\SendResultEmailJob;
use App\Jobs\SendResultTelegramJob;
use App\Mail\SendResultMail;
use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\AttemptAnswerOption;
use App\Models\AttemptPart;
use App\Models\AttemptType;
use App\Models\Option;
use App\Models\Part;
use App\Models\Question;
use App\Services\AnswerMatcher;
use App\Services\ExamService;
use App\Services\IeltsScoreConverter;
use App\Services\MockResultService;
use App\Services\OpenAIService;
use Illuminate\Support\Facades\Bus;
use Illuminate\Support\Facades\Queue;
use Inertia\Testing\AssertableInertia;

/*
|--------------------------------------------------------------------------
| Regression tests for the review findings (answer keys, scoring, essays, bands)
|--------------------------------------------------------------------------
*/

/**
 * Practice attempt on a Listening test: one "choose TWO" question (A, B correct; C wrong) + one gap question.
 */
function practiceAttempt(string $typeName = 'Listening'): array
{
    $admin = makeUser('SuperAdmin');
    $student = makeUser('Student');
    ['test' => $test, 'testType' => $testType, 'part' => $part] = makeTestContent($admin, $typeName);

    $mr = makeSection($part, 'multiple_response', 'Choose TWO');
    $question = Question::create(['section_id' => $mr->id, 'textarea' => '1-2']);
    $a = Option::create(['question_id' => $question->id, 'textarea' => 'A', 'is_correct' => 1]);
    $b = Option::create(['question_id' => $question->id, 'textarea' => 'B', 'is_correct' => 1]);
    $c = Option::create(['question_id' => $question->id, 'textarea' => 'C', 'is_correct' => 0]);

    $gap = makeSection($part, 'fill_blank');
    $gapQuestion = Question::create(['section_id' => $gap->id, 'textarea' => '3', 'answer_text' => 'carbon']);

    $attempt = Attempt::create(['user_id' => $student->id, 'test_id' => $test->id, 'started_at' => now()]);
    $attemptPart = AttemptPart::create(['attempt_id' => $attempt->id, 'part_id' => $part->id, 'started_at' => now(), 'finished_at' => now()->addHour()]);
    $attemptType = AttemptType::create(['attempt_id' => $attempt->id, 'type_id' => $testType->type_id, 'started_at' => now(), 'finished_at' => now()->addHour()]);

    return compact('admin', 'student', 'test', 'testType', 'part', 'question', 'a', 'b', 'c', 'gapQuestion', 'attempt', 'attemptPart', 'attemptType');
}

function answerWith(array $ctx, array $optionIds): AttemptAnswer
{
    $answer = AttemptAnswer::create(['attempt_part_id' => $ctx['attemptPart']->id, 'question_id' => $ctx['question']->id]);
    foreach ($optionIds as $id) {
        // The copied flag is deliberately wrong: scoring must use the live key.
        $answer->attempt_answer_options()->create(['option_id' => $id, 'is_correct' => 1]);
    }

    return $answer;
}

// 1. Answer-key leak on the attempt page

test('the attempt page hides answer keys and scores from the candidate until the attempt is finished', function () {
    $ctx = practiceAttempt();
    $ctx['attemptType']->update(['is_correct_count' => 1, 'score' => 5]);

    $this->actingAs($ctx['student'])->get(route('attempt.show', $ctx['attempt']))
        ->assertOk()
        ->assertInertia(fn (AssertableInertia $page) => $page
            ->where('results_visible', false)
            ->where('bands', null)
            ->missing('attempt.attempt_types.0.attempt_parts')
            ->missing('attempt.attempt_types.0.is_correct_count')
            ->missing('attempt.attempt_types.0.score'));

    expect(json_encode($this->actingAs($ctx['student'])->get(route('attempt.show', $ctx['attempt']))->viewData('page')))
        ->not->toContain('carbon');

    // Graders always see everything.
    $this->actingAs($ctx['admin'])->get(route('attempt.show', $ctx['attempt']))
        ->assertInertia(fn (AssertableInertia $page) => $page
            ->where('results_visible', true)
            ->has('attempt.attempt_types.0.attempt_parts'));

    app(ExamService::class)->finishAttempt($ctx['attempt']);

    $this->actingAs($ctx['student'])->get(route('attempt.show', $ctx['attempt']))
        ->assertInertia(fn (AssertableInertia $page) => $page
            ->where('results_visible', true)
            ->has('attempt.attempt_types.0.attempt_parts')
            ->has('bands.listening'));
});

// 2. multiple_response

test('multiple response: selecting more options than the key has is refused on the web', function () {
    $ctx = practiceAttempt();

    $this->actingAs($ctx['student'])->postJson(route('attempt-answer.store'), [
        'attempt_id' => $ctx['attempt']->id, 'part_id' => $ctx['part']->id, 'question_id' => $ctx['question']->id,
        'options' => [$ctx['a']->id, $ctx['b']->id, $ctx['c']->id],
    ])->assertStatus(422)->assertJsonPath('reason', 'too_many_options');

    $this->actingAs($ctx['student'])->postJson(route('attempt-answer.store'), [
        'attempt_id' => $ctx['attempt']->id, 'part_id' => $ctx['part']->id, 'question_id' => $ctx['question']->id,
        'options' => [$ctx['a']->id, $ctx['c']->id],
    ])->assertOk();
});

test('multiple response scoring: over-selection scores 0, otherwise one point per correct option', function () {
    $ctx = practiceAttempt();

    answerWith($ctx, [$ctx['a']->id, $ctx['b']->id, $ctx['c']->id]);
    expect($ctx['attemptType']->recalculateIsCorrectCount())->toBe(0.0);

    AttemptAnswerOption::query()->delete();
    AttemptAnswer::query()->delete();
    answerWith($ctx, [$ctx['a']->id, $ctx['c']->id]);
    expect($ctx['attemptType']->recalculateIsCorrectCount())->toBe(1.0);

    AttemptAnswerOption::query()->delete();
    AttemptAnswer::query()->delete();
    answerWith($ctx, [$ctx['a']->id, $ctx['b']->id]);
    expect($ctx['attemptType']->recalculateIsCorrectCount())->toBe(2.0);
});

test('scores come from the live answer key and a key fix re-scores submitted modules', function () {
    $ctx = practiceAttempt();
    answerWith($ctx, [$ctx['c']->id]); // copied is_correct = 1, live key says wrong
    $ctx['attemptType']->update(['is_submitted' => true]);

    expect($ctx['attemptType']->recalculateIsCorrectCount())->toBe(0.0);

    // Fix the key: C is correct, B is not.
    $ctx['c']->update(['is_correct' => 1]);
    $ctx['b']->update(['is_correct' => 0]);
    expect((float) $ctx['attemptType']->fresh()->is_correct_count)->toBe(1.0);

    // Text keys too.
    AttemptAnswer::create(['attempt_part_id' => $ctx['attemptPart']->id, 'question_id' => $ctx['gapQuestion']->id, 'answer_text' => 'oxygen']);
    $ctx['attemptType']->recalculateIsCorrectCount();
    $ctx['gapQuestion']->update(['answer_text' => 'oxygen']);
    expect((float) $ctx['attemptType']->fresh()->is_correct_count)->toBe(2.0);
});

// 3. Scores hidden mid-exam

test('the exam room never exposes module scores while the attempt is running', function () {
    $ctx = practiceAttempt();
    $ctx['attemptType']->update(['is_correct_count' => 7, 'score' => 6, 'comment' => 'secret']);

    $json = $this->actingAs($ctx['student'])->getJson(route('practice-attempt', $ctx['attempt']))->assertOk()->json('data');
    expect($json['attempt_types'][0])->not->toHaveKeys(['is_correct_count', 'score', 'comment']);

    $submitted = $this->actingAs($ctx['student'])
        ->postJson(route('practice-test-type-submit', [$ctx['attempt'], $ctx['testType']->type_id]))->assertOk()->json('data');
    expect($submitted)->not->toHaveKeys(['is_correct_count', 'score']);

    $this->actingAs($ctx['student'])->get(route('attempt.index'))
        ->assertInertia(fn (AssertableInertia $page) => $page->missing('attempt.data.0.attempt_types.0.is_correct_count'));
});

// 4. Essays evaluated once

test('a module submitted twice queues its essays once and finishing the attempt does not queue them again', function () {
    Bus::fake([EvaluateEssayJob::class]);
    $admin = makeUser('SuperAdmin');
    $student = makeUser('Student');
    ['test' => $test, 'testType' => $testType, 'part' => $part] = makeTestContent($admin, 'Writing');
    $essay = makeSection($part, 'essay', 'Write');
    $q = Question::create(['section_id' => $essay->id, 'textarea' => 'Task']);
    $attempt = Attempt::create(['user_id' => $student->id, 'test_id' => $test->id, 'started_at' => now()]);
    $attemptPart = AttemptPart::create(['attempt_id' => $attempt->id, 'part_id' => $part->id, 'started_at' => now()]);
    AttemptAnswer::create(['attempt_part_id' => $attemptPart->id, 'question_id' => $q->id, 'answer_text' => str_repeat('word ', 80)]);
    $type = AttemptType::create(['attempt_id' => $attempt->id, 'type_id' => $testType->type_id, 'started_at' => now(), 'finished_at' => now()->addHour()]);

    $exam = app(ExamService::class);
    $stale = AttemptType::find($type->id); // a second request holding the unsubmitted row

    expect($exam->finishTypeWithEvaluation($attempt, $type))->toBeTrue()
        ->and($exam->finishTypeWithEvaluation($attempt, $stale))->toBeFalse();
    $exam->finishAttempt($attempt);

    Bus::assertDispatchedTimes(EvaluateEssayJob::class, 1);
});

test('the essay job skips scored essays unless forced and never touches an Admin-confirmed module', function () {
    $ctx = practiceAttempt('Writing');
    $essay = makeSection($ctx['part'], 'essay', 'Write');
    $q = Question::create(['section_id' => $essay->id, 'textarea' => 'Task']);
    $answer = AttemptAnswer::create(['attempt_part_id' => $ctx['attemptPart']->id, 'question_id' => $q->id, 'answer_text' => str_repeat('word ', 80), 'score' => 6]);

    $ai = Mockery::mock(OpenAIService::class);
    app()->instance(OpenAIService::class, $ai);

    $ai->shouldNotReceive('evaluateEssay');
    (new EvaluateEssayJob($answer->id))->handle();
    expect((float) $answer->fresh()->score)->toBe(6.0);

    $ctx['attemptType']->update(['reviewed_at' => now()]);
    (new EvaluateEssayJob($answer->id, true))->handle();
    expect((float) $answer->fresh()->score)->toBe(6.0);

    $ctx['attemptType']->update(['reviewed_at' => null]);
    $ai = Mockery::mock(OpenAIService::class);
    app()->instance(OpenAIService::class, $ai);
    $ai->shouldReceive('evaluateEssay')->once()->andReturn(json_encode(['overall' => 7.3, 'scores' => [], 'feedback' => 'ok']));
    (new EvaluateEssayJob($answer->id, true))->handle();
    expect((float) $answer->fresh()->score)->toBe(7.5);

    // Unusable output keeps the old band (and fails the attempt so the queue retries).
    $ai = Mockery::mock(OpenAIService::class);
    app()->instance(OpenAIService::class, $ai);
    $ai->shouldReceive('evaluateEssay')->once()->andReturn('not json');
    expect(fn () => (new EvaluateEssayJob($answer->id, true))->handle())->toThrow(RuntimeException::class);
    expect((float) $answer->fresh()->score)->toBe(7.5);
});

test('AI bands are clamped to 0-9 and rounded to half bands', function () {
    expect(EvaluateEssayJob::normalizeBand(12))->toBe(9.0)
        ->and(EvaluateEssayJob::normalizeBand(-1))->toBe(0.0)
        ->and(EvaluateEssayJob::normalizeBand('6.74'))->toBe(6.5)
        ->and(EvaluateEssayJob::normalizeBand(6.75))->toBe(7.0)
        ->and(EvaluateEssayJob::normalizeBand('band 7'))->toBeNull()
        ->and(EvaluateEssayJob::normalizeBand(null))->toBeNull();
});

// 5 + 7. Text matching

test('decimal keys are never rounded into a thousands variant', function () {
    expect(AnswerMatcher::matches('4', '3.5'))->toBeFalse()
        ->and(AnswerMatcher::matches('3.5', '3.5'))->toBeTrue()
        ->and(AnswerMatcher::matches('1500', '1,500'))->toBeTrue()
        ->and(AnswerMatcher::matches('1,500', '1500'))->toBeTrue()
        ->and(AnswerMatcher::matches('14,000', '14000'))->toBeTrue();
});

test('text answers ignore case, repeated whitespace and trailing punctuation', function () {
    expect(AnswerMatcher::matches('  Carbon   Dioxide. ', 'carbon dioxide'))->toBeTrue()
        ->and(AnswerMatcher::matches('CARBON!', 'carbon'))->toBeTrue()
        ->and(AnswerMatcher::matches('Ünïcode', 'üNÏCODE'))->toBeTrue()
        ->and(AnswerMatcher::matches('carbons', 'carbon'))->toBeFalse()
        ->and(AnswerMatcher::matches('', 'carbon'))->toBeFalse();
});

test('slashes between digits are part of the answer; between words they separate alternatives', function () {
    expect(AnswerMatcher::matches('24/7', '24/7'))->toBeTrue()
        ->and(AnswerMatcher::matches('24', '24/7'))->toBeFalse()
        ->and(AnswerMatcher::matches('1/2', '1/2'))->toBeTrue()
        ->and(AnswerMatcher::matches('2', '1 / 2'))->toBeFalse()
        ->and(AnswerMatcher::matches('color', 'colour / color'))->toBeTrue()
        ->and(AnswerMatcher::matches('colour', 'colour/color'))->toBeTrue()
        ->and(AnswerMatcher::matches('grey', 'gray; grey'))->toBeTrue()
        ->and(AnswerMatcher::matches('gray', 'grey | gray'))->toBeTrue();
});

// 6. Writing band

test('the writing band is (T1 + 2*T2) / 3 on the attempt page and the PDF, and a confirmed band wins', function () {
    $admin = makeUser('SuperAdmin');
    $student = makeUser('Student');
    ['test' => $test, 'testType' => $testType, 'part' => $part] = makeTestContent($admin, 'Writing');
    $part2 = Part::create(['test_type_id' => $testType->id, 'name' => 'Task 2', 'minute' => 40]);
    $t1 = Question::create(['section_id' => makeSection($part, 'essay')->id, 'textarea' => 'T1', 'order' => 1]);
    $t2 = Question::create(['section_id' => makeSection($part2, 'essay')->id, 'textarea' => 'T2', 'order' => 1]);
    $attempt = Attempt::create(['user_id' => $student->id, 'test_id' => $test->id, 'started_at' => now(), 'finished_at' => now()]);
    $ap1 = AttemptPart::create(['attempt_id' => $attempt->id, 'part_id' => $part->id, 'started_at' => now()]);
    $ap2 = AttemptPart::create(['attempt_id' => $attempt->id, 'part_id' => $part2->id, 'started_at' => now()]);
    AttemptAnswer::create(['attempt_part_id' => $ap1->id, 'question_id' => $t1->id, 'answer_text' => 'x', 'score' => 5]);
    AttemptAnswer::create(['attempt_part_id' => $ap2->id, 'question_id' => $t2->id, 'answer_text' => 'y', 'score' => 7]);
    $type = AttemptType::create(['attempt_id' => $attempt->id, 'type_id' => $testType->type_id, 'is_submitted' => true, 'started_at' => now(), 'finished_at' => now()]);
    $type->recalculateIsCorrectCount(); // 12 → the old "/2" rule gave 6.0

    // (5 + 2*7) / 3 = 6.33 → 6.5
    $this->actingAs($student)->get(route('attempt.show', $attempt))
        ->assertInertia(fn (AssertableInertia $page) => $page->where('writing_band', 6.5)->where('bands.writing', 6.5)->where('bands.overall', 6.5));

    $html = view('pdf.attempt', ['attempt' => $attempt->load('attempt_types.type')])->render();
    expect($html)->toContain('6.5');

    $type->update(['score' => 8, 'reviewed_at' => now()]);
    expect(app(MockResultService::class)->attemptBands($attempt->fresh())['writing'])->toBe(8.0);
});

// 13. General Training Reading

test('General Training reading uses the GT band table and the test variant', function () {
    expect(IeltsScoreConverter::convertReadingGeneral(40))->toBe(9.0)
        ->and(IeltsScoreConverter::convertReadingGeneral(34))->toBe(7.0)
        ->and(IeltsScoreConverter::convertReadingGeneral(30))->toBe(6.0)
        ->and(IeltsScoreConverter::convertReadingGeneral(23))->toBe(5.0)
        ->and(IeltsScoreConverter::convertReadingGeneral(15))->toBe(4.0)
        ->and(IeltsScoreConverter::convertReadingGeneral(0))->toBe(0.0)
        ->and(IeltsScoreConverter::convertReading(30))->toBe(7.0);

    $ctx = practiceAttempt('Reading');
    $ctx['attemptType']->update(['is_correct_count' => 30, 'is_submitted' => true]);

    expect(app(MockResultService::class)->attemptBands($ctx['attempt']->fresh())['reading'])->toBe(7.0);

    $ctx['test']->update(['variant' => 'general']);
    $bands = app(MockResultService::class)->attemptBands($ctx['attempt']->fresh());
    expect($bands['reading'])->toBe(6.0)->and($bands['reading_variant'])->toBe('general');
});

test('admins set the test variant; anything but academic/general is refused', function () {
    $ctx = practiceAttempt('Reading');

    $this->actingAs($ctx['admin'])->post(route('test.update', $ctx['test']), ['name' => 'T', 'variant' => 'general'])
        ->assertSessionHasNoErrors();
    expect($ctx['test']->fresh()->variant)->toBe('general');

    $this->actingAs($ctx['admin'])->post(route('test.update', $ctx['test']), ['name' => 'T', 'variant' => 'gt'])
        ->assertSessionHasErrors('variant');

    // Omitting the variant keeps it.
    $this->actingAs($ctx['admin'])->post(route('test.update', $ctx['test']), ['name' => 'T2'])->assertSessionHasNoErrors();
    expect($ctx['test']->fresh()->variant)->toBe('general');
});

// 10. Web submit

test('the web submit is refused while paused and finishes through the exam service', function () {
    Queue::fake();
    $ctx = practiceAttempt();
    $ctx['attempt']->update(['paused_at' => now()]);

    $this->actingAs($ctx['student'])->post(route('practice-attempt-submit', $ctx['attempt']))->assertSessionHas('error');
    $this->actingAs($ctx['student'])->postJson(route('practice-test-type-submit', [$ctx['attempt'], $ctx['testType']->type_id]))->assertStatus(409);
    expect($ctx['attempt']->fresh()->finished_at)->toBeNull();

    $ctx['attempt']->update(['paused_at' => null]);
    $this->actingAs($ctx['student'])->post(route('practice-attempt-submit', $ctx['attempt']))->assertRedirect();
    expect($ctx['attempt']->fresh()->finished_at)->not->toBeNull()
        ->and((bool) $ctx['attemptType']->fresh()->is_submitted)->toBeTrue();
});

// 9. CloseOldAttempts

test('attempts:close-old leaves running, paused and online attempts alone', function () {
    Queue::fake();
    $make = function (array $attrs = [], ?array $type = null) {
        $ctx = practiceAttempt();
        Attempt::whereKey($ctx['attempt']->id)->update(array_merge(['created_at' => now()->subHours(4)], $attrs));
        AttemptType::whereKey($ctx['attemptType']->id)->update($type ?? ['finished_at' => now()->subHour()]);

        return $ctx['attempt'];
    };

    $abandoned = $make();
    $paused = $make(['paused_at' => now()->subHour()]);
    $online = $make(['last_heartbeat_at' => now()->subMinutes(2)]);
    $running = $make([], ['finished_at' => now()->addMinutes(20)]);

    $this->artisan('attempts:close-old')->assertSuccessful();

    expect($abandoned->fresh()->finished_at)->not->toBeNull()
        ->and($paused->fresh()->finished_at)->toBeNull()
        ->and($online->fresh()->finished_at)->toBeNull()
        ->and($running->fresh()->finished_at)->toBeNull();
});

// 16. Result jobs

test('result mails render with a plain-text part and jobs without an address do nothing', function () {
    $ctx = practiceAttempt();
    $mail = new SendResultMail($ctx['student'], $ctx['attempt']);
    $mail->assertSeeInText('View the full results');

    $ctx['student']->forceFill(['email' => ''])->save();
    (new SendResultEmailJob($ctx['student'], $ctx['attempt']))->handle();
    (new SendResultTelegramJob($ctx['student'], $ctx['attempt']))->handle();

    expect((new SendResultEmailJob($ctx['student'], $ctx['attempt']))->tries)->toBe(3);
});
