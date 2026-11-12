<?php

use App\Models\Option;
use App\Models\Part;
use App\Models\Question;
use App\Models\Section;
use App\Models\Test as ExamTest;
use App\Models\TestType;
use App\Services\Import\MockTestImporter;
use App\Support\Html\ContentSanitizer;

const XSS = '<script>alert(1)</script><img src="x" onerror="alert(2)"><a href="javascript:alert(3)">link</a><p onclick="alert(4)" style="position:fixed;top:0;text-align:center">safe</p>';

function expectClean(?string $html): void
{
    expect($html)->not->toContain('<script')
        ->and($html)->not->toContain('onerror')
        ->and($html)->not->toContain('onclick')
        ->and($html)->not->toContain('javascript:')
        ->and($html)->not->toContain('position')
        ->and($html)->toContain('safe');
}

beforeEach(function () {
    makeSuperAdmin();
    $this->admin = makeCenter();
    $this->actingAs($this->admin);
    // A tenant center's Mock Bank test (tenant Admins edit only those).
    $this->content = makeTestContent($this->admin, 'Reading', ['folder_id' => null, 'purpose' => 'mock', 'open' => 0]);
});

test('part text is sanitized when a center saves it', function () {
    $this->post(route('part.store'), ['test_type_id' => $this->content['testType']->id, 'name' => 'P2', 'textarea' => XSS])
        ->assertSessionHasNoErrors()->assertRedirect();
    expectClean(Part::where('name', 'P2')->value('textarea'));

    $part = $this->content['part'];
    $this->post(route('part.update', $part), ['name' => 'Part 1', 'textarea' => '<table><tr><td colspan="2" onmouseover="x()">{1}</td></tr></table>'.XSS])
        ->assertSessionHasNoErrors()->assertRedirect();
    $html = $part->fresh()->textarea;
    expectClean($html);
    expect($html)->toContain('<td colspan="2">{1}</td>');
});

test('section text is sanitized and gap blanks still become questions', function () {
    $type = makeQuestionType('complete_section');

    $this->post(route('section.store'), [
        'part_id' => $this->content['part']->id,
        'question_type_id' => $type->id,
        'textarea' => '<p>The {cave} was <strong>{dark}</strong> and {don\'t}.</p>'.XSS,
    ])->assertSessionHasNoErrors()->assertRedirect();

    $section = Section::latest('id')->first();
    expectClean($section->textarea);
    expect($section->textarea)->toContain('{cave}')->toContain('<strong>{dark}</strong>')
        ->and($section->questions()->orderBy('order')->pluck('answer_text')->all())->toBe(['cave', 'dark', "don't"]);

    $this->put(route('section.update', $section), [
        'question_type_id' => $type->id,
        'textarea' => '<ul><li>{cave}</li></ul><img src="/storage/a.png" onerror="x()">'.XSS,
    ])->assertSessionHasNoErrors()->assertRedirect();

    $section->refresh();
    expectClean($section->textarea);
    expect($section->textarea)->toContain('<li>{cave}</li>')->toContain('src="/storage/a.png"')
        ->and($section->questions()->pluck('answer_text')->all())->toBe(['cave']);
});

test('question and option html is sanitized, plain text is left alone', function () {
    $section = makeSection($this->content['part'], 'multiple_choice', '<p>Choose</p>');

    $this->post(route('question.store'), [
        'section_id' => $section->id,
        'textarea' => 'Q '.XSS,
        'answer_text' => null,
        'options' => [['textarea' => 'A & B', 'is_correct' => true], ['textarea' => '<b onmouseover="x()">C</b>', 'is_correct' => false]],
    ])->assertSessionHasNoErrors()->assertRedirect();

    $question = Question::latest('id')->first();
    expectClean($question->textarea);
    expect($question->options->pluck('textarea')->all())->toBe(['A & B', '<b>C</b>']);

    $this->put(route('question.update', $question), ['textarea' => '<img src=x onerror=alert(1)>safe', 'options' => []]);
    expect($question->fresh()->textarea)->not->toContain('onerror');
});

test('the importer cannot store scripts either', function () {
    $test = ExamTest::create(['folder_id' => null, 'name' => 'Bank', 'purpose' => 'mock', 'open' => 0]);
    $module = TestType::create(['test_id' => $test->id, 'type_id' => makeType('Reading')->id]);
    makeQuestionType('complete_section');

    app(MockTestImporter::class)->import($module, [[
        'name' => 'Passage 1',
        'textarea' => XSS,
        'sections' => [[
            'question_type' => 'complete_section', 'textarea' => '<table><tr><td>{tea}</td></tr></table>'.XSS,
            'from_option' => null, 'to_option' => null, 'options' => ['<img src=x onerror=y>'],
            'questions' => [['order' => 1, 'textarea' => null, 'answer_text' => 'tea', 'options' => []]],
        ]],
    ]], false);

    $part = Part::where('test_type_id', $module->id)->firstOrFail();
    expectClean($part->textarea);
    expectClean($part->sections->first()->textarea);
    expect($part->sections->first()->textarea)->toContain('<td>{tea}</td>')
        ->and(Option::where('section_id', $part->sections->first()->id)->value('textarea'))->not->toContain('onerror');
});

test('content:sanitize cleans rows saved before sanitization existed', function () {
    $part = $this->content['part'];
    Part::whereKey($part->id)->update(['textarea' => XSS]);

    $this->artisan('content:sanitize', ['--dry-run' => true])->expectsOutputToContain('1 row(s) would change')->assertOk();
    expect($part->fresh()->textarea)->toBe(XSS);

    $this->artisan('content:sanitize')->assertOk();
    expectClean($part->fresh()->textarea);
});

test('the sanitizer keeps raster data images and drops svg data urls', function () {
    $html = app(ContentSanitizer::class)->sanitize('<img src="data:image/png;base64,iVBORw0KGgo="><img src="data:image/svg+xml;base64,PHN2Zz4=">');

    expect($html)->toContain('data:image/png')->not->toContain('svg');
});
