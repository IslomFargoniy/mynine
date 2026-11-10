<?php

use App\Models\Device;
use App\Services\Desktop\ReleaseManifest;

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

    // No manifest / no min_version → no check.
    useReleaseManifest(null);
    desktopApi('POST', 'exam/login', ['code' => 'MOCK-100001'], $token, null, '0.0.1')->assertOk();
    useReleaseManifest(releaseManifestData(['min_version' => null]));
    desktopApi('POST', 'exam/login', ['code' => 'MOCK-100001'], $token, null, '0.0.1')->assertOk();

    // The 426 is driven by min_version of version.json (mandatory alone does not block the exam).
    useReleaseManifest(releaseManifestData(['version' => '1.2.0', 'mandatory' => true, 'min_version' => '1.1.0']));

    desktopApi('POST', 'exam/login', ['code' => 'MOCK-100001'], $token, null, '1.0.9')
        ->assertStatus(426)
        ->assertJsonPath('code', 'client_outdated')
        ->assertJsonPath('min_version', '1.1.0');

    // Device endpoints stay reachable so the PC can update itself.
    desktopApi('POST', 'device/heartbeat', ['state' => 'updating'], $token, null, '1.0.9')->assertOk();

    desktopApi('POST', 'exam/login', ['code' => 'MOCK-100001'], $token, null, '1.1.0')->assertOk();

    app('auth')->forgetGuards();
    $this->postJson('/api/v1/exam/login', ['code' => 'MOCK-100001'], ['X-Device-Token' => $token])
        ->assertStatus(426);
});

test('release manifest is parsed and validated', function () {
    $manifest = fn () => app(ReleaseManifest::class);

    useReleaseManifest(null);
    expect($manifest()->get())->toBeNull()
        ->and($manifest()->latestVersion())->toBeNull()
        ->and($manifest()->minVersion())->toBeNull();

    foreach (['', 'not json', '[]', '"1.2.0"', json_encode(['version' => '1.2', 'file' => 'a.exe']),
        json_encode(['version' => '1.2.0']), json_encode(['version' => '1.2.0', 'file' => '../evil.exe']),
        json_encode(['version' => '1.2.0', 'file' => 'setup.zip'])] as $invalid) {
        useReleaseManifest($invalid);
        expect($manifest()->get())->toBeNull();
    }

    useReleaseManifest(releaseManifestData(['sha256' => strtoupper(str_repeat('ab', 32)), 'min_version' => '1.1.0', 'mandatory' => true]));
    expect($manifest()->get())->toBe([
        'version' => '1.2.0',
        'file' => 'mynine-setup-1.2.0.exe',
        'sha256' => str_repeat('ab', 32),
        'size' => 1024,
        'mandatory' => true,
        'min_version' => '1.1.0',
        'notes' => 'Fixes',
        'published_at' => '2026-11-10T00:00:00+05:00',
    ])->and($manifest()->latestVersion())->toBe('1.2.0')
        ->and($manifest()->minVersion())->toBe('1.1.0');

    // Unfilled release fields are normalised instead of rejected (the app treats them as "no update").
    useReleaseManifest(['version' => '1.0.0', 'file' => 'mynine-setup-1.0.0.exe', 'sha256' => '', 'size' => 0, 'min_version' => 'abc', 'mandatory' => 'yes']);
    expect($manifest()->get())->toMatchArray(['sha256' => '', 'size' => 0, 'min_version' => null, 'mandatory' => false, 'notes' => '', 'published_at' => null]);
});

test('release manifest cache follows the file mtime', function () {
    $path = useReleaseManifest(releaseManifestData(['version' => '1.2.0']));
    $manifest = app(ReleaseManifest::class);
    expect($manifest->latestVersion())->toBe('1.2.0');

    file_put_contents($path, json_encode(releaseManifestData(['version' => '1.3.0', 'file' => 'mynine-setup-1.3.0.exe'])));
    touch($path, time() + 10);
    expect($manifest->latestVersion())->toBe('1.3.0');

    file_put_contents($path, '{broken');
    touch($path, time() + 20);
    expect($manifest->get())->toBeNull();

    unlink($path);
    expect($manifest->get())->toBeNull();
});

test('the committed public/desktop/version.json is valid', function () {
    $data = ReleaseManifest::parse(file_get_contents(public_path('desktop/version.json')));
    expect($data)->not->toBeNull()
        ->and($data['file'])->toBe('mynine-setup-'.$data['version'].'.exe');
});

test('the old release API endpoints are gone', function () {
    $this->getJson('/api/v1/app/version')->assertNotFound();
    $this->getJson('/api/v1/app/releases/1.0.0/download')->assertNotFound();
});
