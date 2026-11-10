<?php

namespace App\Services\Import;

use App\Services\GeminiService;
use App\Services\OpenAIService;
use InvalidArgumentException;

/**
 * A Listening / Reading paper (+ answer key) -> normalised parts via the AI.
 *
 * Provider "gemini" (config services.mock_import.provider): the PDFs go to Gemini as files, so the
 * model sees the layout; .docx / .txt uploads are sent as extracted text. One call per module (a
 * Reading paper whose answer is cut off is re-done passage by passage), then one follow-up call for
 * question numbers that are still missing.
 *
 * Provider "openai": text extracted with smalot/pdfparser goes to gpt-4o, one call per module; a
 * long Reading paper is split into one call per passage so each response stays well inside the
 * model's output limit.
 */
class MockTestPdfParser
{
    public const MODULES = ['Listening', 'Reading'];

    /** Above this many characters a Reading paper is parsed passage by passage. */
    public const SPLIT_THRESHOLD = 12000;

    public function __construct(
        private readonly OpenAIService $ai,
        private readonly MockImportNormalizer $normalizer,
        private readonly GeminiService $gemini,
        private readonly DocumentTextExtractor $extractor,
    ) {}

    public static function provider(): string
    {
        return config('services.mock_import.provider') === 'gemini' ? 'gemini' : 'openai';
    }

    /**
     * Parse uploaded files (paper + optional answer key) with the configured provider.
     *
     * @return array{parts: array<int, array<string, mixed>>, warnings: array<int, string>, questions: int, numbers: array<int, int>}
     */
    public function parseFiles(string $module, string $paperPath, ?string $answersPath = null, ?string $provider = null): array
    {
        $this->assertModule($module);

        if (($provider ?? self::provider()) !== 'gemini') {
            $answers = $answersPath !== null ? $this->extractor->extract($answersPath) : '';

            return $this->parse($module, $this->extractor->extract($paperPath), $answers);
        }

        $paper = $this->geminiDocument($paperPath);
        $key = $answersPath !== null ? $this->geminiDocument($answersPath) : [];

        try {
            $responses = [$this->gemini->parseMockModule($module, $paper, $key, "the whole {$module} paper")];
        } catch (AiOutputTruncatedException $e) {
            if ($module !== 'Reading') {
                throw $e;
            }
            $responses = [];
            foreach ([1, 2, 3] as $n) {
                $responses[] = $this->gemini->parseMockModule($module, $paper, $key, "Reading Passage {$n} only (return exactly one part named \"Passage {$n}\" with the paper's own question numbers, and answers only for those numbers)");
            }
        }

        $result = $this->normalizer->normalize($module, $responses);

        $missing = $this->missing($module, $result['numbers']);
        if ($missing === []) {
            return $result;
        }

        $extra = $this->gemini->parseMockModule($module, $paper, $key, "the whole {$module} paper", $missing);
        $merged = $this->mergeMissing($responses, $extra, $missing);

        return $this->normalizer->normalize($module, [$merged]);
    }

    /**
     * Gemini request parts for one uploaded file: PDFs as files, other documents as extracted text.
     *
     * @return array<int, array<string, mixed>>
     */
    public function geminiDocument(string $path): array
    {
        if (strtolower(pathinfo($path, PATHINFO_EXTENSION)) === 'pdf') {
            return [$this->gemini->filePart($path, 'application/pdf')];
        }

        return [['text' => $this->extractor->extract($path)]];
    }

    /**
     * Expected question numbers (1-40) not covered by the parsed result.
     *
     * @param  array<int, int>  $covered
     * @return array<int, int>
     */
    public function missing(string $module, array $covered): array
    {
        $expected = MockImportNormalizer::EXPECTED_QUESTIONS[$module] ?? 0;

        return $expected > 0 ? array_values(array_diff(range(1, $expected), $covered)) : [];
    }

    /**
     * Put the sections of a follow-up response (only the missing numbers) into the parts of the first pass.
     *
     * @param  array<int, array<string, mixed>>  $responses
     * @param  array<string, mixed>  $extra
     * @param  array<int, int>  $missing
     * @return array<string, mixed> one combined response
     */
    public function mergeMissing(array $responses, array $extra, array $missing): array
    {
        $parts = [];
        $answers = [];
        foreach ($responses as $response) {
            array_push($parts, ...array_values(array_filter((array) ($response['parts'] ?? []), 'is_array')));
            $answers += (array) ($response['answers'] ?? []);
        }
        foreach ((array) ($extra['answers'] ?? []) as $number => $answer) {
            $answers[$number] ??= $answer;
        }

        foreach ((array) ($extra['parts'] ?? []) as $extraPart) {
            if (! is_array($extraPart)) {
                continue;
            }
            foreach ((array) ($extraPart['sections'] ?? []) as $section) {
                if (! is_array($section) || array_intersect($this->sectionNumbers($section), $missing) === []) {
                    continue;
                }
                $target = $this->targetPart($parts, (string) ($extraPart['name'] ?? ''), min($this->sectionNumbers($section)));
                if ($target === null) {
                    $parts[] = ['name' => (string) ($extraPart['name'] ?? ''), 'passage_html' => (string) ($extraPart['passage_html'] ?? ''), 'sections' => [$section]];

                    continue;
                }
                $parts[$target]['sections'][] = $section;
            }
        }

        foreach ($parts as &$part) {
            $sections = array_values(array_filter((array) ($part['sections'] ?? []), 'is_array'));
            usort($sections, fn ($a, $b) => $this->firstNumber($a) <=> $this->firstNumber($b));
            $part['sections'] = $sections;
        }
        unset($part);
        usort($parts, fn ($a, $b) => $this->firstNumber($a['sections'][0] ?? []) <=> $this->firstNumber($b['sections'][0] ?? []));

        return ['parts' => $parts, 'answers' => $answers];
    }

    /**
     * Index of the part a follow-up section belongs to: same name ("Passage 2"), else the part whose
     * numbers come right before it.
     *
     * @param  array<int, array<string, mixed>>  $parts
     */
    private function targetPart(array $parts, string $name, int $first): ?int
    {
        $key = fn (string $n) => strtolower(preg_replace('/\s+/', ' ', trim(strip_tags($n))));

        foreach ($parts as $i => $part) {
            if ($name !== '' && $key((string) ($part['name'] ?? '')) === $key($name)) {
                return $i;
            }
        }

        $best = null;
        foreach ($parts as $i => $part) {
            $start = $this->firstNumber((array) ($part['sections'][0] ?? []));
            if ($start !== PHP_INT_MAX && $start <= $first) {
                $best = $i;
            }
        }

        return $best;
    }

    /**
     * @param  array<string, mixed>  $section
     * @return array<int, int>
     */
    private function sectionNumbers(array $section): array
    {
        $numbers = [];
        foreach ((array) ($section['questions'] ?? []) as $question) {
            foreach ((array) (is_array($question) ? ($question['numbers'] ?? $question['number'] ?? []) : []) as $n) {
                $numbers[] = (int) $n;
            }
        }
        if (preg_match_all('/\[\[\s*(\d{1,3})\s*\]\]/', (string) ($section['content_html'] ?? ''), $m)) {
            array_push($numbers, ...array_map('intval', $m[1]));
        }

        return array_values(array_unique(array_filter($numbers, fn ($n) => $n > 0)));
    }

    /**
     * @param  array<string, mixed>  $section
     */
    private function firstNumber(array $section): int
    {
        $numbers = $this->sectionNumbers($section);

        return $numbers === [] ? PHP_INT_MAX : min($numbers);
    }

    /**
     * @return array{parts: array<int, array<string, mixed>>, warnings: array<int, string>, questions: int}
     */
    public function parse(string $module, string $text, string $answerKeyText = ''): array
    {
        $this->assertModule($module);

        $responses = [];
        foreach ($this->chunks($module, $text) as $scope => $chunk) {
            $responses[] = $this->ai->parseMockModule($module, $chunk, $answerKeyText, $scope);
        }

        return $this->normalizer->normalize($module, $responses);
    }

    /**
     * @return array<string, string> scope description => text
     */
    public function chunks(string $module, string $text): array
    {
        $whole = ["the whole {$module} paper" => $text];

        if ($module !== 'Reading' || mb_strlen($text) <= self::SPLIT_THRESHOLD) {
            return $whole;
        }

        $pieces = preg_split('/(?=READING\s+PASSAGE\s*\d)/i', $text);
        $passages = array_values(array_filter($pieces, fn ($p) => preg_match('/^READING\s+PASSAGE\s*\d/i', $p)));

        if (count($passages) < 2) {
            return $whole;
        }

        $chunks = [];
        foreach ($passages as $i => $passage) {
            preg_match('/^READING\s+PASSAGE\s*(\d)/i', $passage, $m);
            $n = $m[1] ?? (string) ($i + 1);
            $chunks["Reading Passage {$n} only (it is one part of a longer paper; return exactly one part named \"Passage {$n}\" and keep the paper's own question numbers)"] = trim($passage);
        }

        return $chunks;
    }

    private function assertModule(string $module): void
    {
        if (! in_array($module, self::MODULES, true)) {
            throw new InvalidArgumentException("PDF import supports Listening and Reading only, not {$module}.");
        }
    }
}
