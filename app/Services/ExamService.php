<?php

namespace App\Services;

use App\Jobs\EvaluateEssayJob;
use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\AttemptPart;
use App\Models\AttemptType;
use App\Models\MockStudent;
use App\Models\Option;
use App\Models\Part;
use App\Models\Question;
use App\Models\TestType;
use Carbon\Carbon;
use Carbon\CarbonInterface;
use Illuminate\Support\Facades\DB;

/**
 * Exam rules shared by the web exam room and the desktop API, so both behave identically.
 */
class ExamService
{
    public const SAVED = 'saved';

    public const DUPLICATE = 'duplicate';

    public const STALE = 'stale';

    public const REJECTED = 'rejected';

    /**
     * Strip everything a candidate could use to cheat from a part payload and
     * build a neutral, pre-sorted option list for drag-and-drop sections.
     */
    public function hideAnswerKeys(Part $part): void
    {
        foreach ($part->sections as $section) {
            $section->options->each->makeHidden('is_correct');

            if ($section->question_type?->type === 'drag_and_drop') {
                $section->setAttribute('drag_options', $this->dragOptions($section));
            }

            foreach ($section->questions as $question) {
                $question->makeHidden('answer_text');
                $question->options->each->makeHidden('is_correct');

                if ($question->attempt_answer) {
                    $question->attempt_answer->makeHidden(['is_correct', 'score', 'review_note', 'review_note_ai', 'client_uuid', 'client_changed_at']);
                    $question->attempt_answer->attempt_answer_options->each(function ($answerOption) {
                        $answerOption->makeHidden('is_correct');
                        $answerOption->option?->makeHidden('is_correct');
                    });
                }
            }
        }
    }

    /**
     * Word bank of a drag-and-drop section: correct words mixed with distractors, sorted alphabetically.
     *
     * @return array<int, array{id: string, label: string}>
     */
    public function dragOptions($section): array
    {
        return $section->questions->pluck('answer_text')
            ->merge($section->options->pluck('textarea'))
            ->map(fn ($label) => trim((string) $label))
            ->filter()
            ->unique(fn ($label) => mb_strtolower($label))
            ->sort(fn ($a, $b) => strcasecmp($a, $b))
            ->values()
            ->map(fn ($label, $i) => ['id' => 'd'.($i + 1), 'label' => $label])
            ->all();
    }

    public function mockWindowError(Attempt $attempt): ?string
    {
        $mock = $attempt->mock;
        if (! $mock) {
            return null;
        }

        return match ($mock->status) {
            'inactive' => 'Ushbu Mock test hozirda faol emas!',
            'scheduled' => 'Ushbu Mock test hali boshlanmagan! Boshlanish vaqti: '.Carbon::parse($mock->started_at)->format('d.m.Y H:i'),
            'expired' => 'Ushbu Mock test vaqti tugagan! Yakunlangan vaqti: '.Carbon::parse($mock->finished_at)->format('d.m.Y H:i'),
            default => null,
        };
    }

    /**
     * Close every module whose timer ran out (plus $graceSeconds) and queue AI evaluation for its essays.
     * Timers are frozen while the attempt is paused.
     */
    public function autoFinishExpiredTypes(Attempt $attempt, int $graceSeconds = 0): void
    {
        if ($attempt->paused_at !== null) {
            return;
        }

        $expired = AttemptType::where('attempt_id', $attempt->id)
            ->where('is_submitted', false)
            ->whereNotNull('finished_at')
            ->where('finished_at', '<', now()->subSeconds($graceSeconds))
            ->get();

        foreach ($expired as $attemptType) {
            $this->finishTypeWithEvaluation($attempt, $attemptType);
        }
    }

    public function finishTypeWithEvaluation(Attempt $attempt, AttemptType $attemptType): void
    {
        $attemptType->finish();

        foreach ($attempt->essayAnswersForEvaluation($attemptType->type_id) as $answer) {
            EvaluateEssayJob::dispatch($answer->id);
        }
    }

    /**
     * Module length: Listening follows the recording (+5 s), everything else the type's minutes.
     */
    public function moduleDurationSeconds(TestType $testType): int
    {
        $test = $testType->test;
        if ($testType->type?->name === 'Listening' && $test?->playtime_seconds) {
            return (int) $test->playtime_seconds + 5;
        }

        return (int) $testType->type?->minute * 60;
    }

    /**
     * Web exam room: open one part, creating its timer and the module timer on first visit.
     */
    public function startPart(Attempt $attempt, Part $part): AttemptPart
    {
        $part->loadMissing(['test_type.test', 'test_type.type']);
        $type = $part->test_type->type;
        $typeFinishedAt = now()->addSeconds($this->moduleDurationSeconds($part->test_type));

        $attemptPart = AttemptPart::firstOrCreate(
            ['attempt_id' => $attempt->id, 'part_id' => $part->id],
            ['started_at' => now(), 'finished_at' => now()->addMinutes((int) ($part->minute ?: $type->minute))]
        );

        AttemptType::firstOrCreate(
            ['attempt_id' => $attempt->id, 'type_id' => $part->test_type->type_id],
            ['started_at' => now(), 'finished_at' => $typeFinishedAt]
        );

        return $attemptPart;
    }

    /**
     * Desktop: start a whole module (timer + every part). Idempotent.
     */
    public function startModule(Attempt $attempt, TestType $testType): AttemptType
    {
        return DB::transaction(function () use ($attempt, $testType) {
            $start = now();
            $attemptType = AttemptType::createOrFirst(
                ['attempt_id' => $attempt->id, 'type_id' => $testType->type_id],
                ['started_at' => $start, 'finished_at' => $start->copy()->addSeconds($this->moduleDurationSeconds($testType))]
            );

            $partIds = Part::withoutEagerLoads()->where('test_type_id', $testType->id)->pluck('id');
            $existing = AttemptPart::where('attempt_id', $attempt->id)->whereIn('part_id', $partIds)->pluck('part_id')->all();

            foreach ($partIds->diff($existing) as $partId) {
                AttemptPart::create([
                    'attempt_id' => $attempt->id,
                    'part_id' => $partId,
                    'started_at' => $attemptType->started_at,
                    'finished_at' => $attemptType->finished_at,
                ]);
            }

            return $attemptType;
        });
    }

    /**
     * Save one answer. Shared by web (one answer per request) and desktop (idempotent batches).
     *
     * @param  array<int>|null  $optionIds  null = leave selected options untouched
     * @param  CarbonInterface|null  $changedAt  client time of the change (desktop queue)
     * @return array{status: string, reason?: string, answer?: AttemptAnswer}
     */
    public function saveAnswer(
        Attempt $attempt,
        AttemptPart $attemptPart,
        Question $question,
        ?string $text,
        ?array $optionIds,
        ?CarbonInterface $changedAt = null,
        ?string $clientUuid = null,
        int $graceSeconds = 0,
    ): array {
        if ($attempt->paused_at !== null && ($changedAt === null || $changedAt->gte($attempt->paused_at))) {
            return $this->rejected('paused');
        }

        $question->loadMissing('section.question_type');
        if (! $question->section || (int) $question->section->part_id !== (int) $attemptPart->part_id) {
            return $this->rejected('invalid_question');
        }

        $attemptPart->loadMissing('part.test_type');
        $attemptType = AttemptType::where('attempt_id', $attempt->id)
            ->where('type_id', $attemptPart->part->test_type->type_id)
            ->first();

        if ($attemptType) {
            if ($attemptType->is_submitted) {
                return $this->rejected('module_submitted');
            }

            if ($attemptType->finished_at) {
                // While paused the clock stands still at paused_at.
                $now = $attempt->paused_at ? Carbon::parse($attempt->paused_at) : now();
                $finishedAt = Carbon::parse($attemptType->finished_at);
                $graceEnd = $finishedAt->copy()->addSeconds($graceSeconds);

                if ($now->gt($finishedAt)) {
                    $inGrace = $graceSeconds > 0 && $changedAt !== null
                        && $changedAt->lte($finishedAt) && $now->lte($graceEnd);

                    if (! $inGrace) {
                        if ($attempt->paused_at === null && $now->gt($graceEnd)) {
                            $this->finishTypeWithEvaluation($attempt, $attemptType);
                        }

                        return $this->rejected('module_time_over');
                    }
                }
            }
        }

        return DB::transaction(function () use ($attemptPart, $question, $text, $optionIds, $changedAt, $clientUuid) {
            // Serialize concurrent saves of the same part.
            AttemptPart::whereKey($attemptPart->id)->lockForUpdate()->first();

            $answer = AttemptAnswer::where('attempt_part_id', $attemptPart->id)
                ->where('question_id', $question->id)
                ->first();

            if ($answer && $clientUuid !== null && $answer->client_uuid === $clientUuid) {
                return ['status' => self::DUPLICATE, 'answer' => $answer];
            }

            if ($answer && $changedAt !== null && $answer->client_changed_at !== null
                && Carbon::parse($answer->client_changed_at)->gt($changedAt)) {
                return ['status' => self::STALE, 'answer' => $answer];
            }

            $answer ??= new AttemptAnswer(['attempt_part_id' => $attemptPart->id, 'question_id' => $question->id]);
            $answer->answer_text = $text;
            if ($clientUuid !== null) {
                $answer->client_uuid = $clientUuid;
            }
            if ($changedAt !== null) {
                $answer->client_changed_at = Carbon::instance($changedAt)->setTimezone(config('app.timezone'))->format('Y-m-d H:i:s.v');
            }
            $answer->save();

            if (is_array($optionIds)) {
                $answer->attempt_answer_options()->delete();

                $isMultiple = $question->section->question_type?->type === 'multiple_response';
                $optionIds = array_values(array_unique(array_map('intval', $optionIds)));
                $optionIds = $isMultiple ? $optionIds : array_slice($optionIds, 0, 1);

                $options = Option::whereIn('id', $optionIds)->where('question_id', $question->id)->get()->keyBy('id');
                foreach ($optionIds as $optionId) {
                    $option = $options->get($optionId);
                    if (! $option) {
                        continue;
                    }
                    $answer->attempt_answer_options()->create([
                        'option_id' => $option->id,
                        'is_correct' => $option->is_correct ? 1 : 0,
                    ]);
                }
            }

            return ['status' => self::SAVED, 'answer' => $answer];
        });
    }

    /**
     * Freeze the attempt: answers are rejected and module timers stop.
     */
    public function pause(Attempt $attempt): void
    {
        if ($attempt->finished_at !== null || $attempt->paused_at !== null) {
            return;
        }

        $attempt->forceFill(['paused_at' => now()])->save();
    }

    /**
     * Unfreeze: push every running timer forward by the pause duration.
     */
    public function resume(Attempt $attempt): void
    {
        if ($attempt->paused_at === null) {
            return;
        }

        DB::transaction(function () use ($attempt) {
            $pausedAt = Carbon::parse($attempt->paused_at);
            $seconds = (int) floor($pausedAt->diffInSeconds(now(), true));

            if ($seconds > 0) {
                AttemptType::where('attempt_id', $attempt->id)
                    ->where('is_submitted', false)
                    ->whereNotNull('finished_at')
                    ->get()
                    ->each(fn (AttemptType $type) => $type->forceFill([
                        'finished_at' => Carbon::parse($type->finished_at)->addSeconds($seconds),
                    ])->save());

                AttemptPart::where('attempt_id', $attempt->id)
                    ->whereNotNull('finished_at')
                    ->where('finished_at', '>', $pausedAt)
                    ->get()
                    ->each(fn (AttemptPart $part) => $part->forceFill([
                        'finished_at' => Carbon::parse($part->finished_at)->addSeconds($seconds),
                    ])->save());
            }

            $attempt->forceFill(['paused_at' => null])->save();
        });
    }

    /**
     * Give the running module(s) extra minutes. Returns how many modules were extended.
     */
    public function addTime(Attempt $attempt, int $minutes): int
    {
        if ($attempt->finished_at !== null) {
            return 0;
        }

        return DB::transaction(function () use ($attempt, $minutes) {
            $running = AttemptType::where('attempt_id', $attempt->id)
                ->where('is_submitted', false)
                ->whereNotNull('finished_at')
                ->get();

            foreach ($running as $type) {
                $type->forceFill(['finished_at' => Carbon::parse($type->finished_at)->addMinutes($minutes)])->save();
            }

            if ($running->isNotEmpty()) {
                AttemptPart::where('attempt_id', $attempt->id)
                    ->whereNotNull('finished_at')
                    ->whereHas('part.test_type', fn ($q) => $q->whereIn('type_id', $running->pluck('type_id')))
                    ->get()
                    ->each(fn (AttemptPart $part) => $part->forceFill([
                        'finished_at' => Carbon::parse($part->finished_at)->addMinutes($minutes),
                    ])->save());
            }

            return $running->count();
        });
    }

    /**
     * Finish the whole attempt: close every started module, then score and queue essays (Attempt::finish).
     */
    public function finishAttempt(Attempt $attempt): void
    {
        if ($attempt->finished_at !== null) {
            return;
        }

        DB::transaction(function () use ($attempt) {
            AttemptType::where('attempt_id', $attempt->id)
                ->where('is_submitted', false)
                ->get()
                ->each(fn (AttemptType $type) => $type->finish());

            if ($attempt->paused_at !== null) {
                $attempt->paused_at = null;
            }

            $attempt->unsetRelation('attempt_types')->unsetRelation('attempt_parts');
            $attempt->finish();
        });
    }

    public function forceSubmit(Attempt $attempt): void
    {
        $this->finishAttempt($attempt);
    }

    /**
     * Mark a remote unlock as delivered; true only once per request and only while fresh.
     */
    public function consumeUnlock(?int $attemptId): bool
    {
        if (! $attemptId) {
            return false;
        }

        return Attempt::whereKey($attemptId)
            ->whereNotNull('unlock_requested_at')
            ->where('unlock_requested_at', '>=', now()->subMinutes((int) config('desktop.unlock_ttl_minutes', 15)))
            ->update(['unlock_requested_at' => null]) > 0;
    }

    /**
     * Candidate-code attempt: modules come from mock_modules (attempts.test_id = first module's test)
     * or, for legacy mocks, from mocks.test_id.
     */
    public function findOrCreateMockAttempt(MockStudent $student, array $extra = []): ?Attempt
    {
        $attempt = Attempt::where('mock_student_id', $student->id)->first();
        if ($attempt) {
            return $attempt;
        }

        $mock = $student->mock;
        $testId = $mock->test_id;

        $firstModule = $mock->modules()
            ->with('testType.type')
            ->get()
            ->sortBy(fn ($module) => $this->moduleSortKey($module->testType?->type?->name))
            ->first();
        if ($firstModule?->testType) {
            $testId = $firstModule->testType->test_id;
        }

        if (! $testId) {
            return null;
        }

        return Attempt::create(array_merge([
            'name' => $student->name,
            'mock_id' => $student->mock_id,
            'mock_student_id' => $student->id,
            'user_id' => null,
            'test_id' => $testId,
            'started_at' => now(),
        ], $extra));
    }

    private function moduleSortKey(?string $typeName): int
    {
        $order = array_flip([...Attempt::DESKTOP_MODULE_ORDER, 'Speaking']);

        return $order[$typeName] ?? 99;
    }

    /**
     * @return array{status: string, reason: string}
     */
    private function rejected(string $reason): array
    {
        return ['status' => self::REJECTED, 'reason' => $reason];
    }
}
