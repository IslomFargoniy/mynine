<?php

use App\Models\User\User;
use Illuminate\Testing\TestResponse;
use Laravel\Socialite\Contracts\Factory as SocialiteFactory;
use Laravel\Socialite\Contracts\User as SocialiteUser;
use Laravel\Socialite\Facades\Socialite;

/**
 * Browser Google sign-in for the apps: /app/google → Google → /app/google/callback → mynine://auth?token=…,
 * then POST /api/v1/student/auth/google/exchange swaps the one-time token for an API token.
 */
function fakeAppGoogle(string $id, string $email): void
{
    $googleUser = Mockery::mock(SocialiteUser::class);
    $googleUser->shouldReceive('getId')->andReturn($id);
    $googleUser->shouldReceive('getEmail')->andReturn($email);
    $googleUser->shouldReceive('getName')->andReturn('Google Student');
    $googleUser->shouldReceive('getAvatar')->andReturn(null);

    $provider = Mockery::mock();
    $provider->shouldReceive('redirectUrl')->andReturnSelf();
    $provider->shouldReceive('with')->andReturnSelf();
    $provider->shouldReceive('redirect')->andReturn(redirect('https://accounts.google.com/o/oauth2/auth'));
    $provider->shouldReceive('user')->andReturn($googleUser);
    $factory = Mockery::mock(SocialiteFactory::class);
    $factory->shouldReceive('driver')->with('google')->andReturn($provider);
    Socialite::swap($factory);
}

function appReturnUrl(TestResponse $response): array
{
    $location = (string) $response->headers->get('Location');
    expect($location)->toStartWith('mynine://auth?');
    parse_str(parse_url($location, PHP_URL_QUERY) ?? '', $query);

    return $query;
}

test('a student signs in with Google in the browser and the app swaps the token once', function () {
    seedRoles();
    $student = makeUser('Student');
    fakeAppGoogle('g-123', $student->email);

    $this->get('/app/google?state=abcdefghijklmnop1234')->assertRedirect();
    $query = appReturnUrl($this->get('/app/google/callback?code=x')->assertRedirect());

    expect($query['state'])->toBe('abcdefghijklmnop1234')->and($query['token'])->toHaveLength(48);

    $this->postJson('/api/v1/student/auth/google/exchange', ['token' => $query['token']])
        ->assertOk()
        ->assertJsonPath('user.id', $student->id)
        ->assertJsonStructure(['token']);
    expect($student->fresh()->google_id)->toBe('g-123');

    $this->postJson('/api/v1/student/auth/google/exchange', ['token' => $query['token']])
        ->assertStatus(422)->assertJsonPath('code', 'invalid_token');
});

test('a new Google account becomes a student', function () {
    seedRoles();
    fakeAppGoogle('g-new', 'new.person@example.com');

    $this->get('/app/google?state=abcdefghijklmnop1234');
    $query = appReturnUrl($this->get('/app/google/callback?code=x'));

    $this->postJson('/api/v1/student/auth/google/exchange', ['token' => $query['token']])->assertOk();
    expect(User::where('email', 'new.person@example.com')->first()->hasRole('Student'))->toBeTrue();
});

test('the browser sign-in needs the app state, and a staff account cannot use the app', function () {
    seedRoles();
    $this->get('/app/google')->assertStatus(400);
    $this->get('/app/google?state=bad')->assertStatus(400);

    $admin = makeUser('Admin');
    fakeAppGoogle('g-admin', $admin->email);
    $this->get('/app/google?state=abcdefghijklmnop1234');
    $query = appReturnUrl($this->get('/app/google/callback?code=x'));

    $this->postJson('/api/v1/student/auth/google/exchange', ['token' => $query['token']])
        ->assertStatus(403)->assertJsonPath('code', 'staff_account');
});
