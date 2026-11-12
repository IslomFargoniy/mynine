<?php

namespace App\Models;

use App\Services\AnswerMatcher;
use Carbon\Carbon;
use Database\Factories\AttemptTypeFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class AttemptType extends Model
{
    /** @use HasFactory<AttemptTypeFactory> */
    use HasFactory;

    protected $fillable = [
        'attempt_id',
        'type_id',
        'score',
        'is_correct_count',
        'is_submitted',
        'comment',
        'started_at',
        'finished_at',
        'reviewed_at',
        'reviewed_by',
        'offline_at_end',
        'audio_lag_seconds',
    ];

    protected $casts = [
        'offline_at_end' => 'boolean',
        'audio_lag_seconds' => 'integer',
    ];

    protected $with = [
        'type',
    ];

    protected static function booted(): void
    {
        // Billing: the first written module a mock candidate starts records them once, immutably.
        static::created(function (AttemptType $attemptType) {
            $typeName = Type::query()->whereKey($attemptType->type_id)->value('name');
            if (! in_array($typeName, Attempt::DESKTOP_MODULE_ORDER, true)) {
                return;
            }

            $attempt = Attempt::withoutGlobalScopes()->withoutEagerLoads()->find($attemptType->attempt_id);
            if ($attempt) {
                CenterBillableCandidate::record($attempt);
            }
        });
    }

    public function attempt()
    {
        return $this->belongsTo(Attempt::class, 'attempt_id');
    }

    public function type()
    {
        return $this->belongsTo(Type::class, 'type_id');
    }

    public function reviewer()
    {
        return $this->belongsTo(User\User::class, 'reviewed_by');
    }

    /** Result fields a candidate must not see before the attempt is finished. */
    public const RESULT_FIELDS = ['score', 'is_correct_count', 'comment', 'reviewed_at', 'reviewed_by'];

    public function hideResults(): static
    {
        return $this->makeHidden(self::RESULT_FIELDS);
    }

    // AttemptType modelida
    public function getAttemptPartsAttribute()
    {
        $attempt_parts = AttemptPart::query()
            ->where(function ($query) {
                $query->where('attempt_id', $this->attempt_id);
            })
            ->whereHas('part.test_type', function ($q) {
                $q->where(function ($query) {
                    $query->where('type_id', $this->type_id);
                });
            })
            ->with([
                'part.test_type',
                'part.attempt_part' => fn ($q) => $q->where('attempt_id', $this->attempt_id),
                'part.sections.questions.options',
            ])
            ->orderBy('part_id')
            ->get();

        $attempt_parts->each(function ($attempt_part) {
            if ($attempt_part->part && $attempt_part->part->sections) {
                $attempt_part->part->sections->load([
                    'questions.attempt_answer' => fn ($q) => $q->where('attempt_part_id', $attempt_part->id)
                        ->with('attempt_answer_options.option'),
                ]);
            }
        });

        return $attempt_parts;
    }

    /**
     * Score of a module: Listening / Reading = number of correct answers, Writing / Speaking = sum of the
     * examiner or AI band scores. Called on submit, after essay evaluation and after answer-key fixes.
     *
     * Option questions are scored from the LIVE options.is_correct (never the copy in
     * attempt_answer_options), so fixing a key and re-scoring corrects old attempts. A question with N
     * correct options ("choose TWO") is worth 1 point per correct selected option, and 0 when more
     * options than N were selected.
     */
    public static function calculateIsCorrectCount($attempt_id, $type_id)
    {
        $answers = AttemptAnswer::query()
            ->whereHas('attempt_part', function ($query) use ($attempt_id, $type_id) {
                $query->where('attempt_id', $attempt_id)
                    ->whereHas('part.test_type', function ($q) use ($type_id) {
                        $q->where('type_id', $type_id);
                    });
            })
            ->with(['question.options', 'attempt_answer_options', 'attempt_part.part.test_type.type'])
            ->get();

        $correctCount = 0;

        foreach ($answers as $answer) {
            $question = $answer->question;
            if (! $question) {
                continue;
            }

            $typeName = $answer->attempt_part?->part?->test_type?->type?->name;

            // Writing / Speaking: sum of examiner or AI band scores
            if (! in_array($typeName, ['Listening', 'Reading'], true)) {
                $correctCount += (float) ($answer->score ?? 0);

                continue;
            }

            if ($question->options->count() > 0) {
                $correctCount += static::optionPoints($question->options, $answer->attempt_answer_options->pluck('option_id')->all());
            } elseif (AnswerMatcher::matches($answer->answer_text, $question->answer_text)) {
                $correctCount += 1;
            }
        }

        return (float) $correctCount;
    }

    /**
     * Points for the selected options of one question: 0 when more options than the key has were selected,
     * else one point per correctly selected option.
     *
     * @param  Collection<int, Option>  $options  the question's options (live keys)
     * @param  array<int, int|string>  $selectedIds
     */
    public static function optionPoints($options, array $selectedIds): int
    {
        $correctIds = $options->filter(fn ($option) => (bool) $option->is_correct)->pluck('id')->map(fn ($id) => (int) $id)->all();
        $selected = array_values(array_unique(array_map('intval', $selectedIds)));

        if ($correctIds === [] || count($selected) > count($correctIds)) {
            return 0;
        }

        return count(array_intersect($selected, $correctIds));
    }

    /**
     * Bu attempt_type uchun is_correct_count ni qayta hisoblash va DB ga yozish
     */
    public function recalculateIsCorrectCount()
    {
        $this->is_correct_count = static::calculateIsCorrectCount($this->attempt_id, $this->type_id) ?? 0;
        $this->save();

        return $this->is_correct_count;
    }

    /**
     * Finish the module (no-op when it is already submitted).
     */
    public function finish()
    {
        $this->submit();

        return $this;
    }

    /**
     * Atomically submit the module: only the caller whose UPDATE ... WHERE is_submitted = 0 changed the row
     * gets true (and is the one that may queue the AI evaluation), so concurrent submits / auto-finishes never
     * evaluate the same essays twice. finished_at keeps an end time that already passed (time over), else now.
     */
    public function submit(): bool
    {
        $now = now();
        $current = static::whereKey($this->id)->value('finished_at');
        $finishedAt = $current !== null && Carbon::parse($current)->lt($now) ? Carbon::parse($current) : $now;

        $changed = static::whereKey($this->id)
            ->where('is_submitted', false)
            ->update(['is_submitted' => true, 'finished_at' => $finishedAt, 'updated_at' => $now]);

        if ($changed !== 1) {
            $this->refresh();

            return false;
        }

        $this->forceFill(['is_submitted' => true, 'finished_at' => $finishedAt])->syncOriginal();

        // Bog'liq AttemptPartlarni ham yakunlash
        AttemptPart::query()
            ->where('attempt_id', $this->attempt_id)
            ->whereHas('part.test_type', fn ($q) => $q->where('type_id', $this->type_id))
            ->where(fn ($q) => $q->whereNull('finished_at')->orWhere('finished_at', '>', $now))
            ->update(['finished_at' => $now]);

        // Ballarni hisoblash
        $this->recalculateIsCorrectCount();

        return true;
    }
}
