<?php

use App\Models\User\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;

uses(RefreshDatabase::class);

test('password can be updated', function () {
    $user = User::factory()->create();

    $response = $this
        ->actingAs($user)
        ->from('/settings/password')
        ->put('/settings/password', [
            'current_password' => 'password',
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ]);

    $response
        ->assertSessionHasNoErrors()
        ->assertRedirect('/settings/password');

    expect(Hash::check('new-password', $user->refresh()->password))->toBeTrue();
});

test('correct password must be provided to update password', function () {
    $user = User::factory()->create();

    $response = $this
        ->actingAs($user)
        ->from('/settings/password')
        ->put('/settings/password', [
            'current_password' => 'wrong-password',
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ]);

    $response
        ->assertSessionHasErrors('current_password')
        ->assertRedirect('/settings/password');
});

test('a Google sign-up (no password) sets one without a current password', function () {
    $user = User::factory()->create(['password' => null, 'google_id' => 'g-1']);
    expect($user->fresh()->hasOwnPassword())->toBeFalse();

    $this->actingAs($user)->get('/settings/password')->assertInertia(fn ($page) => $page->where('hasPassword', false));

    $this->actingAs($user)->from('/settings/password')->put('/settings/password', [
        'password' => 'new-password',
        'password_confirmation' => 'new-password',
    ])->assertSessionHasNoErrors();

    $user->refresh();
    expect(Hash::check('new-password', $user->password))->toBeTrue()
        ->and($user->hasOwnPassword())->toBeTrue();

    // From now on the current password is asked for.
    $this->actingAs($user)->from('/settings/password')->put('/settings/password', [
        'password' => 'other-password',
        'password_confirmation' => 'other-password',
    ])->assertSessionHasErrors('current_password');
});

test('a center handed over by Replace admin: the new Admin sets a password without the old random one', function () {
    $owner = makeSuperAdmin();
    $center = makeCenter('ALPHA');
    expect($center->fresh()->hasOwnPassword())->toBeTrue();

    $this->actingAs($owner)->post(route('centers.replace-admin', $center), ['email' => 'new.admin@example.com'])
        ->assertSessionHasNoErrors();
    expect($center->fresh()->hasOwnPassword())->toBeFalse();

    $this->actingAs($center->fresh())->from('/settings/password')->put('/settings/password', [
        'password' => 'new-password',
        'password_confirmation' => 'new-password',
    ])->assertSessionHasNoErrors();
    expect(Hash::check('new-password', $center->fresh()->password))->toBeTrue();
});
