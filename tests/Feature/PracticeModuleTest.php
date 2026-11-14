<?php

use App\Models\Attempt;
use App\Models\Part;
use App\Models\Question;
use App\Models\TestType;
use App\Services\MockResultService;

/**
 * Listening / Reading / Writing practised on their own: the attempt opens only its module, the module is the
 * whole attempt, and the result has that module's band only (no overall).
 */
beforeEach(function () {
    $this->owner = makeUser('SuperAdmin');
    $this->student = makeUser('Student');
    ['test' => $this->test, 'testType' => $this->reading, 'part' => $this->readingPart] = makeTestContent($this->owner, 'Reading');
    $this->listening = TestType::create(['test_id' => $this->test->id, 'type_id' => makeType('Listening', 30)->id]);
    $this->listeningPart = Part::create(['test_type_id' => $this->listening->id, 'name' => 'Part 1', 'minute' => 30]);
    $section = makeSection($this->readingPart, 'fill_blank', '<p>Write one word</p>');
    $this->question = Question::create(['section_id' => $section->id, 'order' => 1, 'textarea' => 'Gas: ___', 'answer_text' => 'carbon']);
});

function startModule(object $test, string $module): Attempt
{
    test()->actingAs(test()->student)->post(route('attempt.store'), ['test_id' => test()->test->id, 'module' => $module])
        ->assertSessionHasNoErrors()->assertRedirect();

    return Attempt::where('user_id', test()->student->id)->latest('id')->firstOrFail();
}

test('a module attempt opens only its module', function () {
    $attempt = startModule($this, 'reading');
    expect($attempt->module)->toBe('reading')->and($attempt->isModulePractice())->toBeTrue();

    $this->getJson(route('practice-test-type', ['test_type' => $this->reading->id, 'attempt_id' => $attempt->id]))->assertOk();
    $this->getJson(route('practice-test-type', ['test_type' => $this->listening->id, 'attempt_id' => $attempt->id]))->assertForbidden();
    $this->getJson(route('practice-part', ['part' => $this->listeningPart->id, 'attempt_id' => $attempt->id]))->assertForbidden();

    $modules = $this->getJson(route('practice-attempt', $attempt->id))->assertOk()->json('data.test.types');
    expect(collect($modules)->pluck('id')->all())->toBe([$this->reading->id]);
});

test('a module the test does not have, or a module with a mock, is refused', function () {
    $this->actingAs($this->student)->post(route('attempt.store'), ['test_id' => $this->test->id, 'module' => 'writing'])
        ->assertSessionHasErrors('error');
    $this->actingAs($this->student)->post(route('attempt.store'), ['test_id' => $this->test->id, 'module' => 'speaking'])
        ->assertSessionHasErrors('module');
    expect(Attempt::where('user_id', $this->student->id)->count())->toBe(0);
});

test('submitting the module finishes the attempt and goes to its result, which has no overall band', function () {
    $attempt = startModule($this, 'reading');
    $this->getJson(route('practice-part', ['part' => $this->readingPart->id, 'attempt_id' => $attempt->id]))->assertOk();
    $this->postJson(route('attempt-answer.store', ['part_id' => $this->readingPart->id, 'attempt_id' => $attempt->id]), [
        'question_id' => $this->question->id, 'answer_text' => 'carbon',
    ])->assertOk();

    $this->postJson(route('practice-test-type-submit', ['attempt' => $attempt->id, 'type_id' => $this->reading->type_id]))->assertOk();
    expect($attempt->fresh()->finished_at)->not->toBeNull();

    $this->post(route('practice-attempt-submit', $attempt->id))->assertRedirect(route('attempt.show', $attempt->id));

    $bands = app(MockResultService::class)->attemptBands($attempt->fresh());
    expect($bands['reading'])->not->toBeNull()->and($bands['overall'])->toBeNull();
});

test('the module page lists tests with that module and the student\'s own bands; staff are sent away', function () {
    $attempt = startModule($this, 'reading');
    $this->getJson(route('practice-part', ['part' => $this->readingPart->id, 'attempt_id' => $attempt->id]))->assertOk();
    $this->postJson(route('practice-test-type-submit', ['attempt' => $attempt->id, 'type_id' => $this->reading->type_id]))->assertOk();

    $this->actingAs($this->student)->get(route('practice-module.index', 'reading'))->assertOk()
        ->assertInertia(fn ($page) => $page->component('practice-module/index')
            ->where('module', 'reading')
            ->where('folders.0.tests.0.id', $this->test->id)
            ->where('stats.count', 1)
            ->where('byTest.'.$this->test->id.'.count', 1));

    // No Writing module in the test: nothing listed.
    $this->get(route('practice-module.index', 'writing'))->assertOk()->assertInertia(fn ($page) => $page->has('folders', 0));
    $this->get('/practice-module/speaking')->assertNotFound();

    $this->actingAs(makeCenter('NOVA'))->get(route('practice-module.index', 'reading'))->assertRedirect(route('dashboard'));
});

test('results can be filtered by module', function () {
    $module = startModule($this, 'reading');
    $full = Attempt::create(['user_id' => $this->student->id, 'test_id' => $this->test->id, 'started_at' => now()]);

    $ids = fn (array $query) => collect($this->actingAs($this->student)->get(route('attempt.index', $query))->assertOk()
        ->viewData('page')['props']['attempt']['data'])->pluck('id')->all();

    expect($ids(['module' => 'reading']))->toBe([$module->id])
        ->and($ids(['module' => 'full']))->toBe([$full->id])
        ->and($ids([]))->toContain($module->id, $full->id);
});
