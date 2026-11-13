<?php

use App\Models\CenterAuditLog;
use App\Models\CenterSetting;
use App\Models\Device;
use App\Models\Mock;
use App\Models\MockStudent;
use App\Models\Test as ExamTest;
use App\Models\TestImport;
use App\Models\User\User;
use App\Services\ExamService;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Inertia\Testing\AssertableInertia as Assert;
use Laravel\Socialite\Contracts\Factory as SocialiteFactory;
use Laravel\Socialite\Contracts\User as SocialiteUser;
use Laravel\Socialite\Facades\Socialite;

/*
|--------------------------------------------------------------------------
| Backfill migration
|--------------------------------------------------------------------------
*/

test('the backfill gives all existing data to the SuperAdmin\'s Mynine center and demotes other Admins', function () {
    seedRoles();
    $owner = User::factory()->create(['email' => 'abdurahmanislam304@gmail.com']);
    $owner->assignRole('Admin');
    $oldAdmin = User::factory()->create();
    $oldAdmin->assignRole('Admin');
    $reception = User::factory()->create();
    $reception->assignRole('Reception');
    $student = User::factory()->create();
    $student->assignRole('Student');

    DB::table('settings')->insert([
        ['key' => 'desktop_exit_password', 'value' => Hash::make('legacy-pass'), 'created_at' => now(), 'updated_at' => now()],
        ['key' => 'desktop_exit_password_offline', 'value' => 'pbkdf2_sha256$120000$c2FsdA==$aGFzaA==', 'created_at' => now(), 'updated_at' => now()],
        ['key' => 'desktop_background', 'value' => json_encode(['path' => 'desktop/bg.png', 'sha256' => 'abc']), 'created_at' => now(), 'updated_at' => now()],
    ]);

    // Legacy rows: no owner yet.
    $mockId = DB::table('mocks')->insertGetId([
        'name' => 'Old mock', 'user_id' => $oldAdmin->id, 'slug' => 'old', 'active' => 1,
        'started_at' => now(), 'finished_at' => now()->addHour(), 'created_at' => now(), 'updated_at' => now(),
    ]);
    $testId = DB::table('tests')->insertGetId(['name' => 'Old bank', 'purpose' => 'mock', 'active' => 1, 'open' => 0, 'created_at' => now(), 'updated_at' => now()]);
    $practiceId = DB::table('tests')->insertGetId(['name' => 'Practice', 'purpose' => 'practice', 'active' => 1, 'open' => 1, 'created_at' => now(), 'updated_at' => now()]);
    $deviceId = DB::table('devices')->insertGetId(['machine_id' => 'OLD-PC', 'name' => 'PC', 'token_hash' => str_repeat('a', 64), 'created_at' => now(), 'updated_at' => now()]);
    $importId = DB::table('test_imports')->insertGetId(['test_id' => $testId, 'status' => 'done', 'created_at' => now(), 'updated_at' => now()]);

    $migration = require database_path('migrations/2026_11_12_000003_backfill_mynine_center.php');
    $migration->up();
    $migration->up(); // idempotent
    app()['cache']->forget(config('permission.cache.key'));

    $owner = $owner->fresh();
    $oldAdmin = $oldAdmin->fresh();
    expect($owner->hasRole('SuperAdmin'))->toBeTrue()
        ->and($owner->hasRole('Admin'))->toBeTrue()
        ->and($oldAdmin->hasRole('Admin'))->toBeFalse()
        ->and($oldAdmin->hasRole('Reception'))->toBeTrue()
        ->and($oldAdmin->owner_id)->toBe($owner->id)
        ->and($reception->fresh()->owner_id)->toBe($owner->id)
        ->and($student->fresh()->owner_id)->toBeNull()
        ->and(DB::table('mocks')->where('id', $mockId)->value('owner_id'))->toBe($owner->id)
        ->and(DB::table('tests')->where('id', $testId)->value('owner_id'))->toBe($owner->id)
        ->and(DB::table('tests')->where('id', $practiceId)->value('owner_id'))->toBe($owner->id)
        ->and(DB::table('devices')->where('id', $deviceId)->value('owner_id'))->toBe($owner->id)
        ->and(DB::table('test_imports')->where('id', $importId)->value('owner_id'))->toBe($owner->id);

    $settings = CenterSetting::where('owner_id', $owner->id)->sole();
    expect($settings->code)->toBe('MYNINE')
        ->and($settings->name)->toBe('Mynine')
        ->and($settings->checkExitPassword('legacy-pass'))->toBeTrue()
        ->and($settings->exit_password_offline)->toBe('pbkdf2_sha256$120000$c2FsdA==$aGFzaA==')
        ->and(json_decode($settings->background, true)['path'])->toBe('desktop/bg.png')
        ->and(CenterSetting::count())->toBe(1);

    // down() gives the demoted Admins their role back.
    $migration->down();
    app()['cache']->forget(config('permission.cache.key'));
    expect($oldAdmin->fresh()->hasRole('Admin'))->toBeTrue()
        ->and($oldAdmin->fresh()->hasRole('Reception'))->toBeFalse();
});

test('the backfill does nothing without the SuperAdmin user', function () {
    $admin = makeUser('Student');
    $migration = require database_path('migrations/2026_11_12_000003_backfill_mynine_center.php');
    $migration->up();

    expect(CenterSetting::count())->toBe(0)
        ->and($admin->fresh()->owner_id)->toBeNull();
});

/*
|--------------------------------------------------------------------------
| Centers page (SuperAdmin)
|--------------------------------------------------------------------------
*/

test('the SuperAdmin creates a center with its Admin; codes are unique and uppercase', function () {
    $super = makeSuperAdmin();

    $this->actingAs($super)->post(route('centers.store'), [
        'name' => 'Smart Academy', 'code' => 'smart1', 'admin_name' => 'Aziz', 'email' => 'aziz@example.com', 'contract_until' => '2027-12-31',
    ])->assertSessionHasNoErrors()->assertSessionHas('success');

    $admin = User::where('email', 'aziz@example.com')->sole();
    $settings = $admin->centerSetting;
    expect($admin->hasRole('Admin'))->toBeTrue()
        ->and($admin->isSuperAdmin())->toBeFalse()
        ->and($settings->code)->toBe('SMART1')
        ->and($settings->contract_until->toDateString())->toBe('2027-12-31')
        ->and(CenterAuditLog::where('action', 'center_created')->where('center_id', $admin->id)->exists())->toBeTrue();

    $this->actingAs($super)->post(route('centers.store'), ['name' => 'X', 'code' => 'SMART1', 'admin_name' => 'Y', 'email' => 'y@example.com'])
        ->assertSessionHasErrors('code');
    $this->actingAs($super)->post(route('centers.store'), ['name' => 'X', 'code' => 'A!', 'admin_name' => 'Y', 'email' => 'y@example.com'])
        ->assertSessionHasErrors('code');
    $this->actingAs($super)->post(route('centers.store'), ['name' => 'X', 'code' => 'NEWONE', 'admin_name' => 'Y', 'email' => 'aziz@example.com'])
        ->assertSessionHasErrors('email');
});

test('only the SuperAdmin manages centers', function () {
    $center = makeCenter();
    $other = makeCenter('OTHER');

    $this->actingAs($center)->get(route('centers.index'))->assertForbidden();
    $this->actingAs($center)->post(route('centers.store'), ['name' => 'X', 'code' => 'XXX', 'admin_name' => 'Y', 'email' => 'y@example.com'])->assertForbidden();
    $this->actingAs($center)->post(route('centers.status', $other), ['status' => 'suspended'])->assertForbidden();
    $this->actingAs($center)->post(route('centers.replace-admin', $other), ['email' => 'evil@example.com'])->assertForbidden();
    $this->actingAs(makeUser('Reception'))->get(route('centers.index'))->assertForbidden();

    expect($other->fresh()->email)->not->toBe('evil@example.com');
});

test('the Mynine center cannot be suspended and its code is fixed', function () {
    $super = makeSuperAdmin();

    $this->actingAs($super)->post(route('centers.status', $super), ['status' => 'suspended'])->assertSessionHas('error');
    $this->actingAs($super)->patch(route('centers.update', $super), ['name' => 'Mynine', 'code' => 'OTHER', 'admin_name' => 'Owner'])->assertSessionHas('error');

    expect(centerSettings($super)->status)->toBe('active')->and(centerSettings($super)->code)->toBe('MYNINE');
});

/*
|--------------------------------------------------------------------------
| Replace admin
|--------------------------------------------------------------------------
*/

test('replacing a center\'s admin clears the old person\'s logins, ends their sessions and writes an audit row', function () {
    config(['session.driver' => 'database']);
    $super = makeSuperAdmin();
    $center = makeCenter('ACME');
    $center->forceFill([
        'email' => 'old@example.com', 'google_id' => 'g-old', 'github_id' => 'gh-old', 'telegram_id' => '111',
        'username' => 'oldie', 'avatar' => 'https://t.me/old.jpg', 'phone' => '+998901112233', 'remember_token' => 'old-token',
        'password' => Hash::make('old-password'),
    ])->saveQuietly();
    $exam = makeDesktopExam($center, [], '333333');

    DB::table('sessions')->insert([
        ['id' => 'old-session-1', 'user_id' => $center->id, 'payload' => 'x', 'last_activity' => time()],
        ['id' => 'someone-else', 'user_id' => $super->id, 'payload' => 'x', 'last_activity' => time()],
    ]);

    $this->actingAs($super)->post(route('centers.replace-admin', $center), ['email' => 'New@Example.com', 'name' => 'New Person'])
        ->assertSessionHas('success');

    $center = $center->fresh();
    expect($center->email)->toBe('new@example.com')
        ->and($center->name)->toBe('New Person')
        ->and($center->google_id)->toBeNull()
        ->and($center->github_id)->toBeNull()
        ->and($center->telegram_id)->toBeNull()
        ->and($center->username)->toBeNull()
        ->and($center->avatar)->toBeNull()
        ->and($center->phone)->toBeNull()
        ->and($center->remember_token)->not->toBe('old-token')
        ->and(Hash::check('old-password', $center->password))->toBeFalse()
        ->and($center->hasRole('Admin'))->toBeTrue()
        ->and(DB::table('sessions')->where('user_id', $center->id)->exists())->toBeFalse()
        ->and(DB::table('sessions')->where('id', 'someone-else')->exists())->toBeTrue();

    // The center's data stays with the account.
    expect(Mock::withoutGlobalScopes()->find($exam['mock']->id)->owner_id)->toBe($center->id);

    $log = CenterAuditLog::where('action', 'admin_replaced')->sole();
    expect($log->center_id)->toBe($center->id)
        ->and($log->actor_id)->toBe($super->id)
        ->and($log->old_email)->toBe('old@example.com')
        ->and($log->new_email)->toBe('new@example.com');

    // The old person cannot sign in with the old password, phone or email any more.
    $this->post(route('logout'));
    $this->post(route('login'), ['email_or_phone' => 'old@example.com', 'password' => 'old-password']);
    $this->assertGuest();
    $this->post(route('login'), ['email_or_phone' => '+998901112233', 'password' => 'old-password']);
    $this->assertGuest();
});

test('Replace admin can take the email of an ordinary user: that account is archived, the person signs in to the center', function () {
    config(['session.driver' => 'database']);
    $super = makeSuperAdmin();
    $center = makeCenter('NOVA');
    $student = makeUser('Student');
    $student->forceFill(['email' => 'person@example.com', 'google_id' => 'g-person', 'telegram_id' => '555'])->saveQuietly();
    DB::table('sessions')->insert(['id' => 'student-session', 'user_id' => $student->id, 'payload' => 'x', 'last_activity' => time()]);

    $this->actingAs($super)->post(route('centers.replace-admin', $center), ['email' => 'Person@Example.com'])
        ->assertSessionHasNoErrors()->assertSessionHas('success');

    $student = $student->fresh();
    expect($center->fresh()->email)->toBe('person@example.com')
        ->and($student->email)->toEndWith('@mynine.invalid')
        ->and($student->google_id)->toBeNull()
        ->and($student->telegram_id)->toBeNull()
        ->and($student->hasRole('Student'))->toBeTrue()
        ->and(DB::table('sessions')->where('id', 'student-session')->exists())->toBeFalse();
    expect(CenterAuditLog::where('action', 'admin_replaced')->sole()->meta['archived_user_id'] ?? null)->toBe($student->id);

    // Google sign-in with that address now opens the center.
    $this->post(route('logout'));
    fakeGoogleUser('g-person', 'person@example.com');
    $this->get(route('google.callback'))->assertRedirect(route('dashboard'));
    expect(auth()->id())->toBe($center->id);
});

test('Replace admin cannot take the email of staff or another center', function () {
    $super = makeSuperAdmin();
    $center = makeCenter('NOVA');
    $other = makeCenter('ACME');
    $other->forceFill(['email' => 'acme@example.com'])->saveQuietly();

    $this->actingAs($super)->post(route('centers.replace-admin', $center), ['email' => 'acme@example.com'])
        ->assertSessionHasErrors('email');
    $this->actingAs($super)->post(route('centers.replace-admin', $center), ['email' => $super->email])
        ->assertSessionHasErrors('email');
    expect($other->fresh()->email)->toBe('acme@example.com')
        ->and($center->fresh()->email)->not->toBe('acme@example.com');
});

test('the SuperAdmin\'s own account cannot be replaced', function () {
    $super = makeSuperAdmin();
    $this->actingAs($super)->post(route('centers.replace-admin', $super), ['email' => 'x@example.com'])->assertSessionHas('error');
    expect($super->fresh()->email)->not->toBe('x@example.com');
});

function fakeGoogleUser(string $id, string $email): void
{
    $googleUser = Mockery::mock(SocialiteUser::class);
    $googleUser->shouldReceive('getId')->andReturn($id);
    $googleUser->shouldReceive('getEmail')->andReturn($email);
    $googleUser->shouldReceive('getName')->andReturn('Google Person');
    $googleUser->shouldReceive('getAvatar')->andReturn(null);

    $provider = Mockery::mock();
    $provider->shouldReceive('user')->andReturn($googleUser);
    $factory = Mockery::mock(SocialiteFactory::class);
    $factory->shouldReceive('driver')->with('google')->andReturn($provider);
    Socialite::swap($factory);
}

test('after Replace admin the new person signs in with Google and gets the center; the old person does not', function () {
    $super = makeSuperAdmin();
    $center = makeCenter('ACME');
    $center->forceFill(['email' => 'old@example.com', 'google_id' => 'g-old'])->saveQuietly();
    // The new person used Mynine before with the same Google account (linked to a student account).
    $studentOfNewPerson = makeUser('Student');
    $studentOfNewPerson->forceFill(['google_id' => 'g-new', 'email' => 'student-new@example.com'])->saveQuietly();

    $r = $this->actingAs($super)->post(route('centers.replace-admin', $center), ['email' => 'new@example.com']);
    $r->assertSessionHas('success');
    $this->post(route('logout'));

    // Old person: their Google account no longer matches the center.
    fakeGoogleUser('g-old', 'old@example.com');
    $this->get(route('google.callback'))->assertRedirect(route('dashboard'));
    expect(auth()->id())->not->toBe($center->id)
        ->and(auth()->user()->isStaff())->toBeFalse();
    $this->post(route('logout'));

    // New person: the center account, google_id filled.
    fakeGoogleUser('g-new', 'new@example.com');
    $this->get(route('google.callback'))->assertRedirect(route('dashboard'));
    expect(auth()->id())->toBe($center->id)
        ->and($center->fresh()->google_id)->toBe('g-new')
        ->and($studentOfNewPerson->fresh()->google_id)->toBeNull();
});

/*
|--------------------------------------------------------------------------
| Connect Telegram
|--------------------------------------------------------------------------
*/

function signedTelegramWidget(array $data): array
{
    config(['services.telegram.mynine_bot_token' => '123:TEST-TOKEN']);
    $data['auth_date'] ??= time();
    $check = collect($data)->map(fn ($v, $k) => $k.'='.$v)->sort()->implode("\n");
    $data['hash'] = hash_hmac('sha256', $check, hash('sha256', '123:TEST-TOKEN', true));

    return $data;
}

test('Connect Telegram links the verified Telegram account to the current user', function () {
    $admin = makeCenter();

    $this->actingAs($admin)->post(route('profile.telegram.connect'), signedTelegramWidget(['id' => 777, 'first_name' => 'Ali']))
        ->assertSessionHas('success');
    expect($admin->fresh()->telegram_id)->toBe('777');

    // Then Telegram sign-in finds the same account.
    $this->post(route('logout'));
    $this->get(route('telegram.callback', signedTelegramWidget(['id' => 777, 'first_name' => 'Ali'])))->assertRedirect(route('dashboard'));
    expect(auth()->id())->toBe($admin->id);
});

test('Connect Telegram refuses a Telegram account of another user and a forged signature', function () {
    $other = makeUser('Student');
    $other->forceFill(['telegram_id' => '888'])->saveQuietly();
    $admin = makeCenter();

    $this->actingAs($admin)->post(route('profile.telegram.connect'), signedTelegramWidget(['id' => 888, 'first_name' => 'X']))
        ->assertSessionHas('error', __('telegram_already_linked'));
    expect($admin->fresh()->telegram_id)->toBeNull()->and($other->fresh()->telegram_id)->toBe('888');

    $forged = signedTelegramWidget(['id' => 999, 'first_name' => 'X']);
    $forged['id'] = 1000;
    $this->actingAs($admin)->post(route('profile.telegram.connect'), $forged)->assertSessionHas('error');
    expect($admin->fresh()->telegram_id)->toBeNull();
});

/*
|--------------------------------------------------------------------------
| Suspended centers
|--------------------------------------------------------------------------
*/

test('a suspended center is read-only for its staff; exams cannot start', function () {
    $mynine = makeCenter();
    $center = makeCenter('SLEEPY');
    $reception = makeUser('Reception', $center);
    $exam = makeDesktopExam($center, [], '444444');
    $attempt = app(ExamService::class)->findOrCreateMockAttempt($exam['student']);
    $deviceToken = registerDesktopDevice('PC-SLEEPY', 'PC', true, $center);

    centerSettings($center)->forceFill(['status' => CenterSetting::STATUS_SUSPENDED])->save();

    // Read: allowed.
    $this->actingAs($center)->get(route('mock.index'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->where('auth.center.suspended', true));
    $this->actingAs($reception)->get(route('reception.index'))->assertOk();
    $this->actingAs($center)->get(route('mock.code-cards', $exam['mock']))->assertOk();

    // Write: refused.
    $this->actingAs($center)->from(route('mock.index'))->post(route('mock.store'), [
        'name' => 'New', 'started_at' => now()->format('Y-m-d H:i'), 'finished_at' => now()->addHour()->format('Y-m-d H:i'),
        'modules' => [$exam['listening']->id],
    ])->assertSessionHas('error', __('center_suspended'));
    $this->actingAs($reception)->post(route('mock-student.store'), ['mock_id' => $exam['mock']->id, 'text' => 'Ali ; 901234567'])
        ->assertSessionHas('error', __('center_suspended'));
    $this->actingAs($center)->postJson(route('monitor.pause', $attempt))
        ->assertStatus(403)->assertJsonPath('code', 'center_suspended');
    expect($attempt->fresh()->paused_at)->toBeNull();

    expect(Mock::withoutGlobalScopes()->where('owner_id', $center->id)->count())->toBe(1)
        ->and(MockStudent::withoutGlobalScopes()->where('mock_id', $exam['mock']->id)->count())->toBe(1);

    // Desktop: candidate login and new PCs refused; web code entry too.
    desktopApi('POST', 'exam/login', ['code' => $exam['student']->code], $deviceToken)
        ->assertStatus(403)->assertJsonPath('code', 'center_suspended');
    desktopApi('POST', 'device/register', ['machine_id' => 'PC-NEW', 'password' => 'center-pass', 'center_code' => 'SLEEPY'])
        ->assertStatus(403)->assertJsonPath('code', 'center_suspended');
    $exam['mock']->forceFill(['require_desktop' => false])->saveQuietly();
    $this->post(route('mock-student.enter'), ['code' => $exam['student']->code])->assertSessionHasErrors('code');
    $this->assertGuest();

    // Other centers are unaffected.
    $mynineExam = makeDesktopExam($mynine, [], '444445');
    $this->actingAs($mynine)->post(route('mock-student.store'), ['mock_id' => $mynineExam['mock']->id, 'text' => 'Ali ; 901234567'])
        ->assertSessionHas('success');

    // The SuperAdmin is never blocked, even while working as the suspended center.
    $super = makeSuperAdmin();
    $this->actingAs($super)->post(route('centers.switch', $center));
    $this->actingAs($super)->post(route('mock-student.store'), ['mock_id' => $exam['mock']->id, 'text' => 'Vali ; 901234568'])
        ->assertSessionHas('success');
    expect(MockStudent::withoutGlobalScopes()->where('mock_id', $exam['mock']->id)->count())->toBe(2);
});

test('a center whose contract ended counts as suspended', function () {
    makeCenter();
    $center = makeCenter('LATE');
    $exam = makeDesktopExam($center, [], '555555');
    $deviceToken = registerDesktopDevice('PC-LATE', 'PC', true, $center);
    centerSettings($center)->forceFill(['contract_until' => now()->subDay()->toDateString()])->save();

    expect(centerSettings($center)->isSuspended())->toBeTrue();
    desktopApi('POST', 'exam/login', ['code' => $exam['student']->code], $deviceToken)->assertStatus(403)->assertJsonPath('code', 'center_suspended');

    centerSettings($center)->forceFill(['contract_until' => now()->toDateString()])->save();
    expect(centerSettings($center)->fresh()->isSuspended())->toBeFalse();
    desktopApi('POST', 'exam/login', ['code' => $exam['student']->code], $deviceToken)->assertOk();
});

test('suspending and activating a center is audited and visible on the Centers page', function () {
    $super = makeSuperAdmin();
    $center = makeCenter('ZZZ');

    $this->actingAs($super)->post(route('centers.status', $center), ['status' => 'suspended'])->assertSessionHas('success');
    expect(centerSettings($center)->isSuspended())->toBeTrue();
    $this->actingAs($super)->post(route('centers.status', $center), ['status' => 'active'])->assertSessionHas('success');
    expect(centerSettings($center)->fresh()->isSuspended())->toBeFalse()
        ->and(CenterAuditLog::where('center_id', $center->id)->pluck('action')->all())->toContain('center_suspended', 'center_activated');
});

/*
|--------------------------------------------------------------------------
| Desktop registration with a center code
|--------------------------------------------------------------------------
*/

test('a PC registers to the center of its center_code with that center\'s password', function () {
    $mynine = makeCenter();
    $center = makeCenter('ACME');
    centerSettings($mynine)->setExitPassword('mynine-pass');
    centerSettings($center)->setExitPassword('acme-pass');

    desktopApi('POST', 'device/register', ['machine_id' => 'PC-1', 'password' => 'mynine-pass', 'center_code' => 'acme'])
        ->assertStatus(422)->assertJsonPath('code', 'invalid_password');
    desktopApi('POST', 'device/register', ['machine_id' => 'PC-1', 'password' => 'acme-pass', 'center_code' => 'NOPE'])
        ->assertStatus(422)->assertJsonPath('code', 'invalid_center_code');

    $response = desktopApi('POST', 'device/register', ['machine_id' => 'PC-1', 'password' => 'acme-pass', 'center_code' => 'acme'])
        ->assertOk()
        ->assertJsonPath('center.code', 'ACME')
        ->assertJsonPath('exit_password_offline', centerSettings($center)->exit_password_offline);

    expect(Device::withoutGlobalScopes()->find($response->json('device_id'))->owner_id)->toBe($center->id);
});

test('an old client without center_code registers to the Mynine center only', function () {
    $mynine = makeCenter();
    $center = makeCenter('ACME');
    centerSettings($mynine)->setExitPassword('mynine-pass');
    centerSettings($center)->setExitPassword('acme-pass');

    desktopApi('POST', 'device/register', ['machine_id' => 'PC-OLD', 'password' => 'acme-pass'])
        ->assertStatus(422)->assertJsonPath('code', 'invalid_password');

    $id = desktopApi('POST', 'device/register', ['machine_id' => 'PC-OLD', 'password' => 'mynine-pass'])
        ->assertOk()
        ->assertJsonStructure(['device_id', 'device_token', 'name', 'number', 'approved', 'exit_password_offline'])
        ->json('device_id');

    expect(Device::withoutGlobalScopes()->find($id)->owner_id)->toBe($mynine->id);
});

test('a PC registered to another center cannot be taken over; it can move only after that center deletes it', function () {
    $mynine = makeCenter();
    $center = makeCenter('ACME');
    registerDesktopDevice('PC-MOVE', 'PC', true);
    $device = Device::withoutGlobalScopes()->where('machine_id', 'PC-MOVE')->sole();
    $tokenHash = $device->token_hash;
    expect($device->number)->toBe(1)->and($device->owner_id)->toBe($mynine->id);

    centerSettings($center)->setExitPassword('acme-pass');
    desktopApi('POST', 'device/register', ['machine_id' => 'PC-MOVE', 'password' => 'acme-pass', 'center_code' => 'ACME'])
        ->assertStatus(409)
        ->assertJsonPath('code', 'device_other_center')
        ->assertJsonPath('message', 'This PC is registered to another center. Ask that center to remove it first.');

    // The first center's PC is untouched: same center, token, number and approval.
    $device->refresh();
    expect($device->owner_id)->toBe($mynine->id)
        ->and($device->token_hash)->toBe($tokenHash)
        ->and($device->number)->toBe(1)
        ->and($device->is_approved)->toBeTrue();

    $device->delete();
    $id = desktopApi('POST', 'device/register', ['machine_id' => 'PC-MOVE', 'password' => 'acme-pass', 'center_code' => 'ACME'])
        ->assertOk()->json('device_id');

    $moved = Device::withoutGlobalScopes()->findOrFail($id);
    expect($moved->owner_id)->toBe($center->id)
        ->and($moved->number)->toBeNull()
        ->and($moved->is_approved)->toBeFalse();
});

test('PC numbers are unique per center, not globally', function () {
    $mynine = makeCenter();
    $center = makeCenter('ACME');
    registerDesktopDevice('PC-A', 'PC', true);
    registerDesktopDevice('PC-B', 'PC', true, $center);

    expect(Device::withoutGlobalScopes()->where('machine_id', 'PC-A')->value('number'))->toBe(1)
        ->and(Device::withoutGlobalScopes()->where('machine_id', 'PC-B')->value('number'))->toBe(1);

    $other = Device::withoutGlobalScopes()->where('machine_id', 'PC-A')->sole();
    $mine = Device::withoutGlobalScopes()->where('machine_id', 'PC-B')->sole();
    // Number 1 is free in ACME's own list, whatever Mynine uses.
    $this->actingAs($center)->patch(route('desktop.devices.update', $mine), ['number' => 1])->assertSessionHasNoErrors();
    $this->actingAs($mynine)->patch(route('desktop.devices.update', $other), ['number' => 7])->assertSessionHasNoErrors();
    expect($other->fresh()->number)->toBe(7);
});

/*
|--------------------------------------------------------------------------
| Staff page and center settings
|--------------------------------------------------------------------------
*/

test('a center Admin creates, edits and suspends Reception users of their own center only', function () {
    $center = makeCenter();
    $other = makeCenter('OTHER');
    $foreign = makeUser('Reception', $other);

    $this->actingAs($center)->post(route('staff.store'), ['name' => 'Desk 1', 'email' => 'desk1@example.com', 'password' => 'secret123'])
        ->assertSessionHas('success');
    $desk = User::where('email', 'desk1@example.com')->sole();
    expect($desk->hasRole('Reception'))->toBeTrue()
        ->and($desk->hasRole('Admin'))->toBeFalse()
        ->and($desk->owner_id)->toBe($center->id);

    // Cannot hand out other roles: the Staff page only creates Reception users.
    $this->actingAs($center)->post(route('staff.store'), ['name' => 'X', 'email' => 'x@example.com', 'password' => 'secret123', 'role' => 'Admin']);
    expect(User::where('email', 'x@example.com')->sole()->hasRole('Admin'))->toBeFalse();

    $this->actingAs($center)->patch(route('staff.update', $desk), ['name' => 'Desk One', 'email' => 'desk1@example.com'])->assertSessionHas('success');
    expect($desk->fresh()->name)->toBe('Desk One');

    $this->actingAs($center)->patch(route('staff.update', $foreign), ['name' => 'Hacked', 'email' => 'h@example.com'])->assertForbidden();
    $this->actingAs($center)->patch(route('staff.update', $other), ['name' => 'Hacked', 'email' => 'h@example.com'])->assertNotFound();

    // Suspended staff are signed out on their next request.
    $this->actingAs($center)->post(route('staff.suspend', $desk))->assertSessionHas('success');
    $this->actingAs($desk->fresh())->get(route('reception.index'))->assertRedirect(route('login'));
    $this->assertGuest();

    $this->actingAs($center)->post(route('staff.activate', $desk))->assertSessionHas('success');
    $this->actingAs($desk->fresh())->get(route('reception.index'))->assertOk();
});

test('center Admins never reach the website\'s user list; centers cannot be deleted', function () {
    $super = makeSuperAdmin();
    $center = makeCenter('OTHER');

    $this->actingAs($center)->get(route('user.index'))->assertForbidden();
    $this->actingAs($center)->delete(route('user.destroy', makeUser('Student')))->assertForbidden();

    $this->actingAs($super)->delete(route('user.destroy', $center))->assertSessionHasErrors('error');
    $this->actingAs($super)->put(route('user.update', $center), ['name' => 'X', 'role' => 'Student'])->assertSessionHasErrors('error');
    expect(User::find($center->id))->not->toBeNull()->and($center->fresh()->hasRole('Admin'))->toBeTrue();
});

test('the center settings page edits name and logo; the code is read-only', function () {
    Storage::fake('public');
    $center = makeCenter('ACME');

    $this->actingAs($center)->get(route('center.settings'))->assertOk()
        ->assertInertia(fn (Assert $page) => $page->component('center/settings')->where('center.code', 'ACME'));

    $this->actingAs($center)->post(route('center.settings.update'), [
        'name' => 'Acme Learning', 'code' => 'HACK', 'logo' => UploadedFile::fake()->image('logo.png', 64, 64),
    ])->assertSessionHas('success');

    $settings = centerSettings($center)->fresh();
    expect($settings->name)->toBe('Acme Learning')
        ->and($settings->code)->toBe('ACME')
        ->and($settings->logo_path)->not->toBeNull();
    Storage::disk('public')->assertExists($settings->logo_path);

    // The PC config carries the logo.
    $token = registerDesktopDevice('PC-LOGO', 'PC', true, $center);
    desktopApi('GET', 'device/config', [], $token)->assertOk()
        ->assertJsonPath('center.name', 'Acme Learning')
        ->assertJsonPath('center.logo_url', fn ($url) => is_string($url) && str_contains($url, $settings->logo_path));
});

test('owner_id is filled from the current center on create', function () {
    $center = makeCenter('ACME');
    $this->actingAs($center);

    $test = ExamTest::create(['name' => 'Bank', 'purpose' => 'mock', 'folder_id' => null]);
    $import = TestImport::create(['test_id' => $test->id, 'status' => 'queued']);

    expect($test->owner_id)->toBe($center->id)->and($import->owner_id)->toBe($center->id);
});

test('the SuperAdmin edits the code and contract date on Center settings; MYNINE keeps its code', function () {
    $super = makeSuperAdmin();

    $this->actingAs($super)->post(route('center.settings.update'), ['name' => 'Mynine', 'code' => 'MYNINE', 'contract_until' => '2027-12-31'])
        ->assertSessionHas('success');
    expect(centerSettings($super)->fresh()->contract_until->toDateString())->toBe('2027-12-31');

    $this->actingAs($super)->post(route('center.settings.update'), ['name' => 'Mynine', 'code' => 'OTHER'])->assertSessionHas('error');
    expect(centerSettings($super)->fresh()->code)->toBe('MYNINE');

    $partner = makeCenter('BETA');
    $this->actingAs($super)->post(route('centers.switch', $partner))->assertRedirect();
    $this->actingAs($super)->post(route('center.settings.update'), ['name' => 'Beta', 'code' => 'gamma', 'contract_until' => ''])
        ->assertSessionHas('success');
    $settings = centerSettings($partner)->fresh();
    expect($settings->code)->toBe('GAMMA')->and($settings->contract_until)->toBeNull();
});

test('the header center switcher: the SuperAdmin gets every center; switching from a list page stays there', function () {
    $super = makeSuperAdmin();
    $center = makeCenter('NOVA');

    $this->actingAs($super)->get(route('staff.index'))->assertOk()
        ->assertInertia(fn ($page) => $page->where('auth.centers', fn ($centers) => collect($centers)->pluck('id')->contains($center->id)));
    $this->actingAs($center)->get(route('staff.index'))->assertOk()
        ->assertInertia(fn ($page) => $page->where('auth.centers', null));

    $this->actingAs($super)->from(route('staff.index'))->post(route('centers.switch', $center), ['stay' => 1])
        ->assertRedirect(route('staff.index'));
    $this->actingAs($super)->post(route('centers.switch', $center))->assertRedirect(route('mock.index'));
});
