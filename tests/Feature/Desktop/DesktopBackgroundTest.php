<?php

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

beforeEach(function () {
    Storage::fake('local');
    $this->admin = makeUser('Admin');
    $this->device = registerDesktopDevice();
});

test('admin uploads a background; PCs get its url in the config and can download it', function () {
    desktopApi('GET', 'device/config', [], $this->device)->assertOk()->assertJsonPath('background_url', null);

    $image = UploadedFile::fake()->image('hall.jpg', 1920, 1080);
    $this->actingAs($this->admin)->post(route('desktop.settings.background.update'), ['image' => $image])
        ->assertSessionHasNoErrors()->assertSessionHas('success');

    $config = desktopApi('GET', 'device/config', [], $this->device)->assertOk();
    expect($config->json('background_url'))->toBe(route('api.v1.device.background'))
        ->and($config->json('background_sha256'))->toHaveLength(64);

    $file = desktopApi('GET', 'device/background', [], $this->device)->assertOk();
    expect(hash('sha256', binaryContent($file)))->toBe($config->json('background_sha256'));

    $this->actingAs($this->admin)->get(route('desktop.settings.background'))->assertOk();
});

test('removing the background clears it for the PCs; non-admins cannot change it', function () {
    $this->actingAs($this->admin)->post(route('desktop.settings.background.update'), ['image' => UploadedFile::fake()->image('a.png')]);
    $this->actingAs($this->admin)->delete(route('desktop.settings.background.destroy'))->assertSessionHas('success');

    desktopApi('GET', 'device/config', [], $this->device)->assertJsonPath('background_url', null);
    desktopApi('GET', 'device/background', [], $this->device)->assertNotFound();

    $this->actingAs(makeUser('Reception'))->post(route('desktop.settings.background.update'), ['image' => UploadedFile::fake()->image('b.png')])->assertForbidden();
    $this->actingAs($this->admin)->post(route('desktop.settings.background.update'), ['image' => UploadedFile::fake()->create('x.pdf', 10, 'application/pdf')])
        ->assertSessionHasErrors('image');
});
