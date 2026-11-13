<?php

namespace App\Models;

use App\Models\Concerns\BelongsToCenterThroughMock;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\HasApiTokens;

class MockStudent extends Model
{
    use BelongsToCenterThroughMock, HasApiTokens, HasFactory;

    protected $fillable = [
        'mock_id',
        'name',
        'code',
        'attended',
        'phone',
        'checked_in_at',
        'speaking_at',
        'result_printed_at',
        'result_delivered_at',
        'delivered_by',
    ];

    protected $casts = [
        'attended' => 'boolean',
        'checked_in_at' => 'datetime',
        'speaking_at' => 'datetime',
        'result_printed_at' => 'datetime',
        'result_delivered_at' => 'datetime',
    ];

    protected $with = [
        'attempt',
    ];

    /**
     * The candidate started a written module (billed): only the SuperAdmin may delete them.
     */
    public function isBilled(): bool
    {
        if (CenterBillableCandidate::query()->where('mock_student_id', $this->id)->exists()) {
            return true;
        }

        return Attempt::withoutGlobalScopes()->withoutEagerLoads()
            ->where('mock_student_id', $this->id)
            ->whereHas('attempt_types', fn ($q) => $q->withoutEagerLoads()
                ->whereHas('type', fn ($t) => $t->whereIn('name', Attempt::DESKTOP_MODULE_ORDER)))
            ->exists();
    }

    public function mock()
    {
        return $this->belongsTo(Mock::class, 'mock_id');
    }

    public function attempt()
    {
        return $this->hasOne(Attempt::class, 'mock_student_id');
    }

    public function deliveredBy()
    {
        return $this->belongsTo(User\User::class, 'delivered_by');
    }

    /**
     * Candidate codes are issued in order across all mocks of all centers: 000001, 000002, … 999999, then 1000000 (a
     * digit more). Codes still held by older (random) candidates are skipped. A candidate types only digits on the
     * exam PC; the unique index on mock_students.code backs this up.
     */
    public const CODE_PATTERN = '/^\d{6,9}$/';

    /** settings row holding the next number to issue. */
    public const CODE_SEQUENCE_KEY = 'candidate_code_next';

    public static function formatCode(int $number): string
    {
        return str_pad((string) $number, 6, '0', STR_PAD_LEFT);
    }

    /**
     * The next candidate code.
     */
    public static function generateUniqueCode(): string
    {
        return self::generateBulkCodes(1)[0];
    }

    /**
     * The next $count candidate codes, in order (the counter row is locked, so two centers never get the same ones).
     *
     * @return array<int, string>
     */
    public static function generateBulkCodes(int $count): array
    {
        if ($count < 1) {
            return [];
        }

        return DB::transaction(function () use ($count) {
            Setting::query()->insertOrIgnore(['key' => self::CODE_SEQUENCE_KEY, 'value' => '1', 'created_at' => now(), 'updated_at' => now()]);
            $next = max(1, (int) Setting::query()->whereKey(self::CODE_SEQUENCE_KEY)->lockForUpdate()->value('value'));

            $codes = [];
            while (count($codes) < $count) {
                $batch = [];
                while (count($codes) + count($batch) < $count) {
                    $batch[] = self::formatCode($next++);
                }
                $taken = static::withoutGlobalScopes()->whereIn('code', $batch)->pluck('code')->flip();
                foreach ($batch as $code) {
                    if (! isset($taken[$code])) {
                        $codes[] = $code;
                    }
                }
            }

            Setting::query()->whereKey(self::CODE_SEQUENCE_KEY)->update(['value' => (string) $next, 'updated_at' => now()]);

            return $codes;
        });
    }
}
