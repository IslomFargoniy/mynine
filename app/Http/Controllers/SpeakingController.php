<?php

namespace App\Http\Controllers;

use App\Models\AttemptType;
use App\Models\Mock;
use App\Models\MockStudent;
use App\Models\Type;
use App\Services\ExamService;
use App\Services\IeltsScoreConverter;
use App\Services\MockResultService;
use Carbon\Carbon;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Speaking (Admin): time slots and the examiner's band (four criteria, IELTS rounding of the average).
 */
class SpeakingController extends Controller
{
    public const CRITERIA = [
        'fluency' => 'Fluency & Coherence',
        'lexical' => 'Lexical Resource',
        'grammar' => 'Grammatical Range & Accuracy',
        'pronunciation' => 'Pronunciation',
    ];

    public function __construct(
        private readonly MockResultService $results,
        private readonly ExamService $exam,
    ) {}

    public function index(Request $request): Response
    {
        $this->authorize('examine', Mock::class);

        // Mocks started in the last 30 days, upcoming ones, and long-running mocks
        // that are still open (a mock started months ago may still have candidates).
        $mocks = Mock::query()->withoutEagerLoads()
            ->where(fn ($q) => $q->where('started_at', '>=', now()->subDays(30))->orWhere('finished_at', '>=', now()))
            ->orderByDesc('started_at')
            ->orderByDesc('id')
            ->get(['id', 'name', 'started_at', 'finished_at', 'speaking_starts_at', 'speaking_slot_minutes', 'active']);

        $mockId = $request->integer('mock_id') ?: null;
        $mock = $mockId ? Mock::withoutEagerLoads()->find($mockId) : null;
        if ($mock && ! $mocks->contains('id', $mock->id)) {
            // Opened from an older mock's page: keep it in the dropdown so the selection matches the list.
            $mocks->push($mock);
        }
        $mock ??= Mock::pickDefault($mocks);

        $candidates = $mock
            ? MockStudent::query()
                ->with(['attempt.attempt_types.type'])
                ->where('mock_id', $mock->id)
                ->get()
                ->sortBy(fn (MockStudent $s) => [$s->speaking_at?->getTimestamp() ?? PHP_INT_MAX, $s->name])
                ->values()
                ->map(function (MockStudent $s) {
                    $speaking = $s->attempt?->attempt_types->first(fn (AttemptType $t) => $t->type?->name === 'Speaking');

                    return [
                        'id' => $s->id,
                        'name' => $s->name,
                        'code' => $s->code,
                        'speaking_at' => $s->speaking_at?->toIso8601String(),
                        'written_done' => $this->results->writtenDone($s),
                        'band' => $speaking?->score !== null ? (float) $speaking->score : null,
                        'criteria' => $this->parseCriteria($speaking?->comment),
                        'note' => $this->parseNote($speaking?->comment),
                    ];
                })
            : collect();

        return Inertia::render('speaking/index', [
            'mocks' => $mocks->map(fn (Mock $m) => $m->only(['id', 'name', 'started_at'])),
            'mock' => $mock?->only(['id', 'name', 'started_at', 'speaking_starts_at', 'speaking_slot_minutes']),
            'candidates' => $candidates,
            'criteria' => self::CRITERIA,
        ]);
    }

    /**
     * Assign consecutive slots from mocks.speaking_starts_at, ordered by written-exam finish or by name.
     */
    public function autoAssign(Request $request, Mock $mock): RedirectResponse
    {
        $this->authorize('examine', $mock);

        $data = $request->validate([
            'order' => ['required', Rule::in(['finish', 'name'])],
            'only_unassigned' => ['nullable', 'boolean'],
        ]);

        $students = MockStudent::query()->with('attempt')->where('mock_id', $mock->id)->get();
        $fixed = $request->boolean('only_unassigned') ? $students->whereNotNull('speaking_at') : collect();
        $toAssign = $students->diff($fixed);

        $toAssign = $data['order'] === 'name'
            ? $toAssign->sortBy('name')
            : $toAssign->sortBy(fn (MockStudent $s) => [$s->attempt?->finished_at ? Carbon::parse($s->attempt->finished_at)->getTimestamp() : PHP_INT_MAX, $s->name]);

        $taken = $fixed->map(fn (MockStudent $s) => $s->speaking_at->getTimestamp())->flip();
        // From the mock's Speaking start time, or from now when it is not set or already passed
        // (rounded up to the next 5 minutes).
        $now = now()->second(0);
        $now->addMinutes((5 - $now->minute % 5) % 5);
        $slot = $mock->speaking_starts_at ? Carbon::parse($mock->speaking_starts_at)->max($now) : $now;
        $minutes = max(1, (int) ($mock->speaking_slot_minutes ?: 15));

        foreach ($toAssign->values() as $student) {
            while ($taken->has($slot->getTimestamp())) {
                $slot->addMinutes($minutes);
            }
            $student->forceFill(['speaking_at' => $slot->copy()])->saveQuietly();
            $slot->addMinutes($minutes);
        }

        return back()->with('success', $toAssign->count().' ta nomzodga Speaking vaqti belgilandi.');
    }

    public function updateSlot(Request $request, MockStudent $mockStudent): RedirectResponse
    {
        $this->authorize('examine', $mockStudent->mock);

        $data = $request->validate([
            'speaking_at' => ['nullable', 'date_format:Y-m-d H:i'],
        ]);

        $mockStudent->forceFill(['speaking_at' => $data['speaking_at'] ?? null])->save();

        return back()->with('success', __('speaking_slot_saved'));
    }

    /**
     * Examiner band from the four criteria; stored on the Speaking attempt_type (existing manual-score path).
     */
    public function score(Request $request, MockStudent $mockStudent): RedirectResponse
    {
        $this->authorize('examine', $mockStudent->mock);

        $rules = ['note' => ['nullable', 'string', 'max:2000']];
        foreach (array_keys(self::CRITERIA) as $key) {
            $rules[$key] = ['required', 'numeric', 'min:0', 'max:9', 'multiple_of:0.5'];
        }
        $data = $request->validate($rules);

        $attempt = $this->exam->findOrCreateMockAttempt($mockStudent);
        if (! $attempt) {
            return back()->with('error', __('mock_modules_missing'));
        }

        $band = self::band(array_map(fn ($key) => (float) $data[$key], array_keys(self::CRITERIA)));
        $comment = collect(self::CRITERIA)->map(fn ($label, $key) => $label.': '.number_format((float) $data[$key], 1))->implode("\n");
        if (! empty($data['note'])) {
            $comment .= "\n\n".$data['note'];
        }

        $this->exam->storeManualScore($attempt, $this->speakingTypeId(), $band, $comment);

        // Scored without a slot: record when the Speaking test took place.
        if (! $mockStudent->speaking_at) {
            $mockStudent->forceFill(['speaking_at' => now()->second(0)])->saveQuietly();
        }

        return back()->with('success', __('speaking_score_saved', ['band' => $band]));
    }

    /**
     * @param  array<float>  $criteria
     */
    public static function band(array $criteria): float
    {
        return IeltsScoreConverter::calculateOverallBand($criteria);
    }

    private function speakingTypeId(): int
    {
        return (int) Type::firstOrCreate(['name' => 'Speaking'], ['minute' => 15])->id;
    }

    /**
     * @return array<string, float|null>
     */
    private function parseCriteria(?string $comment): array
    {
        $out = [];
        foreach (self::CRITERIA as $key => $label) {
            $out[$key] = $comment && preg_match('/^'.preg_quote($label, '/').':\s*([\d.]+)/m', $comment, $m) ? (float) $m[1] : null;
        }

        return $out;
    }

    private function parseNote(?string $comment): ?string
    {
        if (! $comment) {
            return null;
        }

        $parts = explode("\n\n", $comment, 2);

        return $parts[1] ?? null;
    }
}
