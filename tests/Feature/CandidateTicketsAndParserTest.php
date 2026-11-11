<?php

use App\Models\MockStudent;
use App\Services\CandidateService;

beforeEach(function () {
    $this->admin = makeUser('Admin');
    $this->exam = makeDesktopExam($this->admin, ['require_desktop' => false]);
    $this->mock = $this->exam['mock'];
});

/*
| Bulk candidate parser
*/

test('bulk lines accept ; , : tab and " - " separators and normalise phones', function (string $line, string $name, ?string $phone) {
    $parsed = CandidateService::parseLine($line);

    expect($parsed['name'])->toBe($name)
        ->and(CandidateService::normalizePhone($parsed['phone']))->toBe($phone);
})->with([
    'colon' => ['ali : 911157709', 'ali', '+998911157709'],
    'colon no spaces' => ['Ali Valiyev:911157709', 'Ali Valiyev', '+998911157709'],
    'semicolon' => ['Anvar Karimov; 90 123 45 67', 'Anvar Karimov', '+998901234567'],
    'comma' => ['Malika Aliyeva, +998 93 765 43 21', 'Malika Aliyeva', '+998937654321'],
    'tab' => ["Bobur\t998901112233", 'Bobur', '+998901112233'],
    'spaced dash' => ['Said-Akbar Nur - 90-111-22-33', 'Said-Akbar Nur', '+998901112233'],
    'only space' => ['Lola 901234567', 'Lola', '+998901234567'],
    'phone first' => ['+998 90 123 45 67 - Kamola', 'Kamola', '+998901234567'],
    'trailing punctuation' => ['  Jasur ,: 90 123 45 67 ;', 'Jasur', '+998901234567'],
    'no phone' => ['Dilnoza :', 'Dilnoza', null],
]);

test('a row whose phone sits in the name field is split before saving', function () {
    $this->actingAs($this->admin)->post(route('mock-student.store'), [
        'mock_id' => $this->mock->id,
        'candidates' => [['name' => 'ali : 911157709', 'phone' => '']],
    ])->assertSessionHasNoErrors()->assertSessionHas('success');

    $student = MockStudent::where('mock_id', $this->mock->id)->where('phone', '+998911157709')->firstOrFail();
    expect($student->name)->toBe('ali');
});

test('raw text lines are parsed on the server', function () {
    $this->actingAs($this->admin)->post(route('mock-student.store'), [
        'mock_id' => $this->mock->id,
        'text' => "Anvar ; 90 123 45 67\nMalika, +998937654321\n\nBobur\t911112233",
    ])->assertSessionHasNoErrors();

    expect(MockStudent::where('mock_id', $this->mock->id)->whereIn('name', ['Anvar', 'Bobur', 'Malika'])->orderBy('name')->pluck('phone')->all())
        ->toBe(['+998901234567', '+998911112233', '+998937654321']);
});

test('a line without a valid phone is rejected with a per-line error and nothing is saved', function () {
    $before = MockStudent::count();

    $this->actingAs($this->admin)->post(route('mock-student.store'), [
        'mock_id' => $this->mock->id,
        'text' => "Anvar ; 90 123 45 67\nDilnoza :\nKamol ; 12345",
    ])->assertSessionHasErrors(['candidates.1.phone', 'candidates.2.phone']);

    expect(MockStudent::count())->toBe($before);
    expect(session('errors')->get('candidates.1.phone')[0])->toContain('2')->toContain('Dilnoza');
});

/*
| 80 mm code tickets
*/

test('code tickets show only the requested candidates of that mock', function () {
    $other = makeDesktopExam($this->admin, ['require_desktop' => false], 'MOCK-200002');
    $mine = MockStudent::create(['mock_id' => $this->mock->id, 'name' => 'Mine', 'code' => 'AVGUST17-697100', 'phone' => '+998901234567']);
    $notSelected = MockStudent::create(['mock_id' => $this->mock->id, 'name' => 'Other', 'code' => 'AVGUST17-111111', 'phone' => '+998901234568']);
    $foreign = $other['student'];

    $response = $this->actingAs($this->admin)
        ->get(route('mock.code-tickets', ['mock' => $this->mock->id, 'ids' => implode(',', [$mine->id, $foreign->id])]))
        ->assertOk()
        ->assertSee('AVGUST17-697100')
        ->assertDontSee('AVGUST17-111111')
        ->assertDontSee($foreign->code)
        ->assertSee('size: 80mm auto', false)
        ->assertSee('page-break-after: always', false)
        ->assertSee('window.print()', false);

    // Names are not printed: only the code.
    $response->assertDontSee('>Mine<', false);
});

test('code tickets without ids list every candidate of the mock; unknown ids give 404', function () {
    $this->actingAs($this->admin)->get(route('mock.code-tickets', $this->mock))->assertOk()->assertSee($this->exam['student']->code);

    $other = makeDesktopExam($this->admin, ['require_desktop' => false], 'MOCK-300003');
    $this->actingAs($this->admin)->get(route('mock.code-tickets', ['mock' => $this->mock->id, 'ids' => $other['student']->id]))->assertNotFound();
});

test('code tickets are for Admin and Reception only', function () {
    $this->get(route('mock.code-tickets', $this->mock))->assertRedirect(route('login'));
    $this->actingAs(makeUser('Student'))->get(route('mock.code-tickets', $this->mock))->assertForbidden();
    $this->actingAs(makeUser('Reception'))->get(route('mock.code-tickets', $this->mock))->assertOk();
});
