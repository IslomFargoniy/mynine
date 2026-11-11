<?php

namespace App\Services;

class IeltsScoreConverter
{
    /**
     * Convert Listening correct answers count to IELTS Band Score
     */
    public static function convertListening(int $correctCount): float
    {
        if ($correctCount >= 39) {
            return 9.0;
        }
        if ($correctCount >= 37) {
            return 8.5;
        }
        if ($correctCount >= 35) {
            return 8.0;
        }
        if ($correctCount >= 32) {
            return 7.5;
        }
        if ($correctCount >= 30) {
            return 7.0;
        }
        if ($correctCount >= 26) {
            return 6.5;
        }
        if ($correctCount >= 23) {
            return 6.0;
        }
        if ($correctCount >= 18) {
            return 5.5;
        }
        if ($correctCount >= 16) {
            return 5.0;
        }
        if ($correctCount >= 13) {
            return 4.5;
        }
        if ($correctCount >= 10) {
            return 4.0;
        }
        if ($correctCount >= 8) {
            return 3.5;
        }
        if ($correctCount >= 6) {
            return 3.0;
        }
        if ($correctCount >= 4) {
            return 2.5;
        }
        if ($correctCount == 3) {
            return 2.0;
        }
        if ($correctCount == 2) {
            return 1.5;
        }
        if ($correctCount == 1) {
            return 1.0;
        }

        return 0.0;
    }

    /**
     * Convert Reading (Academic) correct answers count to IELTS Band Score
     */
    public static function convertReading(int $correctCount): float
    {
        if ($correctCount >= 39) {
            return 9.0;
        }
        if ($correctCount >= 37) {
            return 8.5;
        }
        if ($correctCount >= 35) {
            return 8.0;
        }
        if ($correctCount >= 33) {
            return 7.5;
        }
        if ($correctCount >= 30) {
            return 7.0;
        }
        if ($correctCount >= 27) {
            return 6.5;
        }
        if ($correctCount >= 23) {
            return 6.0;
        }
        if ($correctCount >= 19) {
            return 5.5;
        }
        if ($correctCount >= 15) {
            return 5.0;
        }
        if ($correctCount >= 13) {
            return 4.5;
        }
        if ($correctCount >= 10) {
            return 4.0;
        }
        if ($correctCount >= 8) {
            return 3.5;
        }
        if ($correctCount >= 6) {
            return 3.0;
        }
        if ($correctCount >= 4) {
            return 2.5;
        }
        if ($correctCount == 3) {
            return 2.0;
        }
        if ($correctCount == 2) {
            return 1.5;
        }
        if ($correctCount == 1) {
            return 1.0;
        }

        return 0.0;
    }

    /**
     * Convert General Training Reading correct answers (out of 40) to a band, official GT table:
     * 40 → 9, 39 → 8.5, 37-38 → 8, 36 → 7.5, 34-35 → 7, 32-33 → 6.5, 30-31 → 6, 27-29 → 5.5,
     * 23-26 → 5, 19-22 → 4.5, 15-18 → 4, 12-14 → 3.5, 8-11 → 3, 5-7 → 2.5 (below: 3-4 → 2, 2 → 1.5, 1 → 1).
     */
    public static function convertReadingGeneral(int $correctCount): float
    {
        $table = [
            40 => 9.0, 39 => 8.5, 37 => 8.0, 36 => 7.5, 34 => 7.0, 32 => 6.5, 30 => 6.0, 27 => 5.5,
            23 => 5.0, 19 => 4.5, 15 => 4.0, 12 => 3.5, 8 => 3.0, 5 => 2.5, 3 => 2.0, 2 => 1.5, 1 => 1.0,
        ];

        foreach ($table as $min => $band) {
            if ($correctCount >= $min) {
                return $band;
            }
        }

        return 0.0;
    }

    /**
     * Reading band for the test variant ("general" = General Training, anything else = Academic).
     */
    public static function convertReadingFor(int $correctCount, ?string $variant): float
    {
        return $variant === 'general'
            ? static::convertReadingGeneral($correctCount)
            : static::convertReading($correctCount);
    }

    /**
     * Calculate IELTS Overall Band Score from module scores with standard 0.5 rounding
     */
    public static function calculateOverallBand(array $scores): float
    {
        if (empty($scores)) {
            return 0.0;
        }

        return static::roundBand(array_sum($scores) / count($scores));
    }

    /**
     * IELTS rounding of an average to a band: .25 rounds up to .5, .75 rounds up to the next whole band.
     */
    public static function roundBand(float $avg): float
    {
        $avg = round($avg, 6);
        $fraction = $avg - floor($avg);
        if ($fraction < 0.25) {
            return (float) floor($avg);
        } elseif ($fraction < 0.75) {
            return (float) (floor($avg) + 0.5);
        } else {
            return (float) ceil($avg);
        }
    }

    /**
     * Get CEFR equivalent level for IELTS Band score
     */
    public static function getCefrLevel(float $band): string
    {
        if ($band >= 8.5) {
            return 'C2 Mastery / Proficient';
        }
        if ($band >= 7.0) {
            return 'C1 Advanced';
        }
        if ($band >= 5.5) {
            return 'B2 Vantage';
        }
        if ($band >= 4.0) {
            return 'B1 Threshold';
        }

        return 'A2 Waystage';
    }
}
