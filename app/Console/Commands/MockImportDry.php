<?php

namespace App\Console\Commands;

use App\Services\GeminiService;
use App\Services\Import\MockTestPdfParser;
use Illuminate\Console\Command;
use Throwable;

/**
 * Manual check of the Mock Bank PDF import: runs the AI parser on local files and prints what would be
 * imported. Nothing is written to the database.
 */
class MockImportDry extends Command
{
    protected $signature = 'mock:import-dry
        {module : Listening, Reading or Writing}
        {paper : Path of the question paper (.pdf, .docx or .txt)}
        {answers? : Path of the answer key}
        {--provider= : gemini or openai (default: services.mock_import.provider)}
        {--json= : Also write the normalised result as JSON to this file}
        {--image-dir= : Writing: copy the extracted Task 1 picture into this directory}';

    protected $description = 'Parse a Listening / Reading / Writing paper with the AI importer without writing to the database';

    public function handle(MockTestPdfParser $parser, GeminiService $gemini): int
    {
        $module = ucfirst(strtolower((string) $this->argument('module')));
        $paper = (string) $this->argument('paper');
        $answers = $this->argument('answers');

        foreach (array_filter([$paper, $answers]) as $path) {
            if (! is_file($path)) {
                $this->error("File not found: {$path}");

                return self::FAILURE;
            }
        }

        $provider = $module === 'Writing' ? 'gemini' : ($this->option('provider') ?: MockTestPdfParser::provider());
        $model = $provider === 'gemini' ? $gemini->model() : (string) config('services.openai.import_model');
        $this->info("Parsing {$module} with {$provider} ({$model})…");

        $started = microtime(true);
        try {
            $result = $parser->parseFiles($module, $paper, $answers ?: null, $provider);
        } catch (Throwable $e) {
            $this->error(class_basename($e).': '.$e->getMessage());

            return self::FAILURE;
        }
        $seconds = round(microtime(true) - $started, 1);

        if ($module === 'Writing') {
            return $this->writing($result, $seconds);
        }

        foreach ($result['parts'] as $part) {
            $passage = mb_strlen(trim(strip_tags($part['textarea'])));
            $this->newLine();
            $this->line("<options=bold>{$part['name']}</>".($passage > 0 ? " (passage: {$passage} chars)" : ''));

            foreach ($part['sections'] as $section) {
                $numbers = array_merge(...array_map(fn ($q) => $q['numbers'] ?? [], $section['questions']) ?: [[]]);
                $range = $numbers === [] ? '-' : min($numbers).'-'.max($numbers);
                $extra = $section['question_type'] === 'matching' ? " options {$section['from_option']}-{$section['to_option']}" : '';
                $extra .= $section['options'] !== [] ? ' box distractors: '.implode(' | ', $section['options']) : '';
                $this->line("  [{$section['question_type']}] Q{$range}{$extra}");

                foreach ($section['questions'] as $question) {
                    $this->line('    '.implode('&', $question['numbers'] ?? []).': '.$this->describe($question));
                }
            }
        }

        $covered = $result['numbers'];
        $missing = $parser->missing($module, $covered);

        $this->newLine();
        $this->table(['Parts', 'Questions', 'Numbers covered', 'Missing', 'Time'], [[
            count($result['parts']),
            $result['questions'],
            count($covered).($covered !== [] ? ' ('.min($covered).'-'.max($covered).')' : ''),
            $missing === [] ? 'none' : implode(', ', $missing),
            "{$seconds}s",
        ]]);

        $this->printWarnings($result['warnings']);

        if ($path = $this->option('json')) {
            file_put_contents($path, json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
            $this->line("JSON written to {$path}");
        }

        return self::SUCCESS;
    }

    /**
     * @param  array<string, mixed>  $result
     */
    private function writing(array $result, float $seconds): int
    {
        foreach ($result['tasks'] as $task) {
            $this->newLine();
            $this->line("<options=bold>Task {$task['number']}</> (page {$task['page']}, {$task['minutes']} minutes, at least {$task['min_words']} words)");
            $this->line('  Prompt: '.$task['prompt']);

            if ($task['number'] !== 1) {
                continue;
            }

            $this->line("  Visual: {$task['visual_kind']}".($task['visual_description'] !== '' ? " — {$task['visual_description']}" : ''));
            if ($task['visual_box'] !== []) {
                $this->line('  Box on the page (ymin, xmin, ymax, xmax / 1000): '.implode(', ', $task['visual_box']));
            }
            $image = $task['image'];
            if ($image === null) {
                $this->line('  Image: '.(in_array($task['visual_kind'], ['letter', 'none'], true) ? 'not needed (letter task)' : 'NOT extracted'.($task['image_error'] ? " ({$task['image_error']})" : '')));

                continue;
            }

            $path = $image['path'];
            if ($dir = $this->option('image-dir')) {
                @mkdir($dir, 0775, true);
                $copy = rtrim($dir, '/').'/writing-task1.'.$image['extension'];
                copy($path, $copy);
                @unlink($path);
                $path = $copy;
            }
            $how = $image['source'] === 'embedded' ? 'embedded image' : 'page rendered with Ghostscript and cropped';
            $this->line("  Image: {$how}, page {$image['page']}, {$image['width']}x{$image['height']} {$image['extension']} -> {$path}");
        }

        $this->newLine();
        $this->line('Parts: '.count($result['parts'])." ({$seconds}s)");
        $this->printWarnings($result['warnings']);

        if ($path = $this->option('json')) {
            file_put_contents($path, json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
            $this->line("JSON written to {$path}");
        }

        return self::SUCCESS;
    }

    /**
     * @param  array<int, string>  $warnings
     */
    private function printWarnings(array $warnings): void
    {
        if ($warnings === []) {
            $this->info('No warnings.');

            return;
        }

        $this->warn('Warnings:');
        foreach ($warnings as $warning) {
            $this->line("  - {$warning}");
        }
    }

    /**
     * @param  array<string, mixed>  $question
     */
    private function describe(array $question): string
    {
        $text = mb_strimwidth((string) ($question['textarea'] ?? ''), 0, 70, '…');

        if ($question['options'] !== []) {
            $options = array_map(
                fn ($o, $i) => chr(65 + $i).($o['is_correct'] ? '*' : ''),
                $question['options'],
                array_keys($question['options']),
            );

            return trim($text.' ['.implode(' ', $options).']');
        }

        return trim(($text !== '' ? $text.' => ' : '').($question['answer_text'] ?? '(no answer)'));
    }
}
