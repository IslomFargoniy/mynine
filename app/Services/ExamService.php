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

    /** Desktop v1.1: not applied yet, the client keeps the item and sends it again (e.g. while paused). */
    public const DEFERRED = 'deferred';

    /** Desktop API timestamp format (ISO-8601 with milliseconds and offset). */
    public const API_TIME_FORMAT = 'Y-m-d\\TH:i:s.vP';

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

            if (in_array($section->question_type?->type, self::GAP_TYPES, true)) {
                // Response-only change: the model is never saved after this.
                $section->setAttribute('textarea', $this->maskGaps($section->textarea));
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

    /** Section types whose gaps are written into section.textarea as "{answer}". */
    public const GAP_TYPES = ['complete_section', 'drag_and_drop'];

    /**
     * "{answer}" gaps -> "{}" so the correct answers never reach a candidate. Both exam rooms
     * (web practice-section.tsx, desktop HtmlDocument.sectionBlankPattern) treat "{}" as a gap.
     */
    public function maskGaps(?string $html): string
    {
        return preg_replace('/\{[^{}]*\}/', '{}', (string) $html);
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

    /**
     * Submit a module and queue the AI evaluation of its unscored essays. Only the call that actually
     * submitted the module (atomic UPDATE) queues anything. Returns whether this call submitted it.
     */
    public function finishTypeWithEvaluation(Attempt $attempt, AttemptType $attemptType): bool
    {
        if (! $attemptType->submit()) {
            return false;
        }

        foreach ($attempt->essayAnswersForEvaluation($attemptType->type_id, true) as $answer) {
            EvaluateEssayJob::dispatch($answer->id);
        }

        return true;
    }

    /**
     * Desktop API timestamp: ISO-8601 with milliseconds and offset ("2026-11-12T09:14:03.120+05:00").
     */
    public static function apiTime(mixed $value = 'now'): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        $time = $value instanceof CarbonInterface ? Carbon::instance($value) : Carbon::parse($value);

        return $time->setTimezone(config('app.timezone'))->format(self::API_TIME_FORMAT);
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
            // Whole seconds: the timer the app gets now must equal the one stored (and returned later).
            $start = now()->startOfSecond();
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
     * Ordering (desktop): when both the stored answer and the item carry a client `seq`, the higher seq wins;
     * otherwise the later `changed_at` wins (ms precision); equal values → the later request wins.
     *
     * @param  array<int>|null  $optionIds  null = leave selected options untouched
     * @param  CarbonInterface|null  $changedAt  client time of the change (desktop queue)
     * @param  int|null  $seq  client per-question monotonic counter (desktop v1.1)
     * @return array{status: string, reason?: string, answer?: AttemptAnswer, late?: bool, attempt_type?: AttemptType}
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
        ?int $seq = null,
    ): array {
        if ($attempt->paused_at !== null && ($changedAt === null || $changedAt->gte($attempt->paused_at))) {
            // Desktop items are kept by the client and re-sent after the resume; the web shows "paused".
            return $changedAt === null
                ? $this->rejected('paused')
                : ['status' => self::DEFERRED, 'reason' => 'paused'];
        }

        $question->loadMissing('section.question_type');
        if (! $question->section || (int) $question->section->part_id !== (int) $attemptPart->part_id) {
            return $this->rejected('invalid_question');
        }

        $attemptPart->loadMissing('part.test_type');
        $attemptType = AttemptType::where('attempt_id', $attempt->id)
            ->where('type_id', $attemptPart->part->test_type->type_id)
            ->first();

        $late = false;
        if ($attemptType) {
            $closedReason = null;

            if ($attemptType->is_submitted) {
                $closedReason = 'module_submitted';
            } elseif ($attemptType->finished_at) {
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
                            $attemptType->refresh();
                        }
                        $closedReason = 'module_time_over';
                    }
                }
            }

            if ($closedReason !== null) {
                if (! $this->lateSyncAllowed($attempt, $attemptType, $changedAt)) {
                    return $this->rejected($closedReason);
                }
                $late = true;
            }
        }

        if (is_array($optionIds)) {
            $isMultiple = $question->section->question_type?->type === 'multiple_response';
            $optionIds = array_values(array_unique(array_map('intval', $optionIds)));
            $optionIds = $isMultiple ? $optionIds : array_slice($optionIds, 0, 1);

            $options = Option::withoutEagerLoads()->where('question_id', $question->id)->get(['id', 'question_id', 'is_correct'])->keyBy('id');
            $optionIds = array_values(array_filter($optionIds, fn (int $id) => $options->has($id)));

            // "Choose TWO": never more selections than the key has correct options.
            $maxSelections = $options->filter(fn (Option $option) => (bool) $option->is_correct)->count();
            if ($isMultiple && $maxSelections > 0 && count($optionIds) > $maxSelections) {
                return $this->rejected('too_many_options');
            }
        }

        $result = DB::transaction(function () use ($attemptPart, $question, $text, $optionIds, $changedAt, $clientUuid, $seq, $late) {
            // Serialize concurrent saves of the same part.
            AttemptPart::whereKey($attemptPart->id)->lockForUpdate()->first();

            $answer = AttemptAnswer::where('attempt_part_id', $attemptPart->id)
                ->where('question_id', $question->id)
                ->first();

            if ($answer && $clientUuid !== null && $answer->client_uuid === $clientUuid) {
                return ['status' => self::DUPLICATE, 'answer' => $answer];
            }

            if ($answer && $seq !== null && $answer->client_seq !== null) {
                if ((int) $answer->client_seq > $seq) {
                    return ['status' => self::STALE, 'answer' => $answer];
                }
            } elseif ($answer && $changedAt !== null && $answer->client_changed_at !== null
                && Carbon::parse($answer->client_changed_at)->gt($changedAt)) {
                return ['status' => self::STALE, 'answer' => $answer];
            }

            $answer ??= new AttemptAnswer(['attempt_part_id' => $attemptPart->id, 'question_id' => $question->id]);
            $answer->answer_text = $text;
            if ($clientUuid !== null) {
                $answer->client_uuid = $clientUuid;
            }
            if ($seq !== null) {
                $answer->client_seq = $seq;
            }
            if ($changedAt !== null) {
                $answer->client_changed_at = Carbon::instance($changedAt)->setTimezone(config('app.timezone'))->format('Y-m-d H:i:s.v');
            }
            if ($late) {
                $answer->late_synced = true;
            }
            $answer->save();

            if (is_array($optionIds)) {
                $answer->attempt_answer_options()->delete();

                $correct = Option::withoutEagerLoads()->whereIn('id', $optionIds)->pluck('is_correct', 'id');
                foreach ($optionIds as $optionId) {
                    $answer->attempt_answer_options()->create([
                        'option_id' => $optionId,
                        'is_correct' => ($correct[$optionId] ?? 0) ? 1 : 0,
                    ]);
                }
            }

            return ['status' => self::SAVED, 'answer' => $answer];
        });

        if ($late && $result['status'] === self::SAVED) {
            $result['late'] = true;
            $result['attempt_type'] = $attemptType;
        }

        return $result;
    }

    /**
     * Desktop v1.1 offline late sync: after a module ended, an item is still accepted when it was changed
     * before the end, the PC was offline at the end (no heartbeat after finished_at, see snapshotOfflineAtEnd)
     * and the module ended at most desktop.offline_late_sync_minutes ago.
     */
    public function lateSyncAllowed(Attempt $attempt, AttemptType $attemptType, ?CarbonInterface $changedAt): bool
    {
        if ($changedAt === null || $attemptType->finished_at === null) {
            return false;
        }

        $finishedAt = Carbon::parse($attemptType->finished_at);
        if ($changedAt->gt($finishedAt)) {
            return false;
        }

        if (now()->gt($finishedAt->copy()->addMinutes($this->lateSyncMinutes()))) {
            return false;
        }

        return $this->offlineAtEnd($attempt, $attemptType);
    }

    public function lateSyncMinutes(): int
    {
        return (int) config('desktop.offline_late_sync_minutes', 120);
    }

    /**
     * Whether the PC was offline when the module ended: its last exam heartbeat is older than finished_at.
     * Stored on the module (attempt_types.offline_at_end) once the grace is over, so a heartbeat after the
     * reconnect does not change the answer.
     */
    public function offlineAtEnd(Attempt $attempt, AttemptType $attemptType): bool
    {
        if ($attemptType->offline_at_end !== null) {
            return (bool) $attemptType->offline_at_end;
        }

        $finishedAt = Carbon::parse($attemptType->finished_at);
        $lastHeartbeat = $attempt->last_heartbeat_at;
        $offline = $lastHeartbeat === null || Carbon::parse($lastHeartbeat)->lt($finishedAt);

        if (now()->gt($finishedAt->copy()->addSeconds((int) config('desktop.answer_grace_seconds', 30)))) {
            $attemptType->forceFill(['offline_at_end' => $offline])->saveQuietly();
        }

        return $offline;
    }

    /**
     * Record offline_at_end for every module that ended (beyond the grace) before this request.
     * Must run before a heartbeat moves attempts.last_heartbeat_at forward.
     */
    public function snapshotOfflineAtEnd(Attempt $attempt): void
    {
        if ($attempt->paused_at !== null) {
            return;
        }

        AttemptType::withoutEagerLoads()
            ->where('attempt_id', $attempt->id)
            ->whereNull('offline_at_end')
            ->whereNotNull('finished_at')
            ->where('finished_at', '<', now()->subSeconds((int) config('desktop.answer_grace_seconds', 30)))
            ->get()
            ->each(fn (AttemptType $type) => $this->offlineAtEnd($attempt, $type));
    }

    /**
     * Whether answers may still arrive for a finished attempt (some module ended while the PC was offline,
     * within the late-sync cap).
     */
    public function acceptsLateAnswers(Attempt $attempt): bool
    {
        return AttemptType::withoutEagerLoads()
            ->where('attempt_id', $attempt->id)
            ->where('offline_at_end', true)
            ->where('finished_at', '>=', now()->subMinutes($this->lateSyncMinutes()))
            ->exists();
    }

    /**
     * After late-synced answers: re-score the touched modules and (re-)evaluate late essays. A Writing module
     * an Admin already confirmed loses the confirmation (it returns to the Writing review queue): the
     * confirmed band was given without the late essay text.
     *
     * @param  array<int, array{answer: AttemptAnswer, attempt_type: AttemptType}>  $lateResults
     */
    public function afterLateSync(array $lateResults): void
    {
        $types = [];
        foreach ($lateResults as $result) {
            $type = $result['attempt_type']->fresh();
            if (! $type) {
                continue;
            }
            $types[$type->id] = $type;

            $answer = $result['answer'];
            $isEssay = Question::withoutEagerLoads()->whereKey($answer->question_id)
                ->whereHas('section.question_type', fn ($q) => $q->where('type', 'essay'))->exists();

            if ($isEssay && $type->reviewed_at !== null) {
                $type->forceFill(['reviewed_at' => null, 'reviewed_by' => null])->save();
            }

            if ($isEssay && mb_strlen((string) $answer->answer_text) > 10) {
                // An unscored essay may still have a queued job; it reads the new text. A scored one is re-run.
                EvaluateEssayJob::dispatch($answer->id, $answer->fresh()?->score !== null);
            }
        }

        foreach ($types as $type) {
            if ($type->is_submitted) {
                $type->recalculateIsCorrectCount();
            }
        }
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
     * Desktop: the Listening recording was not heard for $lagSeconds in total (the app was closed / restarting);
     * the app resumes it where it stopped, so the module (and its parts) end that much later. $lagSeconds is the
     * total, so a repeated report never extends twice. Capped at the module length. Returns the module.
     */
    public function extendForAudioLag(AttemptType $attemptType, int $lagSeconds, int $maxSeconds): AttemptType
    {
        return DB::transaction(function () use ($attemptType, $lagSeconds, $maxSeconds) {
            $type = AttemptType::whereKey($attemptType->id)->lockForUpdate()->firstOrFail();
            $lag = min(max(0, $lagSeconds), max(0, $maxSeconds));
            $delta = $lag - (int) $type->audio_lag_seconds;
            if ($type->is_submitted || $type->finished_at === null || $delta <= 0) {
                return $type;
            }

            $oldEnd = Carbon::parse($type->finished_at);
            $type->forceFill(['finished_at' => $oldEnd->copy()->addSeconds($delta), 'audio_lag_seconds' => $lag])->save();

            AttemptPart::where('attempt_id', $type->attempt_id)
                ->whereNotNull('finished_at')
                ->whereHas('part.test_type', fn ($q) => $q->where('type_id', $type->type_id))
                ->get()
                ->each(fn (AttemptPart $part) => $part->forceFill([
                    'finished_at' => Carbon::parse($part->finished_at)->addSeconds($delta),
                ])->save());

            return $type;
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
     * Finish the whole attempt: Attempt::finish submits every open module, scores everything and queues
     * the essays that were not queued yet (also clears a pause).
     */
    public function finishAttempt(Attempt $attempt): void
    {
        if ($attempt->finished_at !== null) {
            return;
        }

        $attempt->unsetRelation('attempt_types')->unsetRelation('attempt_parts');
        $attempt->finish();
    }

    public function forceSubmit(Attempt $attempt): void
    {
        $this->finishAttempt($attempt);
    }

    /**
     * Manual (examiner) band for a module, e.g. Speaking. Creates the attempt_type when missing.
     */
    public function storeManualScore(Attempt $attempt, int $typeId, float $score, ?string $comment): AttemptType
    {
        $attemptType = AttemptType::updateOrCreate(
            ['attempt_id' => $attempt->id, 'type_id' => $typeId],
            [
                'score' => $score,
                'comment' => $comment,
                'started_at' => now(),
                'finished_at' => now(),
                'is_submitted' => true,
            ]
        );

        $attemptType->recalculateIsCorrectCount();

        return $attemptType;
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
