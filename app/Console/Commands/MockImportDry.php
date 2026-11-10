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
        {module : Listening or Reading}
        {paper : Path of the question paper (.pdf, .docx or .txt)}
        {answers? : Path of the answer key}
        {--provider= : gemini or openai (default: services.mock_import.provider)}
        {--json= : Also write the normalised result as JSON to this file}';

    protected $description = 'Parse a Listening / Reading paper with the AI importer without writing to the database';

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

        $provider = $this->option('provider') ?: MockTestPdfParser::provider();
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

        if ($result['warnings'] === []) {
            $this->info('No warnings.');
        } else {
            $this->warn('Warnings:');
            foreach ($result['warnings'] as $warning) {
                $this->line("  - {$warning}");
            }
        }

        if ($path = $this->option('json')) {
            file_put_contents($path, json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
            $this->line("JSON written to {$path}");
        }

        return self::SUCCESS;
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
