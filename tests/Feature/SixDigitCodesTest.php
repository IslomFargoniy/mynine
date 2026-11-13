<?php

use App\Models\MockStudent;
use App\Models\Setting;
use Illuminate\Support\Facades\DB;

beforeEach(function () {
    $this->admin = makeUser('Admin');
    $this->exam = makeDesktopExam($this->admin, ['require_desktop' => false]);
    $this->mock = $this->exam['mock'];
});

test('new candidates get unique six-digit codes', function () {
    $this->actingAs($this->admin)->post(route('mock-student.store'), [
        'mock_id' => $this->mock->id,
        'text' => "Anvar ; 90 123 45 67\nMalika, +998937654321\nBobur\t911112233",
    ])->assertSessionHasNoErrors();

    $codes = MockStudent::where('mock_id', $this->mock->id)->whereIn('name', ['Anvar', 'Malika', 'Bobur'])->pluck('code');
    expect($codes)->toHaveCount(3)
        ->and($codes->unique())->toHaveCount(3)
        ->and($codes->every(fn ($c) => preg_match('/^\d{6}$/', $c) === 1))->toBeTrue();
});

test('bulk codes never repeat each other or existing codes', function () {
    $codes = MockStudent::generateBulkCodes(500);
    expect($codes)->toHaveCount(500)->and(array_unique($codes))->toHaveCount(500)
        ->and(collect($codes)->every(fn ($c) => preg_match(MockStudent::CODE_PATTERN, $c) === 1))->toBeTrue()
        ->and(MockStudent::whereIn('code', $codes)->exists())->toBeFalse();
});

test('the migration keeps the printed digits for candidates who have not started, and leaves started ones alone', function () {
    $waiting = MockStudent::create(['mock_id' => $this->mock->id, 'name' => 'w', 'code' => 'AVGUST17-697100', 'phone' => '+998901111111']);
    $clash = MockStudent::create(['mock_id' => $this->mock->id, 'name' => 'c', 'code' => 'OTHER-697100', 'phone' => '+998901111112']);
    $started = $this->exam['student']; // has an attempt after login
    desktopLogin(registerDesktopDevice(), $started->code);
    $startedCode = $started->fresh()->code;

    (require database_path('migrations/2026_11_11_000004_six_digit_candidate_codes.php'))->up();

    expect($waiting->fresh()->code)->toBe('697100')
        ->and($clash->fresh()->code)->toMatch('/^\d{6}$/')->not->toBe('697100')
        ->and($started->fresh()->code)->toBe($startedCode)
        ->and(DB::table('mock_students')->count())->toBe(DB::table('mock_students')->distinct()->count('code'));
});

test('codes are issued in order from 000001, skipping codes still held', function () {
    Setting::query()->whereKey(MockStudent::CODE_SEQUENCE_KEY)->delete();
    MockStudent::create(['mock_id' => $this->mock->id, 'name' => 'old', 'code' => '000002', 'phone' => '+998901111113']);

    expect(MockStudent::generateBulkCodes(3))->toBe(['000001', '000003', '000004'])
        ->and(MockStudent::generateUniqueCode())->toBe('000005');
});

test('after 999999 the codes get a seventh digit', function () {
    Setting::set(MockStudent::CODE_SEQUENCE_KEY, '999999');

    expect(MockStudent::generateBulkCodes(2))->toBe(['999999', '1000000'])
        ->and(collect(['999999', '1000000'])->every(fn ($c) => preg_match(MockStudent::CODE_PATTERN, $c) === 1))->toBeTrue();
});
