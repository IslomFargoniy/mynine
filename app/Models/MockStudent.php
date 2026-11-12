<?php

namespace App\Models;

use App\Models\Concerns\BelongsToCenterThroughMock;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
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
     * Candidate codes are exactly six digits (100000-999999), unique across all mocks of all centers, so a candidate types
     * only digits on the exam PC. The unique index on mock_students.code backs this up.
     */
    public const CODE_PATTERN = '/^\d{6}$/';

    public static function randomCode(): string
    {
        return (string) random_int(100000, 999999);
    }

    /**
     * One unique six-digit candidate code.
     */
    public static function generateUniqueCode(): string
    {
        do {
            $code = self::randomCode();
        } while (static::withoutGlobalScopes()->where('code', $code)->exists());

        return $code;
    }

    /**
     * $count unique six-digit codes, checked against the database in batches.
     *
     * @return array<int, string>
     */
    public static function generateBulkCodes(int $count): array
    {
        $codes = [];
        while (count($codes) < $count) {
            $batch = [];
            while (count($codes) + count($batch) < $count) {
                $code = self::randomCode();
                if (! isset($codes[$code])) {
                    $batch[$code] = $code;
                }
            }
            $taken = static::withoutGlobalScopes()->whereIn('code', array_values($batch))->pluck('code')->flip();
            foreach ($batch as $code) {
                if (! isset($taken[$code])) {
                    $codes[$code] = $code;
                }
            }
        }

        return array_values($codes);
    }
}
