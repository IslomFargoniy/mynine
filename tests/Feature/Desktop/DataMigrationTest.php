<?php

use App\Models\Mock;
use App\Models\Part;
use App\Models\Test as ExamTest;
use App\Models\TestType;
use Illuminate\Support\Facades\DB;

test('legacy mocks move their test into the Mock Bank and get one module per type', function () {
    $admin = makeUser('Admin');
    ['test' => $legacy, 'testType' => $reading] = makeTestContent($admin, 'Reading');
    $listening = TestType::create(['test_id' => $legacy->id, 'type_id' => makeType('Listening')->id]);
    Part::create(['test_type_id' => $listening->id, 'name' => 'Part 1', 'minute' => 30]);
    TestType::create(['test_id' => $legacy->id, 'type_id' => makeType('Writing')->id]); // no parts
    ['test' => $practice] = makeTestContent($admin, 'Reading');

    $mock = Mock::create([
        'name' => 'Legacy', 'test_id' => $legacy->id, 'user_id' => $admin->id, 'slug' => 'legacy',
        'started_at' => now(), 'finished_at' => now()->addHour(), 'active' => 1,
    ]);

    $modules = require database_path('migrations/2026_11_10_000005_create_mock_modules_table.php');
    $purpose = require database_path('migrations/2026_11_10_000002_add_purpose_and_bank_status_to_tests_table.php');
    $modules->down();
    $purpose->down();
    $purpose->up();
    $modules->up();

    $row = DB::table('tests')->where('id', $legacy->id)->first();
    expect($row->purpose)->toBe('mock')
        ->and((int) $row->open)->toBe(0)
        ->and($row->bank_status)->toBe('ready')
        ->and(ExamTest::find($practice->id)->purpose)->toBe('practice');

    expect(DB::table('mock_modules')->where('mock_id', $mock->id)->orderBy('test_type_id')->pluck('test_type_id')->all())
        ->toBe([$reading->id, $listening->id]);
});
