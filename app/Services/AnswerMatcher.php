<?php

namespace App\Services;

/**
 * Text answers of Listening / Reading gap questions against the answer key.
 *
 * - Case-insensitive (mb_strtolower), surrounding and repeated internal whitespace ignored,
 *   trailing punctuation (. , ; : ! ?) ignored.
 * - Alternatives in a key are separated by ";", "|" or a "/" between words ("colour / color").
 *   A "/" between digits is part of the answer ("24/7", "1/2").
 * - Thousands separators: "14,000" and "14000" are the same answer (integers only, so "3.5" is never
 *   turned into "4").
 */
class AnswerMatcher
{
    public static function normalize(?string $value): string
    {
        $value = mb_strtolower(trim((string) $value));
        $value = preg_replace('/\s+/u', ' ', $value) ?? $value;
        $value = rtrim($value, '.,;:!? ');

        return trim($value);
    }

    /**
     * Normalised alternatives of an answer key, including the thousands-separator variants.
     *
     * @return array<int, string>
     */
    public static function alternatives(?string $key): array
    {
        $key = preg_replace('/\s+/u', ' ', trim((string) $key)) ?? '';

        // ";" and "|" always separate alternatives; "/" only when it is not between two digits.
        $parts = preg_split('#[;|]|(?<!\d)(?<!\d )/|/(?! ?\d)#u', $key) ?: [];

        $alternatives = [];
        foreach ($parts as $part) {
            $clean = self::normalize($part);
            if ($clean === '') {
                continue;
            }
            $alternatives[] = $clean;

            $withoutSeparators = str_replace(',', '', $clean);
            if ($withoutSeparators !== $clean && ctype_digit($withoutSeparators)) {
                $alternatives[] = $withoutSeparators;
            } elseif (ctype_digit($clean) && strlen($clean) > 3) {
                $alternatives[] = number_format((int) $clean);
            }
        }

        return array_values(array_unique($alternatives));
    }

    public static function matches(?string $studentAnswer, ?string $key): bool
    {
        $student = self::normalize($studentAnswer);
        if ($student === '' || trim((string) $key) === '') {
            return false;
        }

        $alternatives = self::alternatives($key);
        if (in_array($student, $alternatives, true)) {
            return true;
        }

        $withoutSeparators = str_replace(',', '', $student);

        return $withoutSeparators !== $student && ctype_digit($withoutSeparators)
            && in_array($withoutSeparators, $alternatives, true);
    }
}
