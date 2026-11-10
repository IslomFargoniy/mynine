<?php

namespace App\Services\Import;

use RuntimeException;

/**
 * Validates the AI JSON of a Listening / Reading module and turns it into rows in the shapes the
 * exam rooms render (web resources/js/components/practice/*, desktop ExamPayloadBuilder):
 *
 * - complete_section / drag_and_drop: gaps live in section.textarea as "{answer}" (as the section editor
 *   writes them, see SectionController::syncQuestions); one question per gap with `order` and answer_text.
 * - fill_blank: question.textarea is plain text with one "{}" input; answer_text holds the key
 *   (alternatives joined with "/").
 * - matching: section from_option/to_option (letters or roman numerals), the option list in section.textarea,
 *   question.answer_text = the letter.
 * - multiple_choice / true_false / yes_no / multiple_response: question options with is_correct
 *   (a multiple_response question covering 27-28 has two correct options and counts as two numbers).
 *
 * Answers are applied by question number from the "answers" object; nothing here trusts the AI to
 * have set is_correct itself.
 */
class MockImportNormalizer
{
    public const TYPES = ['multiple_choice', 'multiple_response', 'true_false', 'yes_no', 'fill_blank', 'matching', 'complete_section', 'drag_and_drop'];

    public const EXPECTED_QUESTIONS = ['Listening' => 40, 'Reading' => 40];

    public const EXPECTED_PARTS = ['Listening' => 4, 'Reading' => 3];

    private const ALLOWED_TAGS = '<p><br><strong><b><em><i><u><h2><h3><h4><h5><ul><ol><li><table><thead><tbody><tr><th><td><sup><sub>';

    private const MARKER = '/\[\[\s*(\d{1,3})\s*\]\]/';

    /** @var array<int, string> */
    private array $warnings = [];

    /** @var array<int, string> question number => raw answer */
    private array $answers = [];

    /** @var array<int, int> question numbers in document order */
    private array $numbers = [];

    /** @var array<int, int> numbers that have no answer */
    private array $unanswered = [];

    /**
     * @param  array<int, array<string, mixed>>  $responses  one decoded AI response per call (whole module or one passage)
     *                                                       Every normalised question also carries "numbers" (its paper question numbers; ignored by the
     *                                                       importer) and the result lists all covered numbers, for coverage checks and the dry run.
     * @return array{parts: array<int, array<string, mixed>>, warnings: array<int, string>, questions: int, numbers: array<int, int>}
     */
    public function normalize(string $module, array $responses): array
    {
        $this->warnings = [];
        $this->answers = [];
        $this->numbers = [];
        $this->unanswered = [];

        $rawParts = [];
        foreach ($responses as $response) {
            if (! is_array($response) || ! isset($response['parts']) || ! is_array($response['parts'])) {
                throw new RuntimeException('The AI response has no "parts" list.');
            }
            array_push($rawParts, ...array_values(array_filter($response['parts'], 'is_array')));

            foreach ((array) ($response['answers'] ?? []) as $number => $answer) {
                $number = (int) preg_replace('/\D/', '', (string) $number);
                $answer = is_array($answer) ? implode(',', array_map('strval', $answer)) : trim((string) $answer);
                if ($number > 0 && $answer !== '' && ! isset($this->answers[$number])) {
                    $this->answers[$number] = $answer;
                }
            }
        }

        if ($rawParts === []) {
            throw new RuntimeException('No parts were found in the document.');
        }

        $parts = [];
        foreach ($rawParts as $i => $rawPart) {
            $parts[] = $this->part($module, $rawPart, $i + 1);
        }

        $this->checkNumbers($module, count($parts));

        if ($this->unanswered !== []) {
            sort($this->unanswered);
            $this->warnings[] = 'Answers missing for questions '.$this->ranges($this->unanswered).' — add them in the module editor.';
        }

        $covered = array_values(array_unique($this->numbers));
        sort($covered);

        return ['parts' => $parts, 'warnings' => $this->warnings, 'questions' => count($this->numbers), 'numbers' => $covered];
    }

    /**
     * @param  array<string, mixed>  $raw
     * @return array<string, mixed>
     */
    private function part(string $module, array $raw, int $index): array
    {
        $default = ($module === 'Reading' ? 'Passage ' : 'Part ').$index;
        $name = trim(strip_tags((string) ($raw['name'] ?? ''))) ?: $default;

        $passage = $module === 'Reading' ? $this->html((string) ($raw['passage_html'] ?? '')) : '';
        if ($module === 'Reading' && mb_strlen(strip_tags($passage)) < 200) {
            $this->warnings[] = "{$name}: the reading passage looks empty or very short — check it in the editor.";
        }

        $sections = [];
        foreach ((array) ($raw['sections'] ?? []) as $rawSection) {
            if (is_array($rawSection) && ($section = $this->section($name, $rawSection))) {
                $sections[] = $section;
            }
        }

        if ($sections === []) {
            $this->warnings[] = "{$name}: no questions were found.";
        }

        return ['name' => mb_substr($name, 0, 255), 'textarea' => $passage, 'sections' => $sections];
    }

    /**
     * @param  array<string, mixed>  $raw
     * @return array<string, mixed>|null
     */
    private function section(string $partName, array $raw): ?array
    {
        $type = (string) ($raw['question_type'] ?? '');
        if (! in_array($type, self::TYPES, true)) {
            $fallback = ! empty($raw['content_html']) ? 'complete_section' : (! empty(($raw['questions'][0]['options'] ?? null)) ? 'multiple_choice' : 'fill_blank');
            $this->warnings[] = "{$partName}: unknown question type \"{$type}\" was imported as {$fallback} — check it.";
            $type = $fallback;
        }

        // Braces are gap markers in section texts: keep them out of the instructions.
        $instructions = str_replace(['{', '}'], ['(', ')'], $this->html((string) ($raw['instructions_html'] ?? '')));
        $rawQuestions = array_values(array_filter((array) ($raw['questions'] ?? []), 'is_array'));
        $options = array_values(array_filter(array_map(fn ($o) => $this->plain(is_array($o) ? ($o['text'] ?? $o['textarea'] ?? '') : $o), (array) ($raw['options'] ?? [])), fn ($o) => $o !== ''));

        return match ($type) {
            'complete_section', 'drag_and_drop' => $this->gapSection($partName, $type, $instructions, (string) ($raw['content_html'] ?? ''), $rawQuestions, $options),
            'matching' => $this->matchingSection($partName, $instructions, $raw, $rawQuestions),
            default => $this->questionSection($partName, $type, $instructions, $rawQuestions),
        };
    }

    /**
     * @param  array<int, array<string, mixed>>  $rawQuestions
     * @param  array<int, string>  $boxWords
     * @return array<string, mixed>|null
     */
    private function gapSection(string $partName, string $type, string $instructions, string $content, array $rawQuestions, array $boxWords): ?array
    {
        $content = $this->html(str_replace(['{', '}'], ['(', ')'], $content));

        // Gaps without markers in the content (the AI listed them only as questions) cannot be placed.
        if (! preg_match_all(self::MARKER, $content, $m)) {
            if ($rawQuestions === []) {
                return null;
            }
            $this->warnings[] = "{$partName}: a {$type} task had no gap markers and was imported as separate fill-in questions.";

            return $this->questionSection($partName, 'fill_blank', $instructions.$content, $rawQuestions);
        }

        $questions = [];
        $used = [];
        $order = 0;
        $content = preg_replace_callback(self::MARKER, function ($match) use (&$questions, &$used, &$order, $type, $boxWords) {
            $number = (int) $match[1];
            $this->numbers[] = $number;

            $answer = $type === 'drag_and_drop'
                ? $this->boxWord($number, $boxWords)
                : $this->textAnswer($number);

            if ($answer === null) {
                $this->unanswered[] = $number;
            } else {
                $used[] = mb_strtolower($answer);
            }

            $questions[] = ['order' => ++$order, 'textarea' => null, 'answer_text' => $answer, 'options' => [], 'numbers' => [$number]];

            return '{'.($answer ?? '').'}';
        }, $content);

        $distractors = $type === 'drag_and_drop'
            ? array_values(array_filter($boxWords, fn ($w) => ! in_array(mb_strtolower($w), $used, true)))
            : [];

        return [
            'question_type' => $type,
            'textarea' => $instructions.$content,
            'from_option' => null,
            'to_option' => null,
            'options' => $distractors,
            'questions' => $questions,
        ];
    }

    /**
     * @param  array<string, mixed>  $raw
     * @param  array<int, array<string, mixed>>  $rawQuestions
     * @return array<string, mixed>|null
     */
    private function matchingSection(string $partName, string $instructions, array $raw, array $rawQuestions): ?array
    {
        if ($rawQuestions === []) {
            return null;
        }

        $from = $this->rangeEnd($raw['from_option'] ?? null);
        $to = $this->rangeEnd($raw['to_option'] ?? null);

        $questions = [];
        $letters = [];
        foreach ($rawQuestions as $rawQuestion) {
            $number = $this->numbersOf($rawQuestion)[0] ?? null;
            if ($number === null) {
                continue;
            }
            $this->numbers[] = $number;

            $answer = isset($this->answers[$number]) ? $this->letter($this->answers[$number]) : null;
            if ($answer === null) {
                $this->unanswered[] = $number;
            } else {
                $letters[] = $answer;
            }

            $questions[] = ['textarea' => $this->plain($rawQuestion['text'] ?? ''), 'answer_text' => $answer, 'options' => [], 'numbers' => [$number]];
        }

        if ($from === null || $to === null) {
            $alpha = array_filter($letters, fn ($l) => preg_match('/^[A-Z]$/', $l));
            $from = 'A';
            $to = $alpha !== [] ? max($alpha) : 'A';
            $this->warnings[] = "{$partName}: matching options range was not found, set to {$from}-{$to} — check it.";
        }

        foreach ($letters as $letter) {
            if (! $this->inRange($letter, $from, $to)) {
                $this->warnings[] = "{$partName}: answer {$letter} is outside the options {$from}-{$to}.";
            }
        }

        return [
            'question_type' => 'matching',
            'textarea' => $instructions,
            'from_option' => $from,
            'to_option' => $to,
            'options' => [],
            'questions' => $questions,
        ];
    }

    /**
     * multiple_choice, multiple_response, true_false, yes_no, fill_blank.
     *
     * @param  array<int, array<string, mixed>>  $rawQuestions
     * @return array<string, mixed>|null
     */
    private function questionSection(string $partName, string $type, string $instructions, array $rawQuestions): ?array
    {
        $questions = [];

        foreach ($rawQuestions as $rawQuestion) {
            $numbers = $this->numbersOf($rawQuestion);
            if ($numbers === []) {
                continue;
            }
            if ($type !== 'multiple_response') {
                $numbers = [$numbers[0]];
            }
            array_push($this->numbers, ...$numbers);

            $text = (string) ($rawQuestion['text'] ?? $rawQuestion['textarea'] ?? '');

            $questions[] = match ($type) {
                'fill_blank' => $this->fillBlank($text, $numbers[0]),
                'true_false', 'yes_no' => $this->judgement($type, $text, $numbers[0]),
                'multiple_response' => $this->choice($partName, $type, $text, $rawQuestion, $numbers),
                default => $this->choice($partName, 'multiple_choice', $text, $rawQuestion, $numbers),
            } + ['numbers' => $numbers];
        }

        if ($questions === []) {
            return null;
        }

        return [
            'question_type' => $type,
            'textarea' => $instructions,
            'from_option' => null,
            'to_option' => null,
            'options' => [],
            'questions' => $questions,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function fillBlank(string $text, int $number): array
    {
        $text = $this->plain(str_replace(['{', '}'], ['(', ')'], $text));
        $text = preg_replace(self::MARKER, '{}', $text, 1);
        $text = preg_replace(self::MARKER, '', $text);
        $text = preg_replace('/[.…_]{4,}/u', '{}', $text, 1);
        if (! str_contains($text, '{}')) {
            $text = rtrim($text).' {}';
        }

        $answer = $this->textAnswer($number);
        if ($answer === null) {
            $this->unanswered[] = $number;
        }

        return ['textarea' => trim($text), 'answer_text' => $answer, 'options' => []];
    }

    /**
     * @return array<string, mixed>
     */
    private function judgement(string $type, string $text, int $number): array
    {
        $labels = $type === 'true_false' ? ['True', 'False', 'Not Given'] : ['Yes', 'No', 'Not Given'];

        $correct = null;
        if (isset($this->answers[$number])) {
            $key = strtoupper(preg_replace('/[^a-z]/i', '', $this->answers[$number]));
            $correct = match ($key) {
                'TRUE', 'T', 'YES', 'Y' => 0,
                'FALSE', 'F', 'NO', 'N' => 1,
                'NOTGIVEN', 'NG' => 2,
                default => null,
            };
        }
        if ($correct === null) {
            $this->unanswered[] = $number;
        }

        return [
            'textarea' => $this->plain($text),
            'answer_text' => null,
            'options' => array_map(fn ($label, $i) => ['textarea' => $label, 'is_correct' => $i === $correct], $labels, array_keys($labels)),
        ];
    }

    /**
     * @param  array<string, mixed>  $rawQuestion
     * @param  array<int, int>  $numbers
     * @return array<string, mixed>
     */
    private function choice(string $partName, string $type, string $text, array $rawQuestion, array $numbers): array
    {
        $options = array_values(array_map(
            fn ($o) => $this->plain(is_array($o) ? ($o['text'] ?? $o['textarea'] ?? '') : $o),
            (array) ($rawQuestion['options'] ?? []),
        ));
        $options = $this->stripOptionLetters($options);

        if (count($options) < 2) {
            $this->warnings[] = "{$partName}: question ".$this->ranges($numbers).' has fewer than two options — check it.';
        }

        $correct = [];
        foreach ($numbers as $number) {
            if (! isset($this->answers[$number])) {
                $this->unanswered[] = $number;

                continue;
            }
            foreach ($this->optionIndexes($this->answers[$number], $options) as $index) {
                $correct[$index] = true;
            }
        }

        if ($type === 'multiple_response' && $correct !== [] && count($correct) !== count($numbers)) {
            $this->warnings[] = "{$partName}: questions ".$this->ranges($numbers).' need '.count($numbers).' correct options, the key gives '.count($correct).'.';
        } elseif ($type === 'multiple_choice' && $correct === [] && isset($this->answers[$numbers[0]])) {
            $this->unanswered[] = $numbers[0];
        }

        return [
            'textarea' => $this->plain($text),
            'answer_text' => null,
            'options' => array_map(fn ($label, $i) => ['textarea' => $label, 'is_correct' => isset($correct[$i])], $options, array_keys($options)),
        ];
    }

    /**
     * Option indexes named by an answer: letters ("C", "A, C", "A and C") or the option text itself.
     *
     * @param  array<int, string>  $options
     * @return array<int, int>
     */
    private function optionIndexes(string $answer, array $options): array
    {
        $answer = trim($answer);

        if (preg_match('/^[A-Ha-h]([\s,;&\/]+(and\s+)?[A-Ha-h])*\.?$/', $answer)) {
            preg_match_all('/[A-Ha-h]/', preg_replace('/\band\b/i', '', $answer), $m);

            return array_values(array_filter(
                array_map(fn ($l) => ord(strtoupper($l)) - 65, $m[0]),
                fn ($i) => $i < count($options),
            ));
        }

        foreach ($options as $i => $option) {
            if (mb_strtolower($option) === mb_strtolower($answer)) {
                return [$i];
            }
        }

        return [];
    }

    /**
     * Options printed as "A massage", "B) ultrasound", … lose their letters (the exam rooms add them).
     *
     * @param  array<int, string>  $options
     * @return array<int, string>
     */
    private function stripOptionLetters(array $options): array
    {
        $all = $options !== [];
        foreach ($options as $i => $option) {
            if (! preg_match('/^'.chr(65 + $i).'(\s+|[.)]\s*)\S/', $option)) {
                $all = false;
            }
        }

        return $all
            ? array_map(fn ($o) => preg_replace('/^[A-Z](\s+|[.)]\s*)/', '', $o), $options)
            : $options;
    }

    private function boxWord(int $number, array $boxWords): ?string
    {
        if (! isset($this->answers[$number])) {
            return null;
        }

        $answer = trim($this->answers[$number]);
        if (preg_match('/^[A-Za-z]$/', $answer) && isset($boxWords[ord(strtoupper($answer)) - 65])) {
            return $this->gapSafe($boxWords[ord(strtoupper($answer)) - 65]);
        }

        return $this->textAnswer($number);
    }

    /**
     * Text answer with alternatives joined by "/": "gray/grey", "(migration) direction" ->
     * "migration direction/direction".
     */
    private function textAnswer(int $number): ?string
    {
        if (! isset($this->answers[$number])) {
            return null;
        }

        $variants = [];
        foreach (preg_split('/\s*[\/|]\s*|\s+\bOR\b\s+/', $this->answers[$number]) as $alternative) {
            foreach ($this->expandOptional($alternative) as $variant) {
                $variant = $this->gapSafe($variant);
                if ($variant !== '' && ! in_array(mb_strtolower($variant), array_map('mb_strtolower', $variants), true)) {
                    $variants[] = $variant;
                }
            }
        }

        return $variants === [] ? null : mb_substr(implode('/', $variants), 0, 255);
    }

    /**
     * @return array<int, string>
     */
    private function expandOptional(string $text): array
    {
        if (! preg_match('/\(([^()]*)\)/', $text, $m, PREG_OFFSET_CAPTURE)) {
            return [$text];
        }

        $before = substr($text, 0, $m[0][1]);
        $after = substr($text, $m[0][1] + strlen($m[0][0]));

        return array_merge(
            $this->expandOptional($before.$m[1][0].$after),
            $this->expandOptional($before.$after),
        );
    }

    private function gapSafe(string $text): string
    {
        return trim(preg_replace('/\s+/u', ' ', str_replace(['{', '}', '<', '>'], '', $text)));
    }

    private function letter(string $answer): ?string
    {
        $answer = strtoupper(trim($answer, " .\t\n"));

        return preg_match('/^([A-Z]|[IVXLC]+)$/', $answer) ? $answer : null;
    }

    private function rangeEnd(mixed $value): ?string
    {
        $value = strtoupper(trim((string) $value));

        return preg_match('/^([A-Z]|[IVXLC]+)$/', $value) ? $value : null;
    }

    private function inRange(string $letter, string $from, string $to): bool
    {
        if (strlen($from) === 1 && strlen($to) === 1 && strlen($letter) === 1) {
            return $letter >= $from && $letter <= $to;
        }

        return true;
    }

    /**
     * @param  array<string, mixed>  $rawQuestion
     * @return array<int, int>
     */
    private function numbersOf(array $rawQuestion): array
    {
        $numbers = $rawQuestion['numbers'] ?? ($rawQuestion['number'] ?? []);

        return array_values(array_filter(array_map('intval', (array) $numbers), fn ($n) => $n > 0));
    }

    private function checkNumbers(string $module, int $partCount): void
    {
        $numbers = $this->numbers;
        $count = count($numbers);

        $duplicates = array_keys(array_filter(array_count_values($numbers), fn ($c) => $c > 1));
        if ($duplicates !== []) {
            $this->warnings[] = 'Duplicate question numbers: '.$this->ranges($duplicates).'.';
        }

        $unique = array_values(array_unique($numbers));
        if ($unique !== []) {
            $missing = array_values(array_diff(range(1, max($unique)), $unique));
            if ($missing !== []) {
                $this->warnings[] = 'Question numbers missing: '.$this->ranges($missing).'.';
            }

            $sorted = $unique;
            sort($sorted);
            if ($sorted !== $unique) {
                $this->warnings[] = 'Questions are not in number order — check the order of sections.';
            }
        }

        $expected = self::EXPECTED_QUESTIONS[$module] ?? null;
        if ($expected !== null && $count !== $expected) {
            $this->warnings[] = "Found {$count} questions; a full {$module} paper has {$expected}.";
        }

        $expectedParts = self::EXPECTED_PARTS[$module] ?? null;
        if ($expectedParts !== null && $partCount !== $expectedParts) {
            $this->warnings[] = "Found {$partCount} parts; a full {$module} paper has {$expectedParts}.";
        }
    }

    /**
     * @param  array<int, int>  $numbers
     */
    private function ranges(array $numbers): string
    {
        $numbers = array_values(array_unique($numbers));
        sort($numbers);

        $out = [];
        $start = $prev = null;
        foreach ($numbers as $n) {
            if ($start === null) {
                $start = $prev = $n;
            } elseif ($n === $prev + 1) {
                $prev = $n;
            } else {
                $out[] = $start === $prev ? (string) $start : "{$start}-{$prev}";
                $start = $prev = $n;
            }
        }
        if ($start !== null) {
            $out[] = $start === $prev ? (string) $start : "{$start}-{$prev}";
        }

        return implode(', ', $out);
    }

    private function plain(mixed $text): string
    {
        $text = html_entity_decode(strip_tags((string) $text), ENT_QUOTES | ENT_HTML5, 'UTF-8');

        return trim(preg_replace('/\s+/u', ' ', $text));
    }

    /**
     * Clean HTML: a small tag allow-list, no attributes (no styles, scripts or event handlers).
     */
    private function html(string $html): string
    {
        $html = preg_replace('#<(script|style)\b[^>]*>.*?</\1>#is', '', $html);
        $html = strip_tags($html, self::ALLOWED_TAGS);
        $html = preg_replace('#<(/?)(\w+)\b[^>]*?(/?)>#', '<$1$2$3>', $html);

        return trim($html);
    }
}
