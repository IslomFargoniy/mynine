<?php

use Illuminate\Support\Facades\Route;

beforeEach(function () {
    // A tiny probe route inside the web group: reports the locale SetLocale chose and a translated message.
    Route::middleware('web')->get('/__locale-probe', fn () => response()->json([
        'locale' => app()->getLocale(),
        'message' => __('status_updated'),
    ]));
});

test('server text defaults to Uzbek', function () {
    $this->getJson('/__locale-probe')->assertJson(['locale' => 'uz', 'message' => 'Holat yangilandi.']);
});

test('the language switcher endpoint stores the choice in the session', function () {
    $this->getJson('/lang/ru')->assertNoContent();
    $this->getJson('/__locale-probe')->assertJson(['locale' => 'ru', 'message' => 'Статус обновлён.']);

    $this->from('/dashboard')->get('/lang/en')->assertRedirect('/dashboard');
    $this->getJson('/__locale-probe')->assertJson(['locale' => 'en', 'message' => 'Status updated.']);

    $this->get('/lang/de')->assertStatus(400);
});

test('the X-Locale header sent by the SPA wins and is remembered', function () {
    $this->withSession(['locale' => 'ru'])
        ->getJson('/__locale-probe', ['X-Locale' => 'en'])
        ->assertJson(['locale' => 'en']);

    expect(session('locale'))->toBe('en');

    // Unknown values are ignored.
    $this->getJson('/__locale-probe', ['X-Locale' => 'xx'])->assertJson(['locale' => 'en']);
});

test('flash messages follow the chosen language', function () {
    $admin = makeUser('Admin');
    $exam = makeDesktopExam($admin, ['require_desktop' => false]);

    $this->actingAs($admin)->withSession(['locale' => 'ru'])
        ->from(route('reception.index'))
        ->post(route('reception.deliver', $exam['student']))
        ->assertSessionHas('error', 'Результат ещё не готов.');

    $this->actingAs($admin)
        ->from(route('reception.index'))
        ->post(route('reception.deliver', $exam['student']), [], ['X-Locale' => 'uz'])
        ->assertSessionHas('error', 'Natija hali tayyor emas.');
});
