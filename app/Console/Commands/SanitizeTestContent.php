<?php

namespace App\Console\Commands;

use App\Support\Html\ContentSanitizer;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * One-off: run the test-content HTML allow-list over rows saved before sanitization on save existed
 * (parts, sections, questions, options). New saves are sanitized by the SanitizesContentHtml model trait.
 *
 *   php artisan content:sanitize --dry-run   # count what would change
 *   php artisan content:sanitize             # rewrite the changed rows (back up the database first)
 *
 * Writes with the query builder: timestamps, model events and re-scoring jobs are not triggered.
 */
class SanitizeTestContent extends Command
{
    protected $signature = 'content:sanitize {--dry-run : Only report how many rows would change}';

    protected $description = 'Sanitize stored test content HTML (parts, sections, questions, options)';

    /** table => sanitize always (true) or only when the value contains markup (false) */
    private const TABLES = ['parts' => true, 'sections' => true, 'questions' => false, 'options' => false];

    public function handle(ContentSanitizer $sanitizer): int
    {
        $dry = (bool) $this->option('dry-run');

        foreach (self::TABLES as $table => $always) {
            $changed = 0;
            DB::table($table)->whereNotNull('textarea')->select(['id', 'textarea'])->orderBy('id')
                ->chunkById(200, function ($rows) use ($table, $always, $sanitizer, $dry, &$changed) {
                    foreach ($rows as $row) {
                        $clean = $always ? $sanitizer->sanitize($row->textarea) : $sanitizer->sanitizeIfHtml($row->textarea);
                        if ($clean === $row->textarea) {
                            continue;
                        }
                        $changed++;
                        if (! $dry) {
                            DB::table($table)->where('id', $row->id)->update(['textarea' => $clean]);
                        }
                    }
                });

            $this->line(sprintf('%-10s %d row(s) %s', $table, $changed, $dry ? 'would change' : 'sanitized'));
        }

        return self::SUCCESS;
    }
}
