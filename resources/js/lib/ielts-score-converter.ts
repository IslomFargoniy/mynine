/**
 * Convert Listening correct count (0-40) to IELTS Band Score
 */
export function convertListeningBand(correctCount: number): number {
    if (correctCount >= 39) return 9.0;
    if (correctCount >= 37) return 8.5;
    if (correctCount >= 35) return 8.0;
    if (correctCount >= 32) return 7.5;
    if (correctCount >= 30) return 7.0;
    if (correctCount >= 26) return 6.5;
    if (correctCount >= 23) return 6.0;
    if (correctCount >= 18) return 5.5;
    if (correctCount >= 16) return 5.0;
    if (correctCount >= 13) return 4.5;
    if (correctCount >= 10) return 4.0;
    if (correctCount >= 8) return 3.5;
    if (correctCount >= 6) return 3.0;
    if (correctCount >= 4) return 2.5;
    if (correctCount === 3) return 2.0;
    if (correctCount === 2) return 1.5;
    if (correctCount === 1) return 1.0;
    return 0.0;
}

/**
 * Convert Reading (Academic) correct count (0-40) to IELTS Band Score
 */
export function convertReadingBand(correctCount: number): number {
    if (correctCount >= 39) return 9.0;
    if (correctCount >= 37) return 8.5;
    if (correctCount >= 35) return 8.0;
    if (correctCount >= 33) return 7.5;
    if (correctCount >= 30) return 7.0;
    if (correctCount >= 27) return 6.5;
    if (correctCount >= 23) return 6.0;
    if (correctCount >= 19) return 5.5;
    if (correctCount >= 15) return 5.0;
    if (correctCount >= 13) return 4.5;
    if (correctCount >= 10) return 4.0;
    if (correctCount >= 8) return 3.5;
    if (correctCount >= 6) return 3.0;
    if (correctCount >= 4) return 2.5;
    if (correctCount === 3) return 2.0;
    if (correctCount === 2) return 1.5;
    if (correctCount === 1) return 1.0;
    return 0.0;
}

/**
 * Calculate overall band score from 4 modules
 */
export function calculateOverallBand(scores: number[]): number {
    if (!scores || scores.length === 0) return 0;
    const avg = scores.reduce((a, b) => a + b, 0) / scores.length;
    const fraction = avg - Math.floor(avg);
    if (fraction < 0.25) {
        return Math.floor(avg);
    } else if (fraction < 0.75) {
        return Math.floor(avg) + 0.5;
    } else {
        return Math.ceil(avg);
    }
}

export interface AttemptScores {
    listening: number | null;
    reading: number | null;
    writing: number | null;
    speaking: number | null;
    listeningBand: number | null;
    readingBand: number | null;
    writingBand: number | null;
    speakingBand: number | null;
    overallBand: number | null;
}

interface ScoredAttemptType {
    type?: { name?: string } | null;
    is_correct_count?: number | string | null;
    score?: number | string | null;
}

interface ScoredAttempt {
    attempt_types?: ScoredAttemptType[] | null;
}

export function extractAttemptScores(attempt: ScoredAttempt | null | undefined): AttemptScores {
    const result: AttemptScores = {
        listening: null,
        reading: null,
        writing: null,
        speaking: null,
        listeningBand: null,
        readingBand: null,
        writingBand: null,
        speakingBand: null,
        overallBand: null,
    };

    if (!attempt || !attempt.attempt_types) {
        return result;
    }

    const validBands: number[] = [];

    attempt.attempt_types.forEach((typeItem) => {
        const typeName = typeItem.type?.name;
        if (typeName === 'Listening') {
            result.listening = Number(typeItem.is_correct_count ?? 0);
            result.listeningBand = convertListeningBand(result.listening);
            validBands.push(result.listeningBand);
        } else if (typeName === 'Reading') {
            result.reading = Number(typeItem.is_correct_count ?? 0);
            result.readingBand = convertReadingBand(result.reading);
            validBands.push(result.readingBand);
        } else if (typeName === 'Writing') {
            result.writingBand = Number(typeItem.is_correct_count ?? 0) / 2;
            result.writing = result.writingBand;
            validBands.push(result.writingBand);
        } else if (typeName === 'Speaking') {
            result.speakingBand = Number(typeItem.score ?? 0);
            result.speaking = result.speakingBand;
            validBands.push(result.speakingBand);
        }
    });

    result.overallBand = validBands.length > 0 ? calculateOverallBand(validBands) : null;

    return result;
}
