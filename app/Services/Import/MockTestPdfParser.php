<?php

namespace App\Services\Import;

use App\Services\OpenAIService;
use InvalidArgumentException;

/**
 * Text of a Listening / Reading paper (+ answer key text) -> normalised parts via the AI.
 * One AI call per module; a long Reading paper is split into one call per passage so each
 * response stays well inside the model's output limit.
 */
class MockTestPdfParser
{
    public const MODULES = ['Listening', 'Reading'];

    /** Above this many characters a Reading paper is parsed passage by passage. */
    public const SPLIT_THRESHOLD = 12000;

    public function __construct(
        private readonly OpenAIService $ai,
        private readonly MockImportNormalizer $normalizer,
    ) {}

    /**
     * @return array{parts: array<int, array<string, mixed>>, warnings: array<int, string>, questions: int}
     */
    public function parse(string $module, string $text, string $answerKeyText = ''): array
    {
        if (! in_array($module, self::MODULES, true)) {
            throw new InvalidArgumentException("PDF import supports Listening and Reading only, not {$module}.");
        }

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
}
