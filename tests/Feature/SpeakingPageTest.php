<?php

use Inertia\Testing\AssertableInertia as Assert;

test('a long-running mock that started months ago but is still open appears on the Speaking page', function () {
    $admin = makeUser('Admin');
    $exam = makeDesktopExam($admin);
    $exam['mock']->forceFill(['started_at' => now()->subMonths(3), 'finished_at' => now()->addWeeks(3)])->save();

    $this->actingAs($admin)->get(route('speaking.index'))
        ->assertOk()
        ->assertInertia(fn (Assert $page) => $page
            ->where('mock.id', $exam['mock']->id)
            ->has('candidates', 1)
            ->where('candidates.0.code', $exam['student']->code));
});

test('without a Speaking start time, slots are assigned from now', function () {
    $this->travelTo(now()->setTime(10, 2));
    $admin = makeUser('Admin');
    $exam = makeDesktopExam($admin);
    $exam['mock']->forceFill(['speaking_starts_at' => null, 'speaking_slot_minutes' => 15])->save();

    $this->actingAs($admin)->post(route('speaking.auto-assign', $exam['mock']), ['order' => 'name'])->assertSessionHas('success');

    expect($exam['student']->fresh()->speaking_at->format('H:i'))->toBe('10:05');
});

test('scoring a candidate without a slot records the time of the Speaking test', function () {
    $this->travelTo(now()->setTime(11, 40));
    $admin = makeUser('Admin');
    $exam = makeDesktopExam($admin);
    $student = $exam['student'];
    expect($student->speaking_at)->toBeNull();

    $this->actingAs($admin)->post(route('speaking.score', $student), ['fluency' => 6, 'lexical' => 6, 'grammar' => 6, 'pronunciation' => 6])
        ->assertSessionHas('success');

    expect($student->fresh()->speaking_at->format('H:i'))->toBe('11:40');
});
