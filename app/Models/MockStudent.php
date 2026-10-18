<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MockStudent extends Model
{
    use HasFactory;

    protected $fillable = [
        'mock_id',
        'name',
        'code',
        'attended',
        'phone',
    ];

    protected $casts = [
        'attended' => 'boolean',
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

    /**
     * Generates a clean, compact uppercase prefix from mock name (e.g. "Test 1" -> "TEST1", "Mock 10" -> "MOCK10")
     */
    public static function generatePrefix(?string $mockName): string
    {
        if (empty($mockName)) {
            return 'MOCK';
        }

        // Remove special characters, keep letters and digits only
        $clean = strtoupper(preg_replace('/[^a-zA-Z0-9]/', '', $mockName));

        // Limit prefix to 8 characters max
        $prefix = substr($clean, 0, 8);

        return ! empty($prefix) ? $prefix : 'MOCK';
    }

    /**
     * Generates a single unique candidate code with mock prefix (e.g. TEST1-849201)
     */
    public static function generateUniqueCode(string $prefix = 'MOCK'): string
    {
        $prefix = self::generatePrefix($prefix);
        do {
            $code = $prefix.'-'.rand(100000, 999999);
        } while (static::where('code', $code)->exists());

        return $code;
    }

    /**
     * Generates a batch of unique codes in memory with zero collisions and only 1 DB check
     *
     * @return array<string>
     */
    public static function generateBulkCodes(int $count, string $prefix = 'MOCK'): array
    {
        if ($count <= 0) {
            return [];
        }

        $prefix = self::generatePrefix($prefix);
        $codes = [];

        // Generate N unique codes in memory
        while (count($codes) < $count) {
            $code = $prefix.'-'.rand(100000, 999999);
            $codes[$code] = $code;
        }

        $codeList = array_values($codes);

        // Check collisions in DB with 1 single query
        $existingCodes = static::whereIn('code', $codeList)->pluck('code')->flip()->toArray();

        // If any code exists in DB, replace it
        if (! empty($existingCodes)) {
            for ($i = 0; $i < count($codeList); $i++) {
                if (isset($existingCodes[$codeList[$i]])) {
                    do {
                        $newCode = $prefix.'-'.rand(100000, 999999);
                    } while (isset($codes[$newCode]) || static::where('code', $newCode)->exists());

                    $codes[$newCode] = $newCode;
                    $codeList[$i] = $newCode;
                }
            }
        }

        return $codeList;
    }
}
