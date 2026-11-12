<?php

use App\Models\Attempt;
use App\Models\Test as ExamTest;
use App\Models\TestType;
use App\Services\AudioUploadService;
use App\Services\ExamService;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

function audioFile(string $name): string
{
    Storage::disk('local')->put('audio/'.$name, 'ID3 fake audio');

    return $name;
}

beforeEach(function () {
    Storage::fake('local');
    Storage::fake('public');

    $this->center = makeCenter();
    $this->exam = makeDesktopExam($this->center);
    $this->exam['testL']->forceFill(['audio_path' => 'media/audio/'.audioFile('module.mp3')])->save();

    // Another Mock Bank Listening test of the same center, not part of the candidate's mock.
    $other = ExamTest::forceCreate([
        'folder_id' => null, 'name' => 'Bank L2', 'active' => 1, 'open' => 0,
        'purpose' => ExamTest::PURPOSE_MOCK, 'bank_status' => ExamTest::BANK_READY, 'owner_id' => $this->center->id,
        'audio_path' => 'media/audio/'.audioFile('bank-other.mp3'),
    ]);
    TestType::create(['test_id' => $other->id, 'type_id' => makeType('Listening')->id]);

    $this->attempt = app(ExamService::class)->findOrCreateMockAttempt($this->exam['student']);
});

test('a candidate hears only the audio of their own mock modules', function () {
    $session = ['mock_student_id' => $this->exam['student']->id];

    $this->withSession($session)->get(route('media.audio', 'module.mp3'))->assertOk();
    $this->withSession($session)->get(route('media.audio', 'bank-other.mp3'))->assertNotFound();
});

test('staff of the owning center hear all of its audio; unknown files are staff-only', function () {
    audioFile('legacy.mp3');
    $reception = makeUser('Reception', $this->center);

    $this->withSession(['mock_student_id' => $this->exam['student']->id])->get(route('media.audio', 'legacy.mp3'))->assertNotFound();
    $this->actingAs(makeUser('Student'))->get(route('media.audio', 'legacy.mp3'))->assertNotFound();

    $this->actingAs($reception)->get(route('media.audio', 'bank-other.mp3'))->assertOk();
    $this->actingAs($reception)->get(route('media.audio', 'legacy.mp3'))->assertOk();
    $this->actingAs(makeCenter())->get(route('media.audio', 'bank-other.mp3'))->assertNotFound();
});

test('a student hears the audio of practice tests they attempt, not every practice test', function () {
    $student = makeUser('Student');
    $mine = makeTestContent(makeSuperAdmin(), 'Listening', ['audio_path' => 'media/audio/'.audioFile('practice-mine.mp3')]);
    makeTestContent(makeSuperAdmin(), 'Listening', ['audio_path' => 'media/audio/'.audioFile('practice-other.mp3')]);

    $this->actingAs($student)->get(route('media.audio', 'practice-mine.mp3'))->assertNotFound();

    Attempt::create(['name' => 'Practice', 'user_id' => $student->id, 'test_id' => $mine['test']->id, 'started_at' => now()]);
    $this->actingAs($student)->get(route('media.audio', 'practice-mine.mp3'))->assertOk();
    $this->actingAs($student)->get(route('media.audio', 'practice-other.mp3'))->assertNotFound();
});

test('uploaded audio gets a random file name', function () {
    $stored = app(AudioUploadService::class)->store(UploadedFile::fake()->create('Cambridge 18 Test 1.mp3', 10, 'audio/mpeg'));

    expect($stored['path'])->toMatch('#^media/audio/[A-Za-z0-9]{32}\.mp3$#')
        ->and($stored['path'])->not->toContain('Cambridge');
});

test('audio requests are throttled per listener', function () {
    $session = ['mock_student_id' => $this->exam['student']->id];
    for ($i = 0; $i < 120; $i++) {
        $this->withSession($session)->get(route('media.audio', 'missing-'.$i.'.mp3'));
    }

    $this->withSession($session)->get(route('media.audio', 'module.mp3'))->assertStatus(429);
});
