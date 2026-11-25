<?php

use App\Models\User\User;
use App\Services\Student\AppLoginCodes;
use App\Services\Telegram\MynineUzBotService;
use Telegram\Bot\Api;
use Telegram\Bot\Objects\Message;

function appCodeBot(array &$sent): MynineUzBotService
{
    config(['services.telegram.mynine_bot_token' => 'test-bot-token']);
    $bot = new MynineUzBotService;
    $api = Mockery::mock(Api::class);
    $api->shouldReceive('sendMessage')->andReturnUsing(function ($p) use (&$sent) {
        $sent[] = ['message', $p];

        return new Message([]);
    });
    (new ReflectionProperty($bot, 'telegram'))->setValue($bot, $api);

    return $bot;
}

/** "/start app" (the mobile app's deep link) and "/code": a one-time code for signing in to the app. */
test('the app deep link sends a sign-in code that works once', function () {
    $sent = [];
    $update = ['message' => ['chat' => ['id' => 777001, 'type' => 'private'], 'from' => ['id' => 777001, 'first_name' => 'Aziza']]];

    appCodeBot($sent)->handleCommand($update, '/start app', 777001);

    $user = User::where('telegram_id', 777001)->firstOrFail();
    expect($user->hasRole('Student'))->toBeTrue()->and($sent)->toHaveCount(1);
    preg_match('/`(\d{6})`/', $sent[0][1]['text'], $m);
    expect($m[1] ?? null)->not->toBeNull()
        ->and(app(AppLoginCodes::class)->consume($m[1])?->id)->toBe($user->id)
        ->and(app(AppLoginCodes::class)->consume($m[1]))->toBeNull();
});

test('no code in group chats or for staff accounts', function () {
    seedRoles();
    $sent = [];
    appCodeBot($sent)->handleCommand(['message' => ['chat' => ['id' => -5, 'type' => 'group']]], '/code', -5);
    expect($sent)->toBe([]);

    $staff = makeUser('Reception');
    $staff->forceFill(['telegram_id' => 777002])->save();
    appCodeBot($sent)->handleCommand(['message' => ['chat' => ['id' => 777002, 'type' => 'private']]], '/code', 777002);
    expect($sent[0][1]['text'])->toContain('xodim');
});
