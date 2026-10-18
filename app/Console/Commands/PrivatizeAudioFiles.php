<?php

namespace App\Console\Commands;

use App\Models\Part;
use App\Models\Test;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

class PrivatizeAudioFiles extends Command
{
    protected $signature = 'audio:privatize {--dry-run : Only report what would change}';

    protected $description = 'Move legacy audio files from the public disk to the private disk and rewrite stored paths';

    public function handle(): int
    {
        $moved = 0;
        $missing = 0;

        foreach ([Test::class, Part::class] as $model) {
            $model::query()
                ->where('audio_path', 'like', 'storage/audio/%')
                ->chunkById(100, function ($rows) use (&$moved, &$missing) {
                    foreach ($rows as $row) {
                        $relative = substr($row->audio_path, strlen('storage/'));
                        $newPath = 'media/'.$relative;

                        if ($this->option('dry-run')) {
                            $this->line("{$row->getTable()}#{$row->id}: {$row->audio_path} -> {$newPath}");

                            continue;
                        }

                        $source = Storage::disk('public')->path($relative);
                        $target = Storage::disk('local')->path($relative);

                        if (is_file($source) && ! is_file($target)) {
                            // rename() moves the file without loading it into memory (audio files can be 100+ MB)
                            if (! is_dir(dirname($target))) {
                                mkdir(dirname($target), 0755, true);
                            }
                            if (! rename($source, $target)) {
                                $this->error("Could not move {$source}");

                                continue;
                            }
                        } elseif (! is_file($source) && ! is_file($target)) {
                            $missing++;
                            $this->warn("File missing for {$row->getTable()}#{$row->id}: {$relative} (path rewritten anyway)");
                        }

                        $row->forceFill(['audio_path' => $newPath])->saveQuietly();
                        $moved++;
                    }
                });
        }

        $this->info($this->option('dry-run') ? 'Dry run finished.' : "Updated {$moved} record(s), {$missing} file(s) were already missing.");

        return self::SUCCESS;
    }
}
