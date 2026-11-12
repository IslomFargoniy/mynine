<?php

namespace App\Models;

use App\Models\Scopes\CenterScope;
use Illuminate\Database\Eloquent\Model;
use LogicException;

/**
 * Immutable billing record: a mock candidate who started a written module (Listening / Reading / Writing).
 * Written once per candidate (mock_student_id is unique) and never changed or deleted by the app, so deleting
 * the mock, the candidate or the attempt later does not lower a center's billed count.
 */
class CenterBillableCandidate extends Model
{
    public const UPDATED_AT = null;

    protected $guarded = ['id'];

    protected $casts = [
        'counted_at' => 'datetime',
    ];

    protected static function booted(): void
    {
        static::updating(fn () => throw new LogicException('Billing records are immutable.'));
        static::deleting(fn () => throw new LogicException('Billing records are immutable.'));
    }

    /**
     * Record the attempt's candidate once (no-op for practice attempts and candidates already recorded).
     */
    public static function record(Attempt $attempt): void
    {
        if (! $attempt->mock_student_id || ! $attempt->mock_id) {
            return;
        }

        if (static::query()->where('mock_student_id', $attempt->mock_student_id)->exists()) {
            return;
        }

        $mock = Mock::withoutGlobalScope(CenterScope::class)->withoutEagerLoads()->find($attempt->mock_id);
        $student = MockStudent::withoutGlobalScopes()->withoutEagerLoads()->find($attempt->mock_student_id);
        if (! $mock?->owner_id || ! $student) {
            return;
        }

        static::query()->insertOrIgnore([
            'owner_id' => $mock->owner_id,
            'mock_student_id' => $student->id,
            'mock_id' => $mock->id,
            'attempt_id' => $attempt->id,
            'code' => (string) $student->code,
            'name' => (string) ($student->name ?: $attempt->name),
            'mock_name' => $mock->name,
            'counted_at' => $attempt->started_at ?? $attempt->created_at ?? now(),
            'created_at' => now(),
        ]);
    }
}
