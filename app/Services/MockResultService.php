<?php

namespace App\Services;

use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\AttemptType;
use App\Models\MockStudent;
use App\Models\Question;

/**
 * Module bands, result readiness and the reception status of a mock candidate.
 *
 * Result is ready when Listening and Reading are submitted, Writing is confirmed by an Admin
 * (attempt_types.reviewed_at) and Speaking has a band. Modules the mock does not contain are ignored.
 */
class MockResultService
{
    public const STATUSES = [
        'not_arrived',
        'checked_in',
        'in_exam',
        'written_done',
        'speaking_waiting',
        'result_ready',
        'delivered',
    ];

    /** @var array<int, array<string>> mock id => module type names */
    private array $moduleTypeCache = [];

    /**
     * @return array<string>
     */
    public function moduleTypes(MockStudent $student): array
    {
        $mock = $student->mock;
        if (! $mock) {
            return [];
        }

        return $this->moduleTypeCache[$mock->id] ??= collect($mock->moduleTypeNames())
            ->filter(fn ($name) => in_array($name, MockBankService::MODULE_TYPES, true))
            ->sortBy(fn ($name) => array_search($name, MockBankService::MODULE_TYPES, true))
            ->values()
            ->all();
    }

    /**
     * Band of a Writing module: the Admin-confirmed band, else the weighted task bands (see computedWritingBand).
     */
    public function writingBand(AttemptType $type): float
    {
        if ($type->reviewed_at !== null && $type->score !== null) {
            return (float) $type->score;
        }

        return $this->computedWritingBand($type);
    }

    /**
     * Writing band from the task bands (AI or adjusted by the Admin), ignoring a confirmed override.
     * IELTS weighting: Task 2 counts twice as much as Task 1 -> (T1 + 2*T2) / 3, then rounded to a half band.
     * A missing / unscored task counts as 0. Modules with a different number of essays use a plain average.
     */
    public function computedWritingBand(AttemptType $type): float
    {
        $bands = $this->writingTaskBands($type);

        if (count($bands) === 2) {
            return IeltsScoreConverter::roundBand(($bands[0] + 2 * $bands[1]) / 3);
        }

        return IeltsScoreConverter::roundBand(array_sum($bands) / max(1, count($bands)));
    }

    /**
     * Band of every essay task of the module in task order (part, then question order).
     *
     * @return array<int, float>
     */
    public function writingTaskBands(AttemptType $type): array
    {
        $attempt = $type->relationLoaded('attempt') ? $type->attempt : Attempt::find($type->attempt_id);
        if (! $attempt) {
            return [];
        }

        $testTypeIds = $attempt->moduleTestTypes()
            ->where('type_id', $type->type_id)
            ->pluck('id');

        $questions = Question::withoutEagerLoads()
            ->select('questions.id')
            ->join('sections', 'sections.id', '=', 'questions.section_id')
            ->join('parts', 'parts.id', '=', 'sections.part_id')
            ->join('question_types', 'question_types.id', '=', 'sections.question_type_id')
            ->whereIn('parts.test_type_id', $testTypeIds)
            ->where('question_types.type', 'essay')
            ->orderBy('parts.id')
            ->orderBy('questions.order')
            ->orderBy('questions.id')
            ->pluck('questions.id');

        $scores = AttemptAnswer::query()
            ->whereIn('question_id', $questions)
            ->whereHas('attempt_part', fn ($q) => $q->where('attempt_id', $attempt->id))
            ->pluck('score', 'question_id');

        return $questions->map(fn ($id) => (float) ($scores[$id] ?? 0))->values()->all();
    }

    /**
     * IELTS variant of the attempt's Reading module ("academic" or "general", from tests.variant).
     */
    public function readingVariant(Attempt $attempt): string
    {
        $reading = $attempt->moduleTestTypes()->first(fn ($testType) => $testType->type?->name === 'Reading');

        return $reading?->test?->variant === 'general' ? 'general' : 'academic';
    }

    /**
     * Bands of every module the attempt has a row for (null for modules it does not have) and the overall
     * band of those. Same rules everywhere (result page, PDF, Telegram): Listening / Reading from the correct
     * answers (Reading by the test variant), Writing = Admin-confirmed band or (T1 + 2*T2) / 3, Speaking =
     * examiner band.
     *
     * @return array{listening: ?float, reading: ?float, writing: ?float, speaking: ?float, overall: ?float,
     *               listening_correct: ?int, reading_correct: ?int, reading_variant: string, writing_confirmed: bool,
     *               writing_pending: bool}
     */
    public function attemptBands(Attempt $attempt): array
    {
        $types = $attempt->relationLoaded('attempt_types') ? $attempt->attempt_types : $attempt->attempt_types()->get();
        $variant = $this->readingVariant($attempt);

        $result = [
            'listening' => null, 'reading' => null, 'writing' => null, 'speaking' => null, 'overall' => null,
            'listening_correct' => null, 'reading_correct' => null, 'reading_variant' => $variant,
            'writing_confirmed' => false, 'writing_pending' => false,
        ];

        foreach ($types as $type) {
            $name = $type->type?->name;
            if ($name === 'Listening') {
                $result['listening_correct'] = (int) $type->is_correct_count;
                $result['listening'] = IeltsScoreConverter::convertListening($result['listening_correct']);
            } elseif ($name === 'Reading') {
                $result['reading_correct'] = (int) $type->is_correct_count;
                $result['reading'] = IeltsScoreConverter::convertReadingFor($result['reading_correct'], $variant);
            } elseif ($name === 'Writing') {
                $type->setRelation('attempt', $attempt);
                $result['writing'] = $this->writingBand($type);
                $result['writing_confirmed'] = $type->reviewed_at !== null;
                $result['writing_pending'] = $attempt->essayAnswersForEvaluation($type->type_id, true)->isNotEmpty();
            } elseif ($name === 'Speaking' && $type->score !== null) {
                $result['speaking'] = (float) $type->score;
            }
        }

        $present = array_values(array_filter(
            [$result['listening'], $result['reading'], $result['writing'], $result['speaking']],
            fn ($band) => $band !== null,
        ));
        // A single-module practice has the band of that module only: no overall.
        $result['overall'] = $present !== [] && ! $attempt->isModulePractice()
            ? IeltsScoreConverter::calculateOverallBand($present)
            : null;

        return $result;
    }

    /**
     * @return array{listening: ?float, reading: ?float, writing: ?float, speaking: ?float, overall: ?float, ready: bool, missing: array<string>, modules: array<string>}
     */
    public function result(MockStudent $student): array
    {
        $attempt = $student->attempt;
        $types = $attempt?->attempt_types ?? collect();
        $byName = $types->keyBy(fn (AttemptType $t) => $t->type?->name);
        $finished = $this->writtenExamClosed($attempt);
        $modules = $this->moduleTypes($student);

        $bands = ['listening' => null, 'reading' => null, 'writing' => null, 'speaking' => null];
        $missing = [];

        foreach ($modules as $name) {
            $type = $byName->get($name);
            $key = strtolower($name);

            if ($name === 'Writing') {
                if ($type && $type->reviewed_at !== null) {
                    $bands[$key] = $this->writingBand($type);
                } elseif (! $type && $finished) {
                    $bands[$key] = 0.0;
                } else {
                    $missing[] = $type && ($type->is_submitted || $finished) ? 'writing_review' : 'writing';
                }

                continue;
            }

            if ($type && ($type->is_submitted || $finished)) {
                $bands[$key] = $name === 'Listening'
                    ? IeltsScoreConverter::convertListening((int) $type->is_correct_count)
                    : IeltsScoreConverter::convertReadingFor((int) $type->is_correct_count, $this->readingVariant($attempt));
            } elseif (! $type && $finished) {
                $bands[$key] = 0.0;
            } else {
                $missing[] = $key;
            }
        }

        $speaking = $byName->get('Speaking');
        if ($speaking && $speaking->score !== null) {
            $bands['speaking'] = (float) $speaking->score;
        } else {
            $missing[] = 'speaking';
        }

        // Offline late sync window still open: answers (and so the bands) may still change.
        $ready = $attempt !== null && $missing === [] && ! app(ExamService::class)->acceptsLateAnswers($attempt);
        $overall = $ready
            ? IeltsScoreConverter::calculateOverallBand(array_values(array_filter($bands, fn ($b) => $b !== null)))
            : null;

        return [...$bands, 'overall' => $overall, 'ready' => $ready, 'missing' => $missing, 'modules' => $modules];
    }

    /**
     * Whether every desktop module of the candidate is done (submitted, or the whole attempt finished).
     */
    public function writtenDone(MockStudent $student): bool
    {
        $attempt = $student->attempt;
        if (! $attempt) {
            return false;
        }
        if ($this->writtenExamClosed($attempt)) {
            return true;
        }

        $submitted = $attempt->attempt_types
            ->filter(fn (AttemptType $t) => $t->is_submitted)
            ->map(fn (AttemptType $t) => $t->type?->name)
            ->all();

        $modules = $this->moduleTypes($student);

        return $modules !== [] && array_diff($modules, $submitted) === [];
    }

    /**
     * Whether the written exam of the attempt is over: the attempt is finished and the candidate either
     * started a written module or the mock window has ended. An attempt that only carries an early Speaking
     * band (closed while the written exam was still ahead) does not count, so missing modules are not 0.
     */
    public function writtenExamClosed(?Attempt $attempt): bool
    {
        if (! $attempt || $attempt->finished_at === null) {
            return false;
        }

        $types = $attempt->relationLoaded('attempt_types') ? $attempt->attempt_types : $attempt->attempt_types()->get();
        $startedWritten = $types->contains(fn (AttemptType $t) => $t->started_at !== null
            && in_array($t->type?->name, MockBankService::MODULE_TYPES, true));

        return $startedWritten || $attempt->mockWindowEnded();
    }

    /**
     * Module the candidate is currently writing (latest started, not submitted).
     */
    public function currentModule(?Attempt $attempt): ?string
    {
        if (! $attempt || $attempt->finished_at !== null) {
            return null;
        }

        return $attempt->attempt_types
            ->filter(fn (AttemptType $t) => ! $t->is_submitted && in_array($t->type?->name, MockBankService::MODULE_TYPES, true))
            ->sortByDesc('started_at')
            ->first()?->type?->name;
    }

    /**
     * @param  array<string, mixed>|null  $result  precomputed result()
     */
    public function status(MockStudent $student, ?array $result = null): string
    {
        if ($student->result_delivered_at !== null) {
            return 'delivered';
        }

        $result ??= $this->result($student);
        if ($result['ready']) {
            return 'result_ready';
        }

        if ($this->writtenDone($student)) {
            // Waiting for the speaking slot; otherwise waiting for Writing confirmation / a slot.
            return in_array('speaking', $result['missing'], true) && $student->speaking_at !== null
                ? 'speaking_waiting'
                : 'written_done';
        }

        $attempt = $student->attempt;
        if ($attempt && $attempt->attempt_types->contains(fn (AttemptType $t) => in_array($t->type?->name, MockBankService::MODULE_TYPES, true))) {
            return 'in_exam';
        }

        return $student->checked_in_at !== null || $attempt !== null ? 'checked_in' : 'not_arrived';
    }
}
