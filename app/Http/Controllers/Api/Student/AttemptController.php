<?php

namespace App\Http\Controllers\Api\Student;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\AttemptAnswerOption;
use App\Models\AttemptPart;
use App\Models\AttemptType;
use App\Models\Question;
use App\Models\Test;
use App\Services\AnswerMatcher;
use App\Services\Desktop\ExamPayloadBuilder;
use App\Services\ExamService;
use App\Services\MockResultService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * Practice attempts of the signed-in student. The exam itself (module start/submit, answers, audio) is served
 * by the desktop exam controllers through ResolveStudentAttempt, so all three exam rooms follow the same rules.
 */
class AttemptController extends Controller
{
    public function __construct(
        private readonly ExamService $exam,
        private readonly ExamPayloadBuilder $payload,
        private readonly MockResultService $results,
    ) {}

    /**
     * GET /student/attempts?page= — history, newest first; bands only for finished attempts.
     */
    public function index(Request $request): JsonResponse
    {
        $page = Attempt::query()
            ->with(['test:id,name', 'attempt_types.type'])
            ->where('user_id', Auth::id())
            ->whereNull('mock_id')
            ->orderByDesc('id')
            ->paginate(20);

        return response()->json([
            'data' => collect($page->items())->map(fn (Attempt $attempt) => $this->summary($attempt))->all(),
            'meta' => [
                'current_page' => $page->currentPage(),
                'last_page' => $page->lastPage(),
                'total' => $page->total(),
            ],
        ]);
    }

    /**
     * POST /student/attempts {test_id, module?} — a running attempt of the same test and module is resumed;
     * any other running attempt is finished first (website rule: one running practice attempt per student).
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'test_id' => ['required', 'integer'],
            // One module ("reading") or several ("listening,reading"); null or all of them = the whole test.
            'module' => ['nullable', 'string', 'max:32'],
        ]);
        $modules = Attempt::parseModules($data['module'] ?? null);
        if (($data['module'] ?? null) !== null && $data['module'] !== '' && $modules === []) {
            throw ApiException::unprocessable('module_invalid', 'Unknown module.');
        }

        $test = Test::find($data['test_id']);
        if (! $test || $test->isMock() || ! $request->user()->can('attempt', $test)) {
            throw ApiException::forbidden('This test is not available.');
        }

        $module = null;
        if ($modules !== []) {
            $present = $test->types()->whereHas('parts')->with('type')->get()
                ->map(fn ($tt) => array_search($tt->type?->name, Attempt::PRACTICE_MODULES, true))
                ->filter()->unique()->values()->all();
            if (array_diff($modules, $present) !== []) {
                throw ApiException::unprocessable('module_not_in_test', 'This test has no such module.');
            }
            // Every module of the test chosen: that is the full test.
            $module = array_diff($present, $modules) === [] ? null : implode(',', $modules);
        }

        $running = Attempt::where('user_id', Auth::id())->whereNull('mock_id')->whereNull('finished_at')->get();
        $resume = $running->first(fn (Attempt $a) => (int) $a->test_id === (int) $test->id && $a->module === $module);

        if ($resume) {
            return response()->json(['attempt' => $this->state($resume), 'resumed' => true]);
        }

        foreach ($running as $other) {
            $this->exam->finishAttempt($other);
        }

        $attempt = Attempt::create([
            'user_id' => Auth::id(),
            'name' => $request->user()->name,
            'test_id' => $test->id,
            'module' => $module,
            'started_at' => now(),
            'status' => 1,
        ]);

        return response()->json(['attempt' => $this->state($attempt), 'resumed' => false], 201);
    }

    /**
     * GET /student/attempts/{attempt} — state + modules with their parts and timers.
     */
    public function show(Request $request): JsonResponse
    {
        $attempt = $this->attempt($request);
        $this->exam->autoFinishExpiredTypes($attempt, $this->graceSeconds());

        return response()->json(['attempt' => $this->state($attempt->fresh())]);
    }

    /**
     * GET /student/attempts/{attempt}/parts/{part} — PartPayload (docs/desktop/API.md), no answer keys.
     */
    public function part(Request $request, int $part): JsonResponse
    {
        $attempt = $this->attempt($request);
        $payload = $this->payload->forStudent($attempt)->part($attempt, $part, $attempt->examModules());

        if ($payload === null) {
            throw ApiException::forbidden('This part is not part of your test.');
        }

        return response()->json($payload + ['server_time' => ExamService::apiTime()]);
    }

    /**
     * POST /student/attempts/{attempt}/submit — finish the whole attempt.
     */
    public function submit(Request $request): JsonResponse
    {
        $attempt = $this->attempt($request);
        $this->exam->finishAttempt($attempt);

        return response()->json(['attempt' => $this->summary($attempt->fresh(['test', 'attempt_types.type']))]);
    }

    /**
     * GET /student/attempts/{attempt}/result — bands and the answer review; only after the attempt is finished.
     */
    public function result(Request $request): JsonResponse
    {
        $attempt = $this->attempt($request);
        if ($attempt->finished_at === null) {
            throw ApiException::conflict('not_finished', 'Results are available after the test is finished.');
        }

        $attempt->load(['test:id,name', 'attempt_types.type']);
        $modules = $attempt->examModules();
        $parts = $this->payload->forStudent($attempt)->allParts($attempt, $modules);

        $questionIds = collect($parts)->flatMap(fn ($p) => collect($p['sections'])->flatMap(fn ($s) => collect($s['questions'])->pluck('id')))->all();
        $questions = Question::withoutEagerLoads()->with('options')->whereIn('id', $questionIds)->get()->keyBy('id');

        $attemptParts = AttemptPart::where('attempt_id', $attempt->id)->pluck('id');
        $answers = AttemptAnswer::whereIn('attempt_part_id', $attemptParts)->get()->keyBy('question_id');
        $selected = AttemptAnswerOption::withoutEagerLoads()->whereIn('attempt_answer_id', $answers->pluck('id'))
            ->get(['attempt_answer_id', 'option_id'])->groupBy('attempt_answer_id');

        $bands = $this->results->attemptBands($attempt);
        $byType = [];

        foreach ($parts as $part) {
            $type = $part['type'];
            $byType[$type] ??= [
                'type' => $type,
                'type_id' => $part['type_id'],
                'title' => ucfirst($type),
                'band' => $bands[$type] ?? null,
                'correct' => $type === 'writing' ? null : ($bands[$type.'_correct'] ?? null),
                'questions' => [],
                'essays' => [],
            ];

            foreach ($part['sections'] as $section) {
                foreach ($section['questions'] as $q) {
                    $question = $questions->get($q['id']);
                    $answer = $answers->get($q['id']);
                    if (! $question) {
                        continue;
                    }

                    if ($section['question_type'] === 'essay') {
                        $text = (string) ($answer?->answer_text ?? '');
                        $byType[$type]['essays'][] = [
                            'question_id' => (int) $question->id,
                            'task' => count($byType[$type]['essays']) + 1,
                            'prompt_html' => $q['html'] !== '' ? $q['html'] : $section['html'],
                            'answer' => $text,
                            'words' => $text === '' ? 0 : count(preg_split('/\s+/u', trim($text)) ?: []),
                            'band' => $answer?->score !== null ? (float) $answer->score : null,
                            'feedback' => $answer?->review_note ?: $answer?->review_note_ai,
                        ];

                        continue;
                    }

                    $byType[$type]['questions'][] = $this->review($q, $question, $answer, ($answer ? $selected->get($answer->id) : null)?->pluck('option_id')->all() ?? []);
                }
            }
        }

        return response()->json([
            'attempt' => $this->summary($attempt),
            'bands' => $bands,
            'modules' => array_values($byType),
        ]);
    }

    private function review(array $q, Question $question, ?AttemptAnswer $answer, array $selectedIds): array
    {
        $options = $question->options->sortBy('id')->values();
        $label = fn ($option) => trim(html_entity_decode(strip_tags((string) $option->textarea)));

        if ($options->isNotEmpty()) {
            $correct = $options->filter(fn ($o) => (bool) $o->is_correct);
            $mine = $options->filter(fn ($o) => in_array((int) $o->id, array_map('intval', $selectedIds), true));
            $points = AttemptType::optionPoints($options, $selectedIds);
            $max = max(1, $correct->count());

            return [
                'question_id' => (int) $question->id,
                'number' => $q['number'],
                'number_count' => $q['number_count'],
                'your_answer' => $mine->map($label)->implode(', ') ?: null,
                'correct_answer' => $correct->map($label)->implode(', '),
                'points' => $points,
                'max_points' => $max,
                'is_correct' => $points === $max,
            ];
        }

        $isCorrect = AnswerMatcher::matches($answer?->answer_text, $question->answer_text);

        return [
            'question_id' => (int) $question->id,
            'number' => $q['number'],
            'number_count' => 1,
            'your_answer' => $answer?->answer_text !== null && trim($answer->answer_text) !== '' ? $answer->answer_text : null,
            'correct_answer' => (string) $question->answer_text,
            'points' => $isCorrect ? 1 : 0,
            'max_points' => 1,
            'is_correct' => $isCorrect,
        ];
    }

    private function state(Attempt $attempt): array
    {
        return [
            'id' => (int) $attempt->id,
            'test' => ['id' => (int) $attempt->test_id, 'name' => $attempt->test?->name],
            'module' => $attempt->module,
            'status' => $attempt->finished_at ? 'completed' : 'in_progress',
            'paused' => $attempt->paused_at !== null,
            'started_at' => ExamService::apiTime($attempt->started_at),
            'finished_at' => ExamService::apiTime($attempt->finished_at),
            'modules' => $this->payload->forStudent($attempt)->modules($attempt, $attempt->examModules()),
            'server_time' => ExamService::apiTime(),
        ];
    }

    private function summary(Attempt $attempt): array
    {
        $finished = $attempt->finished_at !== null;
        $bands = $finished ? $this->results->attemptBands($attempt) : null;

        return [
            'id' => (int) $attempt->id,
            'test' => ['id' => (int) $attempt->test_id, 'name' => $attempt->test?->name],
            'module' => $attempt->module,
            'status' => $finished ? 'completed' : 'in_progress',
            'started_at' => ExamService::apiTime($attempt->started_at ?? $attempt->created_at),
            'finished_at' => ExamService::apiTime($attempt->finished_at),
            'modules' => $attempt->attempt_types
                ->filter(fn ($t) => in_array($t->type?->name, Attempt::DESKTOP_MODULE_ORDER, true))
                ->map(fn ($t) => strtolower($t->type->name))->values()->all(),
            'bands' => $bands ? [
                'overall' => $bands['overall'],
                'listening' => $bands['listening'],
                'reading' => $bands['reading'],
                'writing' => $bands['writing'],
                'writing_pending' => $bands['writing_pending'],
            ] : null,
        ];
    }

    private function attempt(Request $request): Attempt
    {
        return $request->attributes->get('attempt');
    }

    private function graceSeconds(): int
    {
        return (int) config('desktop.answer_grace_seconds', 30);
    }
}
