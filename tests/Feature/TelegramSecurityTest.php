<?php

use Illuminate\Support\Facades\Auth;

function signedInitData(array $tgUser, ?int $authDate = null): string
{
    $fields = ['auth_date' => (string) ($authDate ?? time()), 'query_id' => 'AAE', 'user' => json_encode($tgUser)];
    ksort($fields);
    $check = implode("\n", array_map(fn ($k, $v) => "$k=$v", array_keys($fields), $fields));
    $secret = hash_hmac('sha256', config('services.telegram.mynine_bot_token'), 'WebAppData', true);
    $fields['hash'] = hash_hmac('sha256', $check, $secret);

    return http_build_query($fields);
}

beforeEach(function () {
    config(['services.telegram.mynine_bot_token' => 'test-bot-token']);
});

test('WebApp login uses only the signed Telegram user, never the id sent alongside it', function () {
    $victim = makeUser('Admin');
    $victim->forceFill(['telegram_id' => 555000111])->save();

    $this->postJson('/webapp-login', [
        'initData' => signedInitData(['id' => 777000222, 'first_name' => 'Attacker']),
        'id' => 555000111,
        'first_name' => 'x',
    ])->assertOk();

    expect(Auth::id())->not->toBe($victim->id)
        ->and((string) Auth::user()->telegram_id)->toBe('777000222')
        ->and($victim->fresh()->name)->not->toBe('x');
});

test('WebApp login refuses missing, forged or stale initData', function () {
    $this->postJson('/webapp-login', ['id' => 1])->assertForbidden();
    $this->postJson('/webapp-login', ['initData' => 'user=%7B%22id%22%3A1%7D&auth_date='.time().'&hash=abc'])->assertForbidden();
    $this->postJson('/webapp-login', ['initData' => signedInitData(['id' => 5], time() - 7200)])->assertForbidden();
    expect(Auth::check())->toBeFalse();
});

test('the owner of the signed Telegram account signs in to their own account', function () {
    $user = makeUser('Student');
    $user->forceFill(['telegram_id' => 123456789])->save();

    $this->postJson('/webapp-login', ['initData' => signedInitData(['id' => 123456789, 'first_name' => 'Ali'])])->assertOk();
    expect(Auth::id())->toBe($user->id);
});

test('bot webhooks require the configured secret header and POST', function () {
    config(['services.telegram.webhook_secret' => 'wh-secret']);
    $update = ['update_id' => 1, 'message' => ['chat' => ['id' => 42], 'text' => '/start']];

    $this->postJson('/bot/MynineUzBot/webhook', $update)->assertForbidden();
    $this->postJson('/bot/webhook', $update)->assertForbidden();
    $this->getJson('/bot/MynineUzBot/webhook')->assertStatus(405);
});
