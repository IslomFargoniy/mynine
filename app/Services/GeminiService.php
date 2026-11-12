<?php

namespace App\Services;

use App\Services\Import\AiOutputTruncatedException;
use App\Services\Import\AiRateLimitException;
use App\Support\AiUsage;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Http\Client\RequestException;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Sleep;
use RuntimeException;

/**
 * Google Gemini (generativelanguage REST API) for the Mock Bank "Import from PDF".
 *
 * The question paper and the answer key go to the model as PDF files (inline base64, or the Files API
 * for big files), so it sees the real layout: option lists, tables, gap-fill blocks and two-column
 * forms that plain text extraction breaks. The JSON it returns has the same shape as
 * OpenAIService::parseMockModule and goes through App\Services\Import\MockImportNormalizer.
 */
class GeminiService
{
    public const BASE_URL = 'https://generativelanguage.googleapis.com';

    /** Raw bytes above which a file is uploaded with the Files API (base64 grows 4/3, request limit 20 MB). */
    public const INLINE_LIMIT = 14 * 1024 * 1024;

    /** Waits (ms) before the in-request retries of a 5xx / connection error. */
    public const RETRY_DELAYS = [3000, 10000, 30000];

    public const QUESTION_TYPES = ['multiple_choice', 'multiple_response', 'true_false', 'yes_no', 'fill_blank', 'matching', 'complete_section', 'drag_and_drop'];

    public static function configured(): bool
    {
        return trim((string) config('services.gemini.key')) !== '';
    }

    public function model(): string
    {
        return (string) config('services.gemini.import_model', 'gemini-3.5-flash');
    }

    /**
     * Request part for a file: inline base64 data, or a Files API reference for big files.
     *
     * @return array<string, mixed>
     */
    public function filePart(string $path, string $mimeType = 'application/pdf'): array
    {
        $size = @filesize($path);
        if ($size === false) {
            throw new RuntimeException('The uploaded file could not be read.');
        }

        if ($size > self::INLINE_LIMIT) {
            return $this->uploadFile($path, $mimeType);
        }

        return ['inline_data' => ['mime_type' => $mimeType, 'data' => base64_encode((string) file_get_contents($path))]];
    }

    /**
     * Files API (resumable upload); the file is kept by Google for 48 hours.
     *
     * @return array<string, mixed>
     */
    public function uploadFile(string $path, string $mimeType = 'application/pdf'): array
    {
        $start = $this->http(120)
            ->withHeaders([
                'X-Goog-Upload-Protocol' => 'resumable',
                'X-Goog-Upload-Command' => 'start',
                'X-Goog-Upload-Header-Content-Length' => (string) filesize($path),
                'X-Goog-Upload-Header-Content-Type' => $mimeType,
            ])
            ->post(self::BASE_URL.'/upload/v1beta/files', ['file' => ['display_name' => basename($path)]]);
        $this->guard($start);

        $uploadUrl = $start->header('X-Goog-Upload-URL');
        if ($uploadUrl === '') {
            throw new RuntimeException('Gemini did not return an upload URL for the file.');
        }

        $done = $this->http(300)
            ->withHeaders(['X-Goog-Upload-Offset' => '0', 'X-Goog-Upload-Command' => 'upload, finalize'])
            ->withBody((string) file_get_contents($path), $mimeType)
            ->post($uploadUrl);
        $this->guard($done);

        $file = (array) $done->json('file');
        for ($i = 0; ($file['state'] ?? 'ACTIVE') === 'PROCESSING' && $i < 30; $i++) {
            Sleep::for(2)->seconds();
            $file = (array) $this->http(60)->get(self::BASE_URL.'/v1beta/'.$file['name'])->json();
        }

        if (($file['state'] ?? 'ACTIVE') !== 'ACTIVE' || empty($file['uri'])) {
            throw new RuntimeException('Gemini could not process the uploaded file ('.($file['state'] ?? 'no state').').');
        }

        return ['file_data' => ['mime_type' => $mimeType, 'file_uri' => $file['uri']]];
    }

    /**
     * Parse one Listening / Reading module (or one Reading passage, or only some question numbers).
     *
     * @param  array<int, array<string, mixed>>  $paper  request parts of the question paper (a PDF part, or a text part)
     * @param  array<int, array<string, mixed>>  $answerKey  request parts of the answer key ([] when none was uploaded)
     * @param  array<int, int>  $onlyNumbers  follow-up call: return only these question numbers
     * @return array<string, mixed> {"parts": [...], "answers": {"1": "..."}}
     */
    public function parseMockModule(string $module, array $paper, array $answerKey, string $scope, array $onlyNumbers = []): array
    {
        $parts = [['text' => "QUESTION PAPER ({$module}):"], ...$paper];
        if ($answerKey !== []) {
            $parts = [...$parts, ['text' => 'ANSWER KEY (may contain both Listening and Reading):'], ...$answerKey];
        }
        $parts[] = ['text' => $this->prompt($module, $scope, $answerKey !== [], $onlyNumbers)];

        $decoded = $this->generateJson($parts, self::moduleSchema());

        // The schema returns answers as a list (JSON schema objects cannot have numeric keys); the normalizer wants a map.
        $answers = [];
        foreach ((array) ($decoded['answers'] ?? []) as $key => $entry) {
            if (is_array($entry) && isset($entry['number'])) {
                $answers[(string) (int) $entry['number']] = (string) ($entry['answer'] ?? '');
            } elseif (! is_array($entry)) {
                $answers[(string) $key] = (string) $entry;
            }
        }
        $decoded['answers'] = $answers;

        return $decoded;
    }

    /**
     * Parse a Writing paper (Task 1 + Task 2). The response says where Task 1's picture is, so the
     * importer can cut it out of the PDF (MockTestPdfParser::parseWriting).
     *
     * @param  array<int, array<string, mixed>>  $paper  request parts of the question paper
     * @return array<string, mixed> {"tasks": [{number, page, minutes, min_words, prompt_html, visual_kind, visual_description, visual_box}]}
     */
    public function parseWritingPaper(array $paper): array
    {
        $prompt = <<<'EOT'
Convert the attached IELTS Writing question paper into JSON for a test database. A Writing paper has exactly two tasks: Task 1 (Academic: a graph / chart / table / map / process diagram to describe; General Training: a letter to write) and Task 2 (an essay).

Return ONE JSON object with "tasks": a list with one object per task, in order, with:
- "number": 1 or 2.
- "page": the 1-based page number of the PDF on which this task (for Task 1: its graph / chart / table / map / diagram) is printed. Count every page of the file, including cover pages.
- "minutes": the time the paper gives for the task ("You should spend about 20 minutes on this task." -> 20).
- "min_words": the minimum number of words ("Write at least 150 words." -> 150).
- "prompt_html": the task text exactly as printed, word for word, as clean HTML (<p> per paragraph, <strong>/<em> as printed, <ul><li> for bullet points of a letter task). Include the description of the visual or the situation, the instruction ("Summarise the information by selecting and reporting the main features, and make comparisons where relevant.", "Write a letter...", the bullet points, "Begin your letter as follows: Dear ...,") and for Task 2 the topic / question and the closing instruction ("Give reasons for your answer and include any relevant examples from your own knowledge or experience."). Keep the paper's reading order even when the PDF text is laid out out of order. Do NOT include the "WRITING TASK N" heading, the "You should spend about N minutes on this task." line, the "Write at least N words." line, page numbers, cover-page instructions or copyright lines. Do not describe the picture in this text.
- "visual_kind": for Task 1: "line_graph", "bar_chart", "pie_chart", "table", "map", "process_diagram", "mixed" (several charts), "letter" (General Training letter task, no picture) or "other"; for Task 2: "none".
- "visual_description": for a Task 1 picture, a factual alt text of 1-3 sentences (what is shown, axes / categories / units, time span, labelled stages or places) that lets someone who cannot see the picture understand it; do not interpret trends beyond what is labelled. "" for a letter and for Task 2.
- "visual_box": for a Task 1 picture, its bounding box on that page as [ymin, xmin, ymax, xmax] in 0-1000 page coordinates (0,0 = top-left corner of the page), covering the whole picture with its title, legend, axis labels and key but not the task text above it; [] when there is no picture.
EOT;

        $decoded = $this->generateJson([['text' => 'QUESTION PAPER (Writing):'], ...$paper, ['text' => $prompt]], self::writingSchema());

        if (! isset($decoded['tasks']) || ! is_array($decoded['tasks'])) {
            throw new RuntimeException('The AI response has no "tasks" list.');
        }

        return $decoded;
    }

    /**
     * @return array<string, mixed>
     */
    public static function writingSchema(): array
    {
        $task = [
            'type' => 'OBJECT',
            'properties' => [
                'number' => ['type' => 'INTEGER'],
                'page' => ['type' => 'INTEGER'],
                'minutes' => ['type' => 'INTEGER'],
                'min_words' => ['type' => 'INTEGER'],
                'prompt_html' => ['type' => 'STRING'],
                'visual_kind' => ['type' => 'STRING', 'enum' => ['line_graph', 'bar_chart', 'pie_chart', 'table', 'map', 'process_diagram', 'mixed', 'letter', 'other', 'none']],
                'visual_description' => ['type' => 'STRING'],
                'visual_box' => ['type' => 'ARRAY', 'items' => ['type' => 'NUMBER']],
            ],
            'required' => ['number', 'page', 'minutes', 'min_words', 'prompt_html', 'visual_kind', 'visual_description', 'visual_box'],
            'propertyOrdering' => ['number', 'page', 'minutes', 'min_words', 'prompt_html', 'visual_kind', 'visual_description', 'visual_box'],
        ];

        return [
            'type' => 'OBJECT',
            'properties' => ['tasks' => ['type' => 'ARRAY', 'items' => $task]],
            'required' => ['tasks'],
        ];
    }

    /**
     * One generateContent call with JSON output.
     *
     * @param  array<int, array<string, mixed>>  $parts
     * @param  array<string, mixed>|null  $schema
     * @return array<string, mixed>
     */
    public function generateJson(array $parts, ?array $schema = null): array
    {
        $generationConfig = array_filter([
            'temperature' => 0,
            'responseMimeType' => 'application/json',
            'responseSchema' => $schema,
            'maxOutputTokens' => (int) config('services.gemini.import_max_tokens', 65536),
        ], fn ($v) => $v !== null);

        if ($thinking = config('services.gemini.import_thinking')) {
            $generationConfig['thinkingConfig'] = ['thinkingLevel' => (string) $thinking];
        }

        $payload = [
            'systemInstruction' => ['parts' => [['text' => 'You are a meticulous IELTS test digitiser. You copy content faithfully from the attached documents and return only valid JSON in the requested schema.']]],
            'contents' => [['role' => 'user', 'parts' => $parts]],
            'generationConfig' => $generationConfig,
        ];

        try {
            $response = $this->http((int) config('services.gemini.import_timeout', 300))
                ->retry(self::RETRY_DELAYS, when: fn ($e) => $e instanceof ConnectionException
                    || ($e instanceof RequestException && $e->response->serverError()), throw: false)
                ->post(self::BASE_URL.'/v1beta/models/'.rawurlencode($this->model()).':generateContent', $payload);
        } catch (ConnectionException $e) {
            throw new RuntimeException('Could not reach Google Gemini: '.$e->getMessage(), 0, $e);
        }

        $this->guard($response);
        $this->recordUsage($response);

        if ($blocked = $response->json('promptFeedback.blockReason')) {
            throw new RuntimeException("Gemini refused the document ({$blocked}).");
        }

        $candidate = (array) $response->json('candidates.0');
        $finish = (string) ($candidate['finishReason'] ?? '');
        if ($finish === 'MAX_TOKENS') {
            throw new AiOutputTruncatedException('The AI response was cut off (too long). Split the PDF into smaller files.');
        }
        if ($candidate === [] || ($finish !== 'STOP' && $finish !== '')) {
            throw new RuntimeException('Gemini stopped without a result (finish reason: '.($finish ?: 'none').
                ($finish === 'RECITATION' ? ' — it refused to copy the text verbatim; try again or use the OpenAI provider' : '').').');
        }

        $text = '';
        foreach ((array) ($candidate['content']['parts'] ?? []) as $part) {
            if (is_array($part) && empty($part['thought']) && isset($part['text'])) {
                $text .= $part['text'];
            }
        }

        $text = preg_replace('/^\s*```(?:json)?\s*|\s*```\s*$/', '', $text);
        $decoded = json_decode((string) $text, true);
        if (! is_array($decoded)) {
            throw new RuntimeException('The AI did not return valid JSON.');
        }

        return $decoded;
    }

    /**
     * Token counts of a (billed) generateContent response -> ai_usage_logs. Thinking tokens are billed as output.
     */
    private function recordUsage(Response $response): void
    {
        $usage = (array) $response->json('usageMetadata');

        app(AiUsage::class)->record(
            'gemini',
            (string) ($response->json('modelVersion') ?: $this->model()),
            (int) ($usage['promptTokenCount'] ?? 0),
            (int) ($usage['candidatesTokenCount'] ?? 0) + (int) ($usage['thoughtsTokenCount'] ?? 0),
        );
    }

    /**
     * Error responses -> exceptions; 429 (and a 5xx that outlived the retries) can be retried later by the job.
     */
    private function guard(Response $response): void
    {
        if ($response->successful()) {
            return;
        }

        $status = $response->status();
        $message = (string) ($response->json('error.message') ?? '');
        $reason = (string) ($response->json('error.status') ?? '');

        if ($status === 429 || $reason === 'RESOURCE_EXHAUSTED') {
            throw new AiRateLimitException('Gemini quota or rate limit hit (429 RESOURCE_EXHAUSTED)'.($message !== '' ? ': '.mb_substr($message, 0, 300) : '.'), 'gemini', 429);
        }

        if ($response->serverError()) {
            throw new AiRateLimitException("Gemini is unavailable or overloaded ({$status})".($message !== '' ? ': '.mb_substr($message, 0, 300) : '.'), 'gemini', $status);
        }

        throw new RuntimeException("Gemini API error {$status}".($reason !== '' ? " {$reason}" : '').($message !== '' ? ': '.mb_substr($message, 0, 300) : '.'));
    }

    private function http(int $timeout): PendingRequest
    {
        return Http::withHeaders(['x-goog-api-key' => (string) config('services.gemini.key')])
            ->acceptJson()
            ->connectTimeout(30)
            ->timeout($timeout);
    }

    /**
     * @param  array<int, int>  $onlyNumbers
     */
    private function prompt(string $module, string $scope, bool $hasKey, array $onlyNumbers): string
    {
        $reading = $module === 'Reading';
        $total = $reading ? 'a full Reading paper has 3 passages (one part per passage, named "Passage 1", "Passage 2", "Passage 3") and questions 1-40' : 'a full Listening paper has 4 parts (named "Part 1" ... "Part 4") and questions 1-40';

        $passageRule = $reading
            ? '- "passage_html": the COMPLETE reading passage of that part as clean HTML (<h3> for the title, <p> per paragraph; keep paragraph letters such as "A", "B" at the start of their paragraph as <strong>A</strong>). Copy every sentence word for word — do not shorten, summarise or correct it. Do not include the questions.'
            : '- "passage_html": always "" for Listening.';

        if ($onlyNumbers !== []) {
            $list = implode(', ', $onlyNumbers);
            $focus = <<<EOT
FOLLOW-UP REQUEST: an earlier pass missed questions {$list}. Return ONLY the task sections that contain these question numbers (with their full instructions, option lists and content), inside the part / passage they belong to ("name" as above). Use "passage_html": "" (the passage is already stored). Include "answers" only for these numbers.
EOT;
        } else {
            $focus = "Process {$scope}. {$total}. EVERY question number in that range must appear exactly once — go through the paper task by task and check that no numbered question or gap is skipped (gap-fill summaries, notes, tables, flow-charts and forms count: each numbered gap is a question).";
        }

        $keyRule = $hasKey
            ? 'Take the answers ONLY from the attached ANSWER KEY (never guess or solve the questions). Use only its '.$module.' section; Reading and Listening both number their questions from 1.'
            : 'No separate answer key was uploaded. If the question paper itself contains an answer key (usually at the end) use it; otherwise return "answers": [].';

        return <<<EOT
Convert the attached IELTS {$module} question paper into JSON for a test database. Read the PDF layout carefully: tables, two-column forms, boxes of options and gap-fill blocks.
{$focus}

Return ONE JSON object with:
- "answers": list of {"number": N, "answer": "..."} for the question numbers you return.
- "parts": list of parts in paper order. Each part: "name", "passage_html", "sections" (the tasks of that part in paper order).

Rules for "parts":
- "name": "Part N" for Listening, "Passage N" for Reading.
{$passageRule}
- Each section is one task ("Questions 14-18 ..."). Fields: "question_type", "instructions_html", "content_html", "from_option", "to_option", "options", "questions".
- "question_type" is one of: multiple_choice, multiple_response, true_false, yes_no, fill_blank, matching, complete_section, drag_and_drop.
- "instructions_html": the task heading and instructions ("<p><strong>Questions 1-10</strong></p><p>Complete the notes below.</p><p>Write ONE WORD AND/OR A NUMBER for each answer.</p>"), plus for matching tasks the full list / box of options with their letters or roman numerals ("<ul><li>A doesn't have a long wait</li>...</ul>"). Clean HTML only: <p>, <strong>, <em>, <ul><li>, <table>.
- Question "text" is plain text without the question number. Ignore cover pages, candidate instructions, page numbers, copyright lines and already answered "Example" rows.

How to model each task:
- Notes / form / table / flow-chart / summary / sentence completion where the gaps are inside a block of text: "complete_section". Put the whole block (title, labels, bullet points, table rows) in "content_html" as clean HTML and write each gap as the marker [[N]] (N = its question number), e.g. "<p>Phone number: [[1]] (mobile)</p>". Drop the dotted lines and the printed gap number. For two-column forms put each label next to its value. "questions": one {"numbers":[N],"text":"","options":[]} per gap, in order. Every gap of the block needs its [[N]] marker in "content_html".
- Separate sentences, each with one gap: "fill_blank"; "text" is the sentence with the gap written as [[N]].
- Choose ONE letter (A, B, C or D): "multiple_choice"; "text" = the question stem; "options" = ALL option texts WITHOUT their letters, in order.
- Choose TWO (or THREE) letters from a list (e.g. "Choose TWO letters, A-E" for questions 27 and 28): "multiple_response"; ONE question whose "numbers" lists all its numbers (e.g. [27, 28]); "text" = the question; "options" = ALL the listed option texts (e.g. the five texts A-E) without letters. Never leave "options" empty.
- TRUE / FALSE / NOT GIVEN: "true_false"; YES / NO / NOT GIVEN: "yes_no"; one question per statement, "text" = the statement, "options": [].
- Matching (information to paragraphs, headings, features, people, places on a map/plan, sentence endings, "choose answers from the box and write the letter"): "matching"; "from_option"/"to_option" = first and last option letter (e.g. "A" and "G"; roman numerals "i"/"x" for heading lists); the full option list goes into "instructions_html"; one question per numbered item, "text" = the item.
- Summary completion with a box of words/phrases labelled with letters: "drag_and_drop"; "content_html" with [[N]] markers like complete_section; "options" = the box items without letters, in box order.
- "from_option"/"to_option" are null except for matching. Section "options" is [] except for drag_and_drop.

Rules for "answers":
- {$keyRule}
- Copy each answer exactly as printed. If the key's text lost its spaces, restore only the spaces between separate words ("visualmemory" -> "visual memory", "NOTGIVEN" -> "NOT GIVEN"); never split a single or compound word ("firewood", "weight-training" stay as they are). Keep alternatives separated by "/" ("gray/grey") and optional words in round brackets ("(migration) direction").
- Letters stay single letters ("C"); TRUE/FALSE/NOT GIVEN and YES/NO/NOT GIVEN as written.
- "27&28 in either order: A, C" means {"number":27,"answer":"A"}, {"number":28,"answer":"C"}. Keys sometimes print the wrong numbers for the second either-order pair (e.g. "27&28" twice); assign each pair, in order, to the next choose-TWO question of the paper (e.g. 29 and 30).
EOT;
    }

    /**
     * Gemini responseSchema (OpenAPI subset) of a module response.
     *
     * @return array<string, mixed>
     */
    public static function moduleSchema(): array
    {
        $strings = ['type' => 'ARRAY', 'items' => ['type' => 'STRING']];

        $question = [
            'type' => 'OBJECT',
            'properties' => [
                'numbers' => ['type' => 'ARRAY', 'items' => ['type' => 'INTEGER']],
                'text' => ['type' => 'STRING'],
                'options' => $strings,
            ],
            'required' => ['numbers', 'text', 'options'],
            'propertyOrdering' => ['numbers', 'text', 'options'],
        ];

        $section = [
            'type' => 'OBJECT',
            'properties' => [
                'question_type' => ['type' => 'STRING', 'enum' => self::QUESTION_TYPES],
                'instructions_html' => ['type' => 'STRING'],
                'content_html' => ['type' => 'STRING'],
                'from_option' => ['type' => 'STRING', 'nullable' => true],
                'to_option' => ['type' => 'STRING', 'nullable' => true],
                'options' => $strings,
                'questions' => ['type' => 'ARRAY', 'items' => $question],
            ],
            'required' => ['question_type', 'instructions_html', 'content_html', 'options', 'questions'],
            'propertyOrdering' => ['question_type', 'instructions_html', 'content_html', 'from_option', 'to_option', 'options', 'questions'],
        ];

        $part = [
            'type' => 'OBJECT',
            'properties' => [
                'name' => ['type' => 'STRING'],
                'passage_html' => ['type' => 'STRING'],
                'sections' => ['type' => 'ARRAY', 'items' => $section],
            ],
            'required' => ['name', 'passage_html', 'sections'],
            'propertyOrdering' => ['name', 'passage_html', 'sections'],
        ];

        return [
            'type' => 'OBJECT',
            'properties' => [
                'answers' => ['type' => 'ARRAY', 'items' => [
                    'type' => 'OBJECT',
                    'properties' => ['number' => ['type' => 'INTEGER'], 'answer' => ['type' => 'STRING']],
                    'required' => ['number', 'answer'],
                    'propertyOrdering' => ['number', 'answer'],
                ]],
                'parts' => ['type' => 'ARRAY', 'items' => $part],
            ],
            'required' => ['answers', 'parts'],
            'propertyOrdering' => ['answers', 'parts'],
        ];
    }
}
