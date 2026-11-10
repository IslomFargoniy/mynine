<?php

namespace App\Models;

use App\Models\User\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\DB;

/**
 * A Mock Bank "Import from PDF" run.
 *
 * files:   ['listening' => 'imports/{test}/{import}/listening.pdf', 'reading' => …, 'writing' => …, 'answers' => …]
 * modules: ['Listening' => ['status' => 'queued|running|done|failed', 'message' => ?string,
 *           'warnings' => string[], 'parts' => int, 'questions' => int], 'Reading' => …]
 */
class TestImport extends Model
{
    public const QUEUED = 'queued';

    public const RUNNING = 'running';

    public const DONE = 'done';

    public const FAILED = 'failed';

    protected $fillable = ['test_id', 'user_id', 'status', 'replace', 'files', 'modules', 'finished_at'];

    protected $casts = [
        'replace' => 'boolean',
        'files' => 'array',
        'modules' => 'array',
        'finished_at' => 'datetime',
    ];

    public function test(): BelongsTo
    {
        return $this->belongsTo(Test::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Merge changes into one module's status and recompute the overall status. Runs under a row lock
     * because the Listening and Reading jobs may finish at the same time.
     *
     * @param  array<string, mixed>  $changes
     */
    public static function updateModule(int $id, string $module, array $changes): ?self
    {
        return DB::transaction(function () use ($id, $module, $changes) {
            $import = self::query()->lockForUpdate()->find($id);
            if (! $import) {
                return null;
            }

            $modules = $import->modules ?? [];
            $modules[$module] = array_merge($modules[$module] ?? [], $changes);
            $import->modules = $modules;

            $statuses = array_column($modules, 'status');
            $import->status = match (true) {
                in_array(self::RUNNING, $statuses, true) => self::RUNNING,
                in_array(self::QUEUED, $statuses, true) => in_array(self::DONE, $statuses, true) || in_array(self::FAILED, $statuses, true) ? self::RUNNING : self::QUEUED,
                in_array(self::FAILED, $statuses, true) => self::FAILED,
                default => self::DONE,
            };
            if (! $import->isActive()) {
                $import->finished_at = now();
            }
            $import->save();

            return $import;
        });
    }

    public function isActive(): bool
    {
        return in_array($this->status, [self::QUEUED, self::RUNNING], true);
    }
}
