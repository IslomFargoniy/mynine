<?php

use App\Models\User\User;

test('profile update refuses a phone another account has, in any format', function () {
    $owner = User::factory()->create(['phone' => '+998 90 123-45-67']);
    $user = User::factory()->create();

    foreach (['998901234567', '901234567'] as $phone) {
        $this->actingAs($user)->patch('/settings/profile', ['name' => 'U', 'phone' => $phone])
            ->assertSessionHasErrors(['phone' => __('phone_taken')]);
    }

    // Own number (any format) and a free number are fine.
    $this->actingAs($owner)->patch('/settings/profile', ['name' => 'Owner', 'phone' => '998901234567'])->assertSessionHasNoErrors();
    $this->actingAs($user)->patch('/settings/profile', ['name' => 'U', 'phone' => '998907654321'])->assertSessionHasNoErrors();
    expect($user->fresh()->phone)->toBe('998907654321');
});

test('staff create and edit refuse a phone already used by another account', function () {
    $center = makeCenter();
    User::factory()->create(['phone' => '998901112233']);

    $this->actingAs($center)->post(route('staff.store'), ['name' => 'Desk', 'phone' => '+998 (90) 111-22-33', 'password' => 'secret123'])
        ->assertSessionHasErrors(['phone' => __('phone_taken')]);

    $this->actingAs($center)->post(route('staff.store'), ['name' => 'Desk', 'phone' => '+998 90 999 88 77', 'password' => 'secret123'])
        ->assertSessionHas('success');
    $desk = User::where('name', 'Desk')->sole();

    $this->actingAs($center)->patch(route('staff.update', $desk), ['name' => 'Desk', 'phone' => '901112233'])
        ->assertSessionHasErrors(['phone' => __('phone_taken')]);
    $this->actingAs($center)->patch(route('staff.update', $desk), ['name' => 'Desk', 'phone' => '998909998877'])
        ->assertSessionHas('success');
});

test('phone login finds the account in any format and refuses ambiguous numbers', function () {
    $user = User::factory()->create(['phone' => '998901234567', 'password' => 'secret123']);

    $this->post('/login', ['email_or_phone' => '+998 90 123 45 67', 'password' => 'secret123'])->assertSessionHasNoErrors();
    $this->assertAuthenticatedAs($user);
    auth()->logout();

    // Two legacy accounts with the same number in different formats: no guessing which one.
    User::factory()->create(['phone' => '901234567', 'password' => 'secret123']);
    $this->post('/login', ['email_or_phone' => '998901234567', 'password' => 'secret123'])
        ->assertSessionHasErrors(['email_or_phone' => __('phone_login_ambiguous')]);
    $this->assertGuest();
});
