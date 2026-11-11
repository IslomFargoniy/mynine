<?php

namespace App\Services;

use App\Models\AttemptPart;
use App\Models\Mock;
use App\Models\MockStudent;
use App\Models\TestType;

/**
 * Mock candidates (code-only guests): phone normalization and repeat-candidate detection.
 */
class CandidateService
{
    /**
     * Normalize an Uzbek phone number to +998XXXXXXXXX, or null when it cannot be one.
     */
    public static function normalizePhone(?string $phone): ?string
    {
        $digits = preg_replace('/\D+/', '', (string) $phone);

        if (strlen($digits) === 9) {
            $digits = '998'.$digits;
        }

        return preg_match('/^998\d{9}$/', $digits) === 1 ? '+'.$digits : null;
    }

    /**
     * Name without stray separators around it ("ali :" → "ali", "- Vali," → "Vali"), single spaces.
     */
    public static function cleanName(?string $name): string
    {
        $name = preg_replace('/\s+/u', ' ', (string) $name);

        return trim((string) preg_replace('/^[\s;,:|.\-–—·]+|[\s;,:|.\-–—·]+$/u', '', (string) $name));
    }

    /**
     * One bulk line → name + raw phone. Accepts "Name ; phone", "Name, phone", "Name : phone", "Name<TAB>phone",
     * "Name - phone", "Name phone" and the phone first ("phone - Name"). Hyphens inside names stay.
     *
     * @return array{name: string, phone: ?string}
     */
    public static function parseLine(string $line): array
    {
        $line = trim(str_replace("\t", ' ; ', $line));
        $phone = '(\+?\d[\d\s()\-]{7,}\d)';

        if (preg_match('/^(.*?)(?:\s*[;,:|]\s*|\s+-\s+|\s+)'.$phone.'\s*[;,.]?$/u', $line, $m)) {
            return ['name' => static::cleanName($m[1]), 'phone' => trim($m[2])];
        }

        if (preg_match('/^'.$phone.'(?:\s*[;,:|]\s*|\s+-\s+|\s+)(.+)$/u', $line, $m)) {
            return ['name' => static::cleanName($m[2]), 'phone' => trim($m[1])];
        }

        return ['name' => static::cleanName($line), 'phone' => null];
    }

    /**
     * Modules of $mock that a candidate with this phone already sat in another mock.
     *
     * @return array<int, array{test_type_id: int, type: ?string, test: ?string, mock: ?string, date: ?string}>
     */
    public function repeatModules(Mock $mock, ?string $phone, ?int $exceptStudentId = null): array
    {
        $phone = static::normalizePhone($phone);
        $moduleIds = $mock->moduleTestTypeIds();

        if ($phone === null || $moduleIds === []) {
            return [];
        }

        $studentIds = MockStudent::withoutEagerLoads()
            ->where('phone', $phone)
            ->where('mock_id', '!=', $mock->id)
            ->when($exceptStudentId, fn ($q) => $q->whereKeyNot($exceptStudentId))
            ->pluck('id');

        if ($studentIds->isEmpty()) {
            return [];
        }

        $rows = AttemptPart::query()
            ->join('attempts', 'attempts.id', '=', 'attempt_parts.attempt_id')
            ->join('parts', 'parts.id', '=', 'attempt_parts.part_id')
            ->leftJoin('mocks', 'mocks.id', '=', 'attempts.mock_id')
            ->whereIn('attempts.mock_student_id', $studentIds)
            ->whereIn('parts.test_type_id', $moduleIds)
            ->select('parts.test_type_id', 'mocks.name as mock_name', 'attempts.started_at')
            ->orderBy('attempts.started_at')
            ->get()
            ->unique('test_type_id');

        if ($rows->isEmpty()) {
            return [];
        }

        $types = TestType::query()->with(['type', 'test:id,name'])->whereIn('id', $rows->pluck('test_type_id'))->get()->keyBy('id');

        return $rows->map(function ($row) use ($types) {
            $tt = $types->get($row->test_type_id);

            return [
                'test_type_id' => (int) $row->test_type_id,
                'type' => $tt?->type?->name,
                'test' => $tt?->test?->name,
                'mock' => $row->mock_name,
                'date' => $row->started_at ? substr((string) $row->started_at, 0, 10) : null,
            ];
        })->values()->all();
    }
}
