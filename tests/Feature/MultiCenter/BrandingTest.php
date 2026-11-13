<?php

use App\Models\Attempt;
use App\Models\User\User;
use App\Services\MockResultService;
use App\Support\CenterBranding;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\View;
use Inertia\Testing\AssertableInertia as Assert;

/**
 * Data of the next render of $view (PDF views are rendered into a PDF, so the tests render the HTML themselves).
 *
 * @return object{data: ?array<string, mixed>}
 */
function captureView(string $view): object
{
    $box = (object) ['data' => null];
    View::composer($view, function ($v) use ($box) {
        $box->data ??= $v->getData();
    });

    return $box;
}

beforeEach(function () {
    Storage::fake('public');
    $this->mynine = defaultCenter();
    $this->partner = makeCenter('ALPHA', ['name' => 'Alpha Academy']);
    $this->partnerExam = makeDesktopExam($this->partner, [], '111111');
    $this->mynineExam = makeDesktopExam($this->mynine, [], '222222');
});

function giveLogo(User $center): string
{
    $path = UploadedFile::fake()->image('logo.png', 40, 20)->store('centers/logos', 'public');
    centerSettings($center)->forceFill(['logo_path' => $path])->save();

    return $path;
}

test('a partner center\'s 80 mm tickets show its logo and name and a small Powered by Mynine', function () {
    $path = giveLogo($this->partner);

    $this->actingAs($this->partner)->get(route('mock.code-tickets', $this->partnerExam['mock']))->assertOk()
        ->assertSee('Alpha Academy')
        ->assertSee(Storage::disk('public')->url($path), false)
        ->assertSee('class="center-logo"', false)
        ->assertSee('Powered by Mynine')
        ->assertSee('111111')
        ->assertSee('size: 80mm 70mm', false);
});

test('without a logo the partner ticket prints the name only', function () {
    $this->actingAs($this->partner)->get(route('mock.code-tickets', $this->partnerExam['mock']))->assertOk()
        ->assertSee('Alpha Academy')
        ->assertDontSee('class="center-logo"', false)
        ->assertSee('Powered by Mynine');
});

test('the Mynine center\'s tickets keep the Mynine receipt header', function () {
    $this->actingAs($this->mynine)->get(route('mock.code-tickets', $this->mynineExam['mock']))->assertOk()
        ->assertSee('222222')
        ->assertSee('Mynine · IELTS')
        ->assertDontSee('Powered by Mynine');
});

test('A4 code cards carry the partner\'s embedded logo and name; Mynine cards keep the Mynine brand', function () {
    giveLogo($this->partner);
    $box = captureView('pdf.code-cards');
    $this->actingAs($this->partner)->get(route('mock.code-cards', $this->partnerExam['mock']))->assertOk()->assertHeader('Content-Type', 'application/pdf');

    $html = view('pdf.code-cards', $box->data)->render();
    expect($html)->toContain('Alpha Academy')
        ->toContain('src="data:image/png;base64,')
        ->toContain('Powered by Mynine')
        ->not->toContain('Mynine Mock Exam')
        ->not->toContain('Mynine exam computer');

    $box = captureView('pdf.code-cards');
    $this->actingAs($this->mynine)->get(route('mock.code-cards', $this->mynineExam['mock']))->assertOk();
    $html = view('pdf.code-cards', $box->data)->render();
    expect($html)->toContain('Mynine Mock Exam')->not->toContain('Powered by Mynine');
});

test('reception result sheets are branded per candidate\'s center', function () {
    $this->mock(MockResultService::class, fn ($mock) => $mock->shouldReceive('result')->andReturn([
        'ready' => true, 'listening' => 7.0, 'reading' => 6.5, 'writing' => 6.0, 'speaking' => 6.0, 'overall' => 6.5, 'missing' => [],
    ]));

    $reception = makeUser('Reception', $this->partner);
    $box = captureView('pdf.result-sheet');
    $this->actingAs($reception)->get(route('reception.result-sheets', ['ids' => $this->partnerExam['student']->id]))
        ->assertOk()->assertHeader('Content-Type', 'application/pdf');

    $html = view('pdf.result-sheet', $box->data)->render();
    expect($html)->toContain('Alpha Academy')->toContain('Powered by Mynine')->toContain('Test Report Form')->toContain('B2')->not->toContain('&middot; mynine.uz');

    $box = captureView('pdf.result-sheet');
    $this->actingAs(makeUser('Reception', $this->mynine))->get(route('reception.result-sheets', ['ids' => $this->mynineExam['student']->id]))->assertOk();
    $html = view('pdf.result-sheet', $box->data)->render();
    expect($html)->toContain('<span class="center-name">Mynine</span>')->toContain('&middot; mynine.uz')->not->toContain('Powered by Mynine');
});

test('the attempt result PDF of a partner mock shows the center; practice and Mynine mocks keep MYNINE.UZ', function () {
    $partnerAttempt = Attempt::create(['name' => 'Cand', 'mock_id' => $this->partnerExam['mock']->id, 'mock_student_id' => $this->partnerExam['student']->id, 'test_id' => $this->partnerExam['testL']->id, 'started_at' => now()]);
    $mynineAttempt = Attempt::create(['name' => 'Cand', 'mock_id' => $this->mynineExam['mock']->id, 'mock_student_id' => $this->mynineExam['student']->id, 'test_id' => $this->mynineExam['testL']->id, 'started_at' => now()]);

    $render = fn (Attempt $attempt) => view('pdf.attempt', [
        'attempt' => $attempt->load(['test.folder', 'user', 'mock', 'mockStudent', 'attempt_types.type']),
        'branding' => CenterBranding::forCenter($attempt->centerId()),
    ])->render();

    expect($render($partnerAttempt))->toContain('Alpha Academy')->toContain('ALPHA ACADEMY ASSESSMENT')->toContain('Powered by Mynine')->not->toContain('MYNINE.UZ</div>')
        ->and($render($mynineAttempt))->toContain('MYNINE.UZ</div>')->toContain('MYNINE CERTIFIED ASSESSMENT')->not->toContain('Powered by Mynine')
        ->and(CenterBranding::forCenter(null))->toBeNull();
});

test('center staff get their center in the shared props; the SuperAdmin keeps Mynine', function () {
    $this->actingAs(makeUser('Reception', $this->partner))->get(route('reception.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('auth.center.name', 'Alpha Academy')->where('auth.center.is_mynine', false)->where('auth.access.superAdmin', false));

    $this->actingAs(makeSuperAdmin())->get(route('reception.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('auth.center.is_mynine', true)->where('auth.access.superAdmin', true));
});
