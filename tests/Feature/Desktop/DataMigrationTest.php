<?php

use App\Models\Mock;
use App\Models\Part;
use App\Models\Test as ExamTest;
use App\Models\TestType;
use Illuminate\Database\QueryException;
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

test('mock bank tests are detached from their folders and folder_id becomes nullable', function () {
    $admin = makeUser('Admin');
    ['test' => $bank, 'folder' => $folder] = makeTestContent($admin, 'Reading', ['purpose' => 'mock', 'open' => 0]);
    ['test' => $practice] = makeTestContent($admin, 'Reading');

    $migration = require database_path('migrations/2026_11_10_000015_make_tests_folder_id_nullable.php');

    // SQLite rebuilds the table to change a column; inside the test transaction the referencing rows
    // (test_types) are only checked at commit time.
    DB::statement('PRAGMA defer_foreign_keys = ON');

    // Simulate the pre-migration state: the bank test still sits in a folder.
    $migration->down();
    DB::table('tests')->where('id', $bank->id)->update(['folder_id' => $folder->id]);
    expect(DB::table('tests')->where('id', $bank->id)->value('folder_id'))->not->toBeNull();

    $migration->up();
    DB::statement('PRAGMA defer_foreign_keys = OFF');

    expect(DB::table('tests')->where('id', $bank->id)->value('folder_id'))->toBeNull()
        ->and((int) DB::table('tests')->where('id', $practice->id)->value('folder_id'))->toBe((int) $practice->folder_id);

    // The column accepts NULL for new folderless tests and the foreign key still restricts deleting a used folder.
    $new = ExamTest::create(['folder_id' => null, 'name' => 'Folderless', 'purpose' => 'mock']);
    expect($new->fresh()->folder_id)->toBeNull();

    expect(fn () => DB::table('folders')->where('id', $practice->folder_id)->delete())->toThrow(QueryException::class);
});
