<?php

namespace App\Services\Import;

use RuntimeException;
use Throwable;

/**
 * The AI JSON of a Writing paper (GeminiService::parseWritingPaper) -> two parts "Task 1" / "Task 2",
 * each with one essay section and one essay question, laid out like Writing made in the module editor:
 *
 * - part.textarea: what the candidate reads in the exam rooms (web practice-part.tsx, desktop part html):
 *   heading, the official time line, the task text, the word minimum and the Task 1 picture.
 * - section.textarea: the task text + picture (+ a description of the picture for the examiner); the AI
 *   essay evaluation (EvaluateEssayJob) and the Writing review page read it.
 * - question: order 1, no text, no answer. Part order gives the task order (MockResultService::writingTaskBands,
 *   Task 2 counts double) and the 150 / 250 word target of the web exam room.
 *
 * The Task 1 picture is taken from the PDF (PdfImageExtractor): the embedded image, else the page region
 * rendered with Ghostscript. It is written to a temporary file; MockTestImporter stores it and replaces
 * IMAGE_TOKEN with the <img> tag.
 */
class WritingPaperNormalizer
{
    public const IMAGE_TOKEN = '[[task-image]]';

    public const DEFAULTS = [1 => ['minutes' => 20, 'words' => 150], 2 => ['minutes' => 40, 'words' => 250]];

    public const NO_PICTURE = ['letter', 'none'];

    public function __construct(private readonly PdfImageExtractor $images) {}

    /**
     * @param  array<string, mixed>  $response
     * @param  string|null  $pdfPath  the paper when it is a PDF (pictures can be extracted)
     * @return array{parts: array<int, array<string, mixed>>, warnings: array<int, string>, questions: int, numbers: array<int, int>, tasks: array<int, array<string, mixed>>}
     */
    public function normalize(array $response, ?string $pdfPath): array
    {
        $raw = array_values(array_filter((array) ($response['tasks'] ?? []), 'is_array'));
        if ($raw === []) {
            throw new RuntimeException('No Writing tasks were found in the document.');
        }

        $byNumber = [];
        foreach ($raw as $i => $task) {
            $number = (int) ($task['number'] ?? 0);
            $number = in_array($number, [1, 2], true) && ! isset($byNumber[$number]) ? $number : $i + 1;
            $byNumber[$number] ??= $task;
        }
        ksort($byNumber);

        $warnings = [];
        if (array_keys($byNumber) !== [1, 2]) {
            $warnings[] = 'Found '.count($byNumber).' Writing task(s); a Writing paper has Task 1 and Task 2 — check the module.';
        }

        $parts = [];
        $tasks = [];
        foreach ($byNumber as $number => $task) {
            [$part, $summary, $taskWarnings] = $this->task((int) $number, $task, $pdfPath);
            $parts[] = $part;
            $tasks[] = $summary;
            array_push($warnings, ...$taskWarnings);
        }

        return ['parts' => $parts, 'warnings' => $warnings, 'questions' => count($parts), 'numbers' => [], 'tasks' => $tasks];
    }

    /**
     * @param  array<string, mixed>  $task
     * @return array{0: array<string, mixed>, 1: array<string, mixed>, 2: array<int, string>}
     */
    private function task(int $number, array $task, ?string $pdfPath): array
    {
        $warnings = [];
        $defaults = self::DEFAULTS[$number] ?? self::DEFAULTS[2];
        $minutes = (int) ($task['minutes'] ?? 0);
        $minutes = $minutes > 0 && $minutes <= 60 ? $minutes : $defaults['minutes'];
        $words = (int) ($task['min_words'] ?? 0);
        $words = $words >= 50 && $words <= 500 ? $words : $defaults['words'];

        $prompt = $this->prompt((string) ($task['prompt_html'] ?? ''));
        if (mb_strlen(trim(strip_tags($prompt))) < 20) {
            $warnings[] = "Task {$number}: the task text is empty or very short — check it in the module editor.";
        }

        $kind = $number === 1 ? strtolower(trim((string) ($task['visual_kind'] ?? 'other'))) : 'none';
        $description = trim(preg_replace('/\s+/', ' ', strip_tags((string) ($task['visual_description'] ?? ''))));
        $needsPicture = ! in_array($kind, self::NO_PICTURE, true);

        $image = null;
        $imageError = null;
        if ($needsPicture) {
            [$image, $imageError, $note] = $this->picture($task, $pdfPath, $description);
            if ($image === null) {
                $warnings[] = 'Task 1 image could not be extracted — upload it in the module editor.'.($imageError ? " ({$imageError})" : '');
            } elseif ($note) {
                $warnings[] = $note;
            }
        }

        $wordsHtml = "<p>Write at least {$words} words.</p>";
        $picture = $image ? self::IMAGE_TOKEN : '';
        $examinerNote = $needsPicture && $description !== ''
            ? '<p><em>Picture (description for the examiner): '.e($description).'</em></p>'
            : '';

        $part = [
            'name' => "Task {$number}",
            'minute' => $minutes,
            'textarea' => "<p><strong>WRITING TASK {$number}</strong></p><p>You should spend about {$minutes} minutes on this task.</p>{$prompt}{$wordsHtml}{$picture}",
            'image' => $image,
            'sections' => [[
                'question_type' => 'essay',
                'textarea' => $prompt.$wordsHtml.$picture.$examinerNote,
                'from_option' => null,
                'to_option' => null,
                'options' => [],
                'questions' => [['order' => 1, 'textarea' => null, 'answer_text' => null, 'options' => [], 'numbers' => []]],
            ]],
        ];

        $summary = [
            'number' => $number,
            'page' => (int) ($task['page'] ?? 0),
            'minutes' => $minutes,
            'min_words' => $words,
            'visual_kind' => $kind,
            'visual_description' => $description,
            'visual_box' => array_values(array_filter((array) ($task['visual_box'] ?? []), 'is_numeric')),
            'image' => $image ? array_intersect_key($image, array_flip(['path', 'extension', 'width', 'height', 'source', 'page'])) : null,
            'image_error' => $imageError,
            'prompt' => trim(preg_replace('/\s+/', ' ', html_entity_decode(strip_tags(str_replace('</p>', "</p>\n", $prompt))))),
        ];

        return [$part, $summary, $warnings];
    }

    /**
     * Task 1 picture from the PDF: embedded image of a matching shape, else the rendered page region,
     * else any large embedded image (flagged for a check).
     *
     * @param  array<string, mixed>  $task
     * @return array{0: array<string, mixed>|null, 1: string|null, 2: string|null} [image, error, note]
     */
    private function picture(array $task, ?string $pdfPath, string $alt): array
    {
        if ($pdfPath === null) {
            return [null, 'the paper is not a PDF', null];
        }

        try {
            $pageCount = $this->images->pageCount($pdfPath);
            $page = (int) ($task['page'] ?? 0);
            if ($page < 1 || $page > $pageCount) {
                $page = $this->taskOnePage($pdfPath) ?? min(2, $pageCount);
            }

            $box = array_values(array_filter((array) ($task['visual_box'] ?? []), 'is_numeric'));
            $box = count($box) === 4 && $box[2] > $box[0] && $box[3] > $box[1] ? array_map('floatval', $box) : null;
            $aspect = null;
            if ($box !== null && ($size = $this->images->pageSize($pdfPath, $page))) {
                $aspect = (($box[3] - $box[1]) * $size[0]) / max(1, ($box[2] - $box[0]) * $size[1]);
            }

            $errors = [];
            $image = $this->images->embedded($pdfPath, $page, $aspect);
            $errors[] = $this->images->lastError;
            $note = null;

            if ($image === null && $box !== null) {
                $image = $this->images->renderRegion($pdfPath, $page, $box);
                $errors[] = $this->images->lastError;
            }

            if ($image === null && $aspect !== null) {
                $image = $this->images->embedded($pdfPath, $page);
                $errors[] = $this->images->lastError;
                $note = $image ? 'Task 1: the extracted picture may not be the task chart — check it in the module editor.' : null;
            }

            if ($image === null) {
                return [null, implode('; ', array_unique(array_filter($errors))) ?: null, null];
            }
        } catch (Throwable $e) {
            return [null, 'the PDF could not be read: '.mb_substr($e->getMessage(), 0, 200), null];
        }

        $path = tempnam(sys_get_temp_dir(), 'writing-task1-');
        $file = $path.'.'.$image['extension'];
        @unlink($path);
        file_put_contents($file, $image['data']);
        unset($image['data']);

        return [$image + ['path' => $file, 'alt' => $alt !== '' ? $alt : 'Writing Task 1 picture', 'page' => $page], null, $note];
    }

    /**
     * First page whose text has "TASK 1" (when the AI gave no usable page number).
     */
    private function taskOnePage(string $pdfPath): ?int
    {
        foreach ($this->images->pageTexts($pdfPath) as $number => $text) {
            if (preg_match('/TASK\s*1\b/i', $text)) {
                return $number;
            }
        }

        return null;
    }

    /**
     * Clean task HTML without the lines the importer writes itself (time, word minimum, heading).
     */
    private function prompt(string $html): string
    {
        $html = MockImportNormalizer::cleanHtml($html);
        if ($html !== '' && ! str_contains($html, '<')) {
            $html = '<p>'.nl2br(e($html), false).'</p>';
        }

        $html = preg_replace(
            '#<(p|h\d|li)>\s*(?:<(?:strong|b|em|i)>\s*)*(?:WRITING\s+TASK\s*\d|You\s+should\s+spend\s+about\s+\d+\s+minutes\s+on\s+this\s+task|Write\s+at\s+least\s+\d+\s+words)\s*\.?\s*(?:</(?:strong|b|em|i)>\s*)*</\1>#i',
            '',
            $html,
        );

        return trim((string) $html);
    }
}
