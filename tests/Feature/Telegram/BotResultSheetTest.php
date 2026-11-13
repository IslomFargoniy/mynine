<?php

use App\Models\Attempt;
use App\Services\MockResultService;
use App\Services\Telegram\MynineUzBotService;
use Telegram\Bot\Api;
use Telegram\Bot\Objects\Message;

/** The bot with a fake Telegram API that records what it sends. */
function botWithFakeApi(array &$sent): MynineUzBotService
{
    config(['services.telegram.mynine_bot_token' => 'test-bot-token']);
    $bot = new MynineUzBotService;
    $api = Mockery::mock(Api::class);
    $api->shouldReceive('sendMessage')->andReturnUsing(function ($p) use (&$sent) {
        $sent[] = ['message', $p];

        return new Message([]);
    });
    $api->shouldReceive('sendDocument')->andReturnUsing(function ($p) use (&$sent) {
        $sent[] = ['document', $p];

        return new Message([]);
    });
    (new ReflectionProperty($bot, 'telegram'))->setValue($bot, $api);

    return $bot;
}

function finishedExamStudent()
{
    $exam = makeDesktopExam(defaultCenter(), [], '345678');
    Attempt::create([
        'name' => 'Cand', 'mock_id' => $exam['mock']->id, 'mock_student_id' => $exam['student']->id,
        'test_id' => $exam['testL']->id, 'started_at' => now()->subHour(), 'finished_at' => now(),
    ]);

    return $exam['student']->fresh();
}

function fakeResult(bool $ready): void
{
    $bands = ['listening' => 6.0, 'reading' => 6.5, 'writing' => $ready ? 6.0 : null, 'speaking' => $ready ? 6.0 : null, 'overall' => 6.0];
    test()->mock(MockResultService::class, function ($mock) use ($ready, $bands) {
        $mock->shouldReceive('result')->andReturn([...$bands, 'ready' => $ready, 'missing' => $ready ? [] : ['writing_review'], 'modules' => []]);
        $mock->shouldReceive('attemptBands')->andReturn([
            ...$bands, 'listening_correct' => 30, 'reading_correct' => 30, 'writing_pending' => ! $ready,
        ]);
    });
}

test('a candidate number sends the result sheet PDF once every result is ready', function () {
    fakeResult(true);
    $student = finishedExamStudent();
    $sent = [];

    botWithFakeApi($sent)->sendCandidateResult(1001, $student->code);

    $documents = array_values(array_filter($sent, fn ($s) => $s[0] === 'document'));
    expect($documents)->toHaveCount(1)
        ->and($documents[0][1]['chat_id'])->toBe(1001)
        ->and($documents[0][1]['document']->getContents())->toStartWith('%PDF');
});

test('no PDF while a result is still being checked', function () {
    fakeResult(false);
    $student = finishedExamStudent();
    $sent = [];

    botWithFakeApi($sent)->sendCandidateResult(1001, $student->code);

    expect(array_filter($sent, fn ($s) => $s[0] === 'document'))->toBeEmpty()
        ->and($sent[0][1]['text'])->toContain("barcha modullar natijasi tayyor bo'lganda");
});
