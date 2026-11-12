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
