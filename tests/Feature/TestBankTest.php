<?php

use App\Models\Attempt;
use App\Models\Folder;
use App\Models\Test as ExamTest;
use App\Models\TestType;

/**
 * Test Bank (/test-bank): one page for practice tests by folder; admins manage folders and tests there.
 */
function testBankIds($page): array
{
    return collect($page->toArray()['props']['folder']['data'])->pluck('tests')->flatten(1)->pluck('id')->sort()->values()->all();
}

beforeEach(function () {
    // Practice content (folders, practice tests) is managed by the platform owner.
    $this->admin = makeUser('SuperAdmin');

    // Visible: active folder, active + open test with content.
    $this->visible = makeTestContent($this->admin, 'Reading', ['name' => 'Visible']);
    $folder = $this->visible['folder'];

    $this->inactive = ExamTest::create(['folder_id' => $folder->id, 'name' => 'Inactive', 'active' => 0, 'open' => 1]);
    $this->closed = ExamTest::create(['folder_id' => $folder->id, 'name' => 'Closed', 'active' => 1, 'open' => 0]);
    $this->mock = ExamTest::create(['folder_id' => $folder->id, 'name' => 'Bank', 'active' => 1, 'open' => 1, 'purpose' => 'mock']);

    // An empty module (no parts) on the visible test: hidden from students, shown to admins.
    $this->emptyModule = TestType::create(['test_id' => $this->visible['test']->id, 'type_id' => makeType('Writing')->id]);

    $this->hiddenFolder = Folder::create(['name' => 'Hidden folder', 'user_id' => $this->admin->id, 'active' => 0]);
    $this->hiddenFolderTest = ExamTest::create(['folder_id' => $this->hiddenFolder->id, 'name' => 'In hidden folder', 'active' => 1, 'open' => 1]);
    $this->emptyFolder = Folder::create(['name' => 'Empty folder', 'user_id' => $this->admin->id, 'active' => 1]);
});

test('students see only active folders with active, open practice tests', function (string $role) {
    $user = makeUser($role);

    $this->actingAs($user)->get(route('test-bank.index'))
        ->assertOk()
        ->assertInertia(function ($page) {
            $page->component('test-bank/index')->where('isAdmin', false);

            $props = $page->toArray()['props'];
            expect(testBankIds($page))->toBe([$this->visible['test']->id])
                ->and(collect($props['folder']['data'])->pluck('id')->all())->toBe([$this->visible['folder']->id])
                ->and(collect($props['folder']['data'][0]['tests'][0]['types'])->pluck('id')->all())->toBe([$this->visible['testType']->id])
                ->and(collect($props['folders'])->pluck('id')->all())->not->toContain($this->hiddenFolder->id);
        });
})->with(['Student']);

test('admins see every practice test and folder, including inactive, closed and empty ones, but never Mock Bank tests', function () {
    $this->actingAs($this->admin)->get(route('test-bank.index'))
        ->assertOk()
        ->assertInertia(function ($page) {
            $page->component('test-bank/index')->where('isAdmin', true);

            $props = $page->toArray()['props'];
            $expected = collect([$this->visible['test']->id, $this->inactive->id, $this->closed->id, $this->hiddenFolderTest->id])->sort()->values()->all();
            expect(testBankIds($page))->toBe($expected)
                ->and(testBankIds($page))->not->toContain($this->mock->id)
                ->and(collect($props['folder']['data'])->pluck('id')->all())->toContain($this->hiddenFolder->id, $this->emptyFolder->id)
                ->and(collect($props['folder']['data'][0]['tests'][0]['types'])->pluck('id')->all())->toContain($this->emptyModule->id);
        });
});

test('the folder filter limits the page to one folder', function () {
    $this->actingAs($this->admin)->get(route('test-bank.index', ['folder_id' => $this->emptyFolder->id]))
        ->assertInertia(fn ($page) => $page->where('folder.data', fn ($folders) => collect($folders)->pluck('id')->all() === [$this->emptyFolder->id]));
});

test('old URLs redirect to the Test Bank', function () {
    $student = makeUser('Student');

    $this->actingAs($student)->get('/all-test?search=abc')->assertRedirect(route('test-bank.index', ['search' => 'abc']));
    $this->actingAs($this->admin)->get('/folder')->assertRedirect(route('test-bank.index'));
    $this->actingAs($this->admin)->get('/folder/'.$this->emptyFolder->id)->assertRedirect(route('test-bank.index', ['folder_id' => $this->emptyFolder->id]));
});

test('guests are sent to login', function () {
    $this->get(route('test-bank.index'))->assertRedirect(route('login'));
});

test('admins manage folders and tests from the Test Bank', function () {
    $this->actingAs($this->admin)->from(route('test-bank.index'));

    $this->post(route('folder.store'), ['name' => 'New folder'])->assertRedirect(route('test-bank.index'))->assertSessionHas('success');
    $folder = Folder::where('name', 'New folder')->firstOrFail();

    $this->put(route('folder.update', $folder), ['name' => 'Renamed', 'active' => 0])->assertRedirect(route('test-bank.index'));
    expect($folder->fresh()->name)->toBe('Renamed')->and((int) $folder->fresh()->active)->toBe(0);

    $this->post(route('test.store'), ['folder_id' => $folder->id, 'name' => 'Fresh test'])->assertRedirect(route('test-bank.index'));
    $test = ExamTest::where('name', 'Fresh test')->firstOrFail();

    // Toggle active / open the way the card buttons do (full payload to test.update).
    $this->post(route('test.update', $test), ['name' => 'Fresh test', 'comment' => '', 'active' => 0, 'open' => 1])->assertRedirect(route('test-bank.index'));
    expect((int) $test->fresh()->active)->toBe(0)->and((int) $test->fresh()->open)->toBe(1);

    $this->delete(route('test.destroy', $test))->assertRedirect(route('test-bank.index'))->assertSessionHas('success');
    expect(ExamTest::find($test->id))->toBeNull();

    $this->delete(route('folder.destroy', $folder))->assertRedirect(route('test-bank.index'))->assertSessionHas('success');
    expect(Folder::find($folder->id))->toBeNull();
});

test('a folder whose tests have attempts cannot be deleted', function () {
    Attempt::create(['user_id' => $this->admin->id, 'test_id' => $this->visible['test']->id, 'name' => 'A', 'started_at' => now()]);

    $this->actingAs($this->admin)->from(route('test-bank.index'))
        ->delete(route('folder.destroy', $this->visible['folder']))
        ->assertSessionHasErrors('error');

    expect(Folder::find($this->visible['folder']->id))->not->toBeNull();
});

test('students and reception cannot use the admin actions', function (string $role) {
    $user = makeUser($role);
    $folder = $this->visible['folder'];
    $test = $this->visible['test'];

    $this->actingAs($user)->post(route('folder.store'), ['name' => 'X'])->assertForbidden();
    $this->actingAs($user)->put(route('folder.update', $folder), ['name' => 'X'])->assertForbidden();
    $this->actingAs($user)->delete(route('folder.destroy', $folder))->assertForbidden();
    $this->actingAs($user)->post(route('test.store'), ['folder_id' => $folder->id, 'name' => 'X'])->assertForbidden();
    $this->actingAs($user)->post(route('test.update', $test), ['name' => 'X', 'active' => 0])->assertForbidden();
    $this->actingAs($user)->delete(route('test.destroy', $test))->assertForbidden();

    expect($folder->fresh())->not->toBeNull()->and($test->fresh()->name)->toBe('Visible')->and((int) $test->fresh()->active)->toBe(1);
})->with(['Student']);
