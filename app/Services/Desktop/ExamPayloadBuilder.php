<?php

namespace App\Services\Desktop;

use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\AttemptAnswerOption;
use App\Models\AttemptPart;
use App\Models\AttemptType;
use App\Models\Part;
use App\Models\Section;
use App\Models\TestType;
use App\Services\AudioUploadService;
use App\Services\ExamService;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

/**
 * Builds the desktop API exam payloads (docs/desktop/API.md). Payloads are assembled field by field
 * from an allow-list, so answer keys (options.is_correct, questions.answer_text, scores, reviews)
 * can never leak through model serialization.
 */
class ExamPayloadBuilder
{
    public function __construct(
        private readonly ExamService $exam,
        private readonly AudioUploadService $audio,
    ) {}

    /**
     * @param  Collection<int, TestType>  $modules  exam modules in order (Attempt::examModules)
     */
    public function modules(Attempt $attempt, Collection $modules): array
    {
        $numbering = $this->numbering($modules);
        $attemptTypes = $this->attemptTypes($attempt);

        return $modules->map(function (TestType $testType) use ($numbering, $attemptTypes) {
            $attemptType = $attemptTypes->get($testType->type_id);

            return [
                'type_id' => (int) $testType->type_id,
                'type' => strtolower($testType->type->name),
                'title' => $testType->type->name,
                'duration_seconds' => $this->exam->moduleDurationSeconds($testType),
                'status' => $this->moduleStatus($attemptType),
                'started_at' => $this->iso($attemptType?->started_at),
                'finished_at' => $this->iso($attemptType?->finished_at),
                'audio' => $this->moduleAudio($testType),
                'parts' => array_values(array_map(fn (array $n) => [
                    'id' => $n['id'],
                    'name' => $n['name'],
                    'order' => $n['order'],
                    'question_count' => $n['question_count'],
                    'first_question_number' => $n['first_question_number'],
                ], $numbering['modules'][$testType->id] ?? [])),
            ];
        })->values()->all();
    }

    /**
     * Short module state for the heartbeat.
     *
     * @param  Collection<int, TestType>  $modules
     */
    public function moduleTimers(Attempt $attempt, Collection $modules): array
    {
        $attemptTypes = $this->attemptTypes($attempt);

        return $modules->map(function (TestType $testType) use ($attemptTypes) {
            $attemptType = $attemptTypes->get($testType->type_id);

            return [
                'type_id' => (int) $testType->type_id,
                'status' => $this->moduleStatus($attemptType),
                'finished_at' => $this->iso($attemptType?->finished_at),
            ];
        })->values()->all();
    }

    public function moduleTimer(AttemptType $attemptType): array
    {
        return [
            'type_id' => (int) $attemptType->type_id,
            'status' => $this->moduleStatus($attemptType),
            'started_at' => $this->iso($attemptType->started_at),
            'finished_at' => $this->iso($attemptType->finished_at),
        ];
    }

    /**
     * Full offline bundle for GET /exam/prefetch.
     *
     * @param  Collection<int, TestType>  $modules
     */
    public function prefetch(Attempt $attempt, Collection $modules): array
    {
        $parts = $this->loadParts($modules->pluck('id')->all());
        $partPayloads = $this->parts($attempt, $parts, $modules);

        $audio = [];
        foreach ($modules as $testType) {
            if ($this->isListening($testType) && ($entry = $this->audioEntry('test-'.$testType->test_id, $testType->test?->audio_path, route('api.v1.exam.audio.test', $testType->test_id)))) {
                $audio[$entry['key']] = $entry;
            }
        }
        foreach ($parts as $part) {
            if ($entry = $this->audioEntry('part-'.$part->id, $part->audio_path, route('api.v1.exam.audio.part', $part->id))) {
                $audio[$entry['key']] = $entry;
            }
        }

        return [
            'modules' => $this->modules($attempt, $modules),
            'parts' => $partPayloads,
            'audio' => array_values($audio),
            'images' => $this->images($parts),
        ];
    }

    /**
     * PartPayload for one part (GET /exam/parts/{part}).
     *
     * @param  Collection<int, TestType>  $modules
     */
    public function part(Attempt $attempt, int $partId, Collection $modules): ?array
    {
        $parts = $this->loadParts($modules->pluck('id')->all(), [$partId]);

        return $parts->isEmpty() ? null : $this->parts($attempt, $parts, $modules)[0];
    }

    /**
     * @param  array<int>  $testTypeIds
     * @param  array<int>|null  $onlyPartIds
     * @return Collection<int, Part>
     */
    private function loadParts(array $testTypeIds, ?array $onlyPartIds = null): Collection
    {
        // Part -> sections -> (questions -> options, question_type, options) come from the models' $with,
        // each level in one query.
        return Part::query()
            ->whereIn('test_type_id', $testTypeIds)
            ->when($onlyPartIds !== null, fn ($q) => $q->whereIn('id', $onlyPartIds))
            ->orderBy('id')
            ->get();
    }

    /**
     * @param  Collection<int, Part>  $parts
     * @param  Collection<int, TestType>  $modules
     */
    private function parts(Attempt $attempt, Collection $parts, Collection $modules): array
    {
        $numbering = $this->numbering($modules)['parts'];
        $modulesById = $modules->keyBy('id');
        $answers = $this->answers($attempt, $parts->pluck('id')->all());

        return $parts->map(function (Part $part) use ($numbering, $modulesById, $answers) {
            $testType = $modulesById->get($part->test_type_id);
            $meta = $numbering[$part->id];
            $number = $meta['first_question_number'];

            return [
                'id' => (int) $part->id,
                'type' => strtolower($testType->type->name),
                'type_id' => (int) $testType->type_id,
                'name' => $part->name,
                'order' => $meta['order'],
                'first_question_number' => $meta['first_question_number'],
                'html' => (string) ($part->textarea ?? ''),
                'audio_key' => $this->audio->absolutePath($part->audio_path) ? 'part-'.$part->id : null,
                'sections' => $part->sections->sortBy('id')->values()
                    ->map(function (Section $section) use (&$number, $part, $answers) {
                        return $this->section($section, $number, $answers[$part->id] ?? []);
                    })->all(),
            ];
        })->values()->all();
    }

    private function section(Section $section, int &$number, array $answers): array
    {
        $type = $section->question_type?->type;

        $questions = $section->questions->sortBy('id')->values()->map(function ($question, int $index) use (&$number, $answers) {
            $options = $question->options->sortBy('id')->values();
            $count = $options->isEmpty() ? 1 : $options->where('is_correct', true)->count();
            $answer = $answers[$question->id] ?? null;

            $payload = [
                'id' => (int) $question->id,
                'number' => $number,
                'number_count' => $count,
                'order' => $question->order !== null ? (int) $question->order : $index + 1,
                'html' => (string) ($question->textarea ?? ''),
                'options' => $options->map(fn ($option) => [
                    'id' => (int) $option->id,
                    'html' => (string) ($option->textarea ?? ''),
                ])->all(),
                'answer' => [
                    'text' => $answer['text'] ?? null,
                    'option_ids' => $answer['option_ids'] ?? [],
                ],
            ];

            $number += $count;

            return $payload;
        })->all();

        return [
            'id' => (int) $section->id,
            'question_type' => $type,
            'input_type' => $section->question_type?->input_type,
            'html' => in_array($type, ExamService::GAP_TYPES, true)
                ? $this->exam->maskGaps($section->textarea)
                : (string) ($section->textarea ?? ''),
            // Strings: matching ranges are letters ("A"-"G") or roman numerals as often as numbers.
            'from_option' => $section->from_option !== null && $section->from_option !== '' ? (string) $section->from_option : null,
            'to_option' => $section->to_option !== null && $section->to_option !== '' ? (string) $section->to_option : null,
            'options' => $section->options->sortBy('id')->values()->map(fn ($option) => [
                'id' => (int) $option->id,
                'html' => (string) ($option->textarea ?? ''),
            ])->all(),
            'drag_options' => $type === 'drag_and_drop' ? $this->exam->dragOptions($section) : [],
            'questions' => $questions,
        ];
    }

    /**
     * Saved answers of the attempt: [part_id => [question_id => {text, option_ids}]].
     *
     * @param  array<int>  $partIds
     */
    private function answers(Attempt $attempt, array $partIds): array
    {
        $attemptParts = AttemptPart::where('attempt_id', $attempt->id)->whereIn('part_id', $partIds)->pluck('part_id', 'id');
        if ($attemptParts->isEmpty()) {
            return [];
        }

        $answers = AttemptAnswer::whereIn('attempt_part_id', $attemptParts->keys())
            ->get(['id', 'attempt_part_id', 'question_id', 'answer_text']);
        $options = AttemptAnswerOption::withoutEagerLoads()
            ->whereIn('attempt_answer_id', $answers->pluck('id'))
            ->orderBy('id')
            ->get(['attempt_answer_id', 'option_id'])
            ->groupBy('attempt_answer_id');

        $result = [];
        foreach ($answers as $answer) {
            $result[$attemptParts[$answer->attempt_part_id]][$answer->question_id] = [
                'text' => $answer->answer_text,
                'option_ids' => ($options->get($answer->id) ?? collect())->pluck('option_id')->map(fn ($id) => (int) $id)->values()->all(),
            ];
        }

        return $result;
    }

    /**
     * Part order and question numbering per module, mirroring the web exam room
     * (a question is worth 1 number, or its number of correct options for "choose N" questions).
     *
     * @param  Collection<int, TestType>  $modules
     * @return array{modules: array<int, array<int, array>>, parts: array<int, array>}
     */
    private function numbering(Collection $modules): array
    {
        $parts = Part::withoutEagerLoads()
            ->whereIn('test_type_id', $modules->pluck('id'))
            ->orderBy('id')
            ->get(['id', 'test_type_id', 'name']);

        $weights = DB::table('questions')
            ->join('sections', 'sections.id', '=', 'questions.section_id')
            ->leftJoin('options', 'options.question_id', '=', 'questions.id')
            ->whereIn('sections.part_id', $parts->pluck('id'))
            ->groupBy('questions.id', 'sections.part_id')
            ->select([
                'sections.part_id',
                DB::raw('COUNT(options.id) as option_count'),
                DB::raw('SUM(CASE WHEN options.is_correct = 1 THEN 1 ELSE 0 END) as correct_count'),
            ])
            ->get()
            ->groupBy('part_id')
            ->map(fn ($rows) => $rows->sum(fn ($row) => (int) $row->option_count === 0 ? 1 : (int) $row->correct_count));

        $byModule = [];
        $byPart = [];
        foreach ($parts->groupBy('test_type_id') as $testTypeId => $moduleParts) {
            $next = 1;
            foreach ($moduleParts->values() as $index => $part) {
                $count = (int) ($weights[$part->id] ?? 0);
                $entry = [
                    'id' => (int) $part->id,
                    'name' => $part->name,
                    'order' => $index + 1,
                    'question_count' => $count,
                    'first_question_number' => $next,
                ];
                $byModule[$testTypeId][] = $entry;
                $byPart[$part->id] = $entry;
                $next += $count;
            }
        }

        return ['modules' => $byModule, 'parts' => $byPart];
    }

    private function attemptTypes(Attempt $attempt): Collection
    {
        return AttemptType::withoutEagerLoads()->where('attempt_id', $attempt->id)->get()->keyBy('type_id');
    }

    public function moduleStatus(?AttemptType $attemptType): string
    {
        return match (true) {
            $attemptType === null => 'not_started',
            (bool) $attemptType->is_submitted => 'submitted',
            default => 'in_progress',
        };
    }

    private function isListening(TestType $testType): bool
    {
        return $testType->type?->name === 'Listening';
    }

    private function moduleAudio(TestType $testType): ?array
    {
        if (! $this->isListening($testType) || ! $this->audio->absolutePath($testType->test?->audio_path)) {
            return null;
        }

        $playtime = $testType->test->playtime_seconds;

        return [
            'url' => route('api.v1.exam.audio.test', $testType->test_id),
            'duration_seconds' => $playtime ? (int) round((float) $playtime) : null,
        ];
    }

    private function audioEntry(string $key, ?string $storedPath, string $url): ?array
    {
        $path = $this->audio->absolutePath($storedPath);
        if (! $path) {
            return null;
        }

        $size = filesize($path);
        $sha256 = Cache::rememberForever(
            'desktop-audio-sha256:'.sha1($path.'|'.$size.'|'.filemtime($path)),
            fn () => hash_file('sha256', $path),
        );

        return ['key' => $key, 'url' => $url, 'size' => $size, 'sha256' => $sha256];
    }

    /**
     * Absolute URLs of every image referenced by the parts' HTML.
     *
     * @param  Collection<int, Part>  $parts
     */
    private function images(Collection $parts): array
    {
        $html = [];
        foreach ($parts as $part) {
            $html[] = $part->textarea;
            foreach ($part->sections as $section) {
                $html[] = $section->textarea;
                foreach ($section->options as $option) {
                    $html[] = $option->textarea;
                }
                foreach ($section->questions as $question) {
                    $html[] = $question->textarea;
                    foreach ($question->options as $option) {
                        $html[] = $option->textarea;
                    }
                }
            }
        }

        $urls = [];
        foreach (array_filter($html) as $fragment) {
            if (preg_match_all('/<img\b[^>]*\bsrc\s*=\s*["\']([^"\']+)["\']/i', $fragment, $matches)) {
                foreach ($matches[1] as $src) {
                    $src = preg_replace('#^(\.\./)+#', '/', html_entity_decode(trim($src)));
                    if ($src === '' || str_starts_with($src, 'data:')) {
                        continue;
                    }
                    $urls[] = preg_match('#^https?://#i', $src) ? $src : url('/'.ltrim($src, '/'));
                }
            }
        }

        return array_values(array_unique($urls));
    }

    private function iso($value): ?string
    {
        return $value ? Carbon::parse($value)->toIso8601String() : null;
    }
}
