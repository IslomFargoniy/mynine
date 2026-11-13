<?php

use App\Models\Attempt;
use App\Models\User\User;
use App\Support\UserFacingError;
use Illuminate\Database\QueryException;

test('a user with exam attempts is not deleted, with a plain reason (no SQL)', function () {
    $super = makeSuperAdmin();
    $student = makeUser('Student');
    $exam = makeDesktopExam($super);
    Attempt::create(['user_id' => $student->id, 'test_id' => $exam['testL']->id, 'name' => 'A', 'started_at' => now()]);

    $this->actingAs($super)->delete(route('user.destroy', $student))
        ->assertSessionHasErrors(['error' => __('user_has_results', ['count' => 1])]);
    expect(User::find($student->id))->not->toBeNull();
});

test('database errors become plain sentences; our own messages pass through', function () {
    $fk = new QueryException('mysql', 'delete from `users` where `id` = ?', [182], new PDOException(
        'SQLSTATE[23000]: Integrity constraint violation: 1451 Cannot delete or update a parent row: a foreign key constraint fails'
    ));
    expect(UserFacingError::message($fk))->toBe(__('error_record_in_use'))
        ->and(UserFacingError::message($fk))->not->toContain('SQLSTATE');

    $dup = new QueryException('sqlite', 'insert into x', [], new PDOException('SQLSTATE[23000]: UNIQUE constraint failed: users.email'));
    expect(UserFacingError::message($dup))->toBe(__('error_duplicate_record'));

    expect(UserFacingError::message(new RuntimeException('Folder is not empty.')))->toBe('Folder is not empty.');
});
