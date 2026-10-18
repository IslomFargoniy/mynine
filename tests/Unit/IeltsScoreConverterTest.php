<?php

use App\Services\IeltsScoreConverter;

test('listening raw scores map to the official band boundaries', function () {
    expect(IeltsScoreConverter::convertListening(40))->toBe(9.0)
        ->and(IeltsScoreConverter::convertListening(39))->toBe(9.0)
        ->and(IeltsScoreConverter::convertListening(30))->toBe(7.0)
        ->and(IeltsScoreConverter::convertListening(23))->toBe(6.0)
        ->and(IeltsScoreConverter::convertListening(16))->toBe(5.0)
        ->and(IeltsScoreConverter::convertListening(0))->toBe(0.0);
});

test('reading raw scores map to the academic band boundaries', function () {
    expect(IeltsScoreConverter::convertReading(33))->toBe(7.5)
        ->and(IeltsScoreConverter::convertReading(27))->toBe(6.5)
        ->and(IeltsScoreConverter::convertReading(15))->toBe(5.0)
        ->and(IeltsScoreConverter::convertReading(1))->toBe(1.0);
});

test('overall band rounds to the nearest half band like IELTS', function () {
    expect(IeltsScoreConverter::calculateOverallBand([6.5, 6.5, 5.0, 7.0]))->toBe(6.5)   // 6.25 -> 6.5
        ->and(IeltsScoreConverter::calculateOverallBand([4.0, 3.5, 4.0, 4.0]))->toBe(4.0) // 3.875 -> 4.0
        ->and(IeltsScoreConverter::calculateOverallBand([6.5, 6.5, 5.5, 6.0]))->toBe(6.0) // 6.125 -> 6.0
        ->and(IeltsScoreConverter::calculateOverallBand([]))->toBe(0.0);
});
