<?php

use App\Models\AppRelease;
use App\Models\Device;
use App\Models\Setting;
use Illuminate\Support\Facades\Storage;

function makeRelease(string $version, array $attributes = []): AppRelease
{
    return AppRelease::create(array_merge([
        'version' => $version,
        'notes' => "Release {$version}",
        'mandatory' => false,
        'file_path' => AppRelease::DIRECTORY."/mynine-setup-{$version}.exe",
        'file_size' => 10,
        'sha256' => hash('sha256', $version),
        'is_active' => true,
    ], $attributes));
}

test('device registration stores only the token hash and re-registering rotates it', function () {
    $response = desktopApi('POST', 'device/register', ['machine_id' => 'GUID-1', 'name' => 'PC-07', 'os_version' => 'Windows 11', 'app_version' => '1.0.0'])
        ->assertOk()
        ->assertJsonStructure(['device_id', 'device_token', 'name']);

    $token = $response->json('device_token');
    $device = Device::findOrFail($response->json('device_id'));
    expect($device->token_hash)->toBe(hash('sha256', $token))
        ->and($device->machine_id)->toBe('GUID-1');

    desktopApi('GET', 'device/config', [], $token)->assertForbidden();
    $device->approve();
    desktopApi('GET', 'device/config', [], $token)->assertOk();

    $rotated = desktopApi('POST', 'device/register', ['machine_id' => 'GUID-1', 'name' => 'PC-07b'])->assertOk();
    expect($rotated->json('device_id'))->toBe($device->id)
        ->and($rotated->json('device_token'))->not->toBe($token)
        ->and(Device::count())->toBe(1);

    desktopApi('GET', 'device/config', [], $token)->assertStatus(401)->assertJsonPath('code', 'unauthenticated');
    desktopApi('POST', 'device/heartbeat', ['state' => 'idle'], $rotated->json('device_token'))->assertOk();

    desktopApi('POST', 'device/register', ['name' => 'x'])->assertStatus(422)->assertJsonPath('code', 'validation_failed');
});

test('blocked devices are refused', function () {
    $token = registerDesktopDevice('GUID-B');
    Device::where('machine_id', 'GUID-B')->update(['is_blocked' => true]);

    desktopApi('POST', 'device/heartbeat', ['state' => 'idle'], $token)->assertStatus(403)->assertJsonPath('code', 'device_blocked');
    desktopApi('POST', 'device/register', ['machine_id' => 'GUID-B', 'name' => 'PC'])->assertStatus(403)->assertJsonPath('code', 'device_blocked');
});

test('device heartbeat marks the PC online', function () {
    $token = registerDesktopDevice('GUID-H');
    $this->travel(5)->minutes();

    desktopApi('POST', 'device/heartbeat', ['app_version' => '1.1.0', 'state' => 'idle'], $token)
        ->assertOk()
        ->assertJsonStructure(['server_time', 'unlock'])
        ->assertJsonPath('unlock', false);

    $device = Device::where('machine_id', 'GUID-H')->first();
    expect($device->app_version)->toBe('1.1.0')
        ->and($device->last_seen_at->diffInSeconds(now(), true))->toBeLessThan(2);

    desktopApi('POST', 'device/heartbeat', ['state' => 'sleeping'], $token)->assertStatus(422);
});

test('exam endpoints reject outdated clients with 426', function () {
    $admin = makeUser('Admin');
    makeDesktopExam($admin);
    $token = registerDesktopDevice();

    makeRelease('1.1.0', ['mandatory' => true]);
    makeRelease('1.2.0');

    desktopApi('POST', 'exam/login', ['code' => 'MOCK-100001'], $token, null, '1.0.9')
        ->assertStatus(426)
        ->assertJsonPath('code', 'client_outdated')
        ->assertJsonPath('min_version', '1.1.0');

    // App and device endpoints stay reachable so the PC can update itself.
    desktopApi('GET', 'app/version', [], null, null, '1.0.9')->assertOk();
    desktopApi('POST', 'device/heartbeat', ['state' => 'updating'], $token, null, '1.0.9')->assertOk();

    desktopApi('POST', 'exam/login', ['code' => 'MOCK-100001'], $token, null, '1.1.0')->assertOk();

    app('auth')->forgetGuards();
    $this->postJson('/api/v1/exam/login', ['code' => 'MOCK-100001'], ['X-Device-Token' => $token])
        ->assertStatus(426);
});

test('app version picks the highest active release and the highest mandatory one as minimum', function () {
    desktopApi('GET', 'app/version')->assertOk()
        ->assertJsonPath('latest', null)
        ->assertJsonPath('min_version', null)
        ->assertJsonPath('update_available', false);

    makeRelease('1.0.0', ['mandatory' => true]);
    makeRelease('1.1.0', ['mandatory' => true]);
    makeRelease('1.10.0', ['is_active' => false]);
    makeRelease('1.9.0', ['mandatory' => true, 'is_active' => false]);
    $latest = makeRelease('1.2.0');

    $response = desktopApi('GET', 'app/version?current=1.1.0')->assertOk()
        ->assertJsonPath('latest.version', '1.2.0')
        ->assertJsonPath('latest.mandatory', false)
        ->assertJsonPath('latest.sha256', $latest->sha256)
        ->assertJsonPath('latest.size', 10)
        ->assertJsonPath('latest.url', route('api.v1.app.download', '1.2.0'))
        ->assertJsonPath('min_version', '1.1.0')
        ->assertJsonPath('update_available', true);
    expect($response->json('server_time'))->not->toBeNull();

    desktopApi('GET', 'app/version?current=1.2.0')->assertJsonPath('update_available', false);
    desktopApi('GET', 'app/version', [], null, null, '1.2.0')->assertJsonPath('update_available', false);
    desktopApi('GET', 'app/version?current=abc')->assertStatus(422);
});

test('release download supports Range and hides inactive releases', function () {
    Storage::fake('local');
    Storage::disk('local')->put(AppRelease::DIRECTORY.'/mynine-setup-1.2.0.exe', 'abcdefghij');
    Storage::disk('local')->put(AppRelease::DIRECTORY.'/mynine-setup-1.3.0.exe', 'zzz');
    makeRelease('1.2.0');
    makeRelease('1.3.0', ['is_active' => false]);

    $full = $this->get('/api/v1/app/releases/1.2.0/download');
    $full->assertOk()->assertHeader('Accept-Ranges', 'bytes');
    expect($full->headers->get('Content-Type'))->toBe('application/octet-stream')
        ->and(binaryContent($full))->toBe('abcdefghij');

    $partial = $this->get('/api/v1/app/releases/1.2.0/download', ['Range' => 'bytes=4-']);
    $partial->assertStatus(206)->assertHeader('Content-Range', 'bytes 4-9/10');
    expect(binaryContent($partial))->toBe('efghij');

    $this->getJson('/api/v1/app/releases/1.3.0/download')->assertNotFound()->assertJsonPath('code', 'not_found');
    $this->getJson('/api/v1/app/releases/9.9.9/download')->assertNotFound();
});

test('exit password is verified online and published in the offline PBKDF2 format', function () {
    $token = registerDesktopDevice();

    $this->artisan('desktop:exit-password', ['password' => 'Center#2026'])->assertSuccessful();
    $this->artisan('desktop:exit-password', ['password' => '123'])->assertFailed();

    desktopApi('POST', 'device/unlock', ['password' => 'wrong-pass'], $token)->assertStatus(422)->assertJsonPath('ok', false);
    desktopApi('POST', 'device/unlock', ['password' => 'Center#2026'], $token)->assertOk()->assertJsonPath('ok', true);

    $config = desktopApi('GET', 'device/config', [], $token)->assertOk()
        ->assertJsonPath('heartbeat_seconds', 20)
        ->assertJsonPath('violation_batch_seconds', 10);
    expect($config->json('banned_processes'))->toContain('anydesk.exe');

    [$algo, $iterations, $salt, $hash] = explode('$', $config->json('exit_password_offline'));
    expect($algo)->toBe('pbkdf2_sha256')
        ->and((int) $iterations)->toBe(120000)
        ->and(base64_decode($hash))->toBe(hash_pbkdf2('sha256', 'Center#2026', base64_decode($salt), 120000, 32, true));

    expect(Setting::get(Setting::DESKTOP_EXIT_PASSWORD))->not->toBe('Center#2026');
});

test('device unlock is rate limited', function () {
    $token = registerDesktopDevice();
    Setting::setExitPassword('Center#2026');

    for ($i = 0; $i < 5; $i++) {
        desktopApi('POST', 'device/unlock', ['password' => 'guess-'.$i], $token)->assertStatus(422);
    }

    desktopApi('POST', 'device/unlock', ['password' => 'Center#2026'], $token)->assertStatus(429)->assertJsonPath('code', 'too_many_requests');
});

test('an unapproved PC cannot log candidates in or read the offline password hash', function () {
    $admin = makeUser('Admin');
    makeDesktopExam($admin);
    $code = 'MOCK-100001';
    $token = registerDesktopDevice('MACHINE-NEW', 'PC-NEW', approve: false);

    desktopApi('POST', 'exam/login', ['code' => $code], $token)
        ->assertForbidden()->assertJsonPath('code', 'device_not_approved');
    desktopApi('GET', 'device/config', [], $token)
        ->assertForbidden()->assertJsonPath('code', 'device_not_approved');
    desktopApi('POST', 'device/heartbeat', ['app_version' => '1.0.0', 'state' => 'idle'], $token)->assertOk();

    Device::where('machine_id', 'MACHINE-NEW')->firstOrFail()->approve();
    desktopApi('POST', 'exam/login', ['code' => $code], $token)->assertOk();
});

test('re-registering an approved PC drops its approval', function () {
    registerDesktopDevice('MACHINE-A', 'PC-A');
    expect(Device::where('machine_id', 'MACHINE-A')->value('is_approved'))->toBeTrue();

    $stolen = registerDesktopDevice('MACHINE-A', 'PC-A', approve: false);

    expect(Device::where('machine_id', 'MACHINE-A')->value('is_approved'))->toBeFalse();
    desktopApi('GET', 'device/config', [], $stolen)->assertForbidden()->assertJsonPath('code', 'device_not_approved');
});
