<?php

namespace App\Services;

use App\Models\MockStudent;
use App\Support\CenterBranding;
use App\Support\Pdf;
use Carbon\Carbon;

/**
 * The candidate's result sheet (Test Report Form layout under the center's own name): printed at the reception and
 * sent by the Telegram bot for a candidate number.
 */
class ResultSheetService
{
    /** @var array<int, array{0: ?CenterBranding, 1: ?string}> */
    private array $centers = [];

    public function __construct(private readonly MockResultService $results) {}

    /**
     * The sheet's data, or null while the result is not ready (a module still to be checked).
     *
     * @return array<string, mixed>|null
     */
    public function sheet(MockStudent $student): ?array
    {
        $result = $this->results->result($student);
        if (! $result['ready']) {
            return null;
        }

        $ownerId = (int) ($student->mock?->owner_id ?? 0);
        if (! array_key_exists($ownerId, $this->centers)) {
            $branding = CenterBranding::forCenter($ownerId ?: null);
            $this->centers[$ownerId] = [$branding, $branding?->logoDataUri() ?? CenterBranding::uploadedLogoDataUri($ownerId ?: null)];
        }
        [$branding, $logo] = $this->centers[$ownerId];

        $testDate = $student->mock?->started_at ? Carbon::parse($student->mock->started_at) : null;
        $variant = $student->mock?->test?->variant === 'general' ? 'general' : 'academic';
        $centreNumber = strtoupper($branding?->code ?: 'MYNINE');

        return [
            'branding' => $branding,
            'logo' => $logo,
            'center_name' => $branding?->name ?: 'Mynine',
            'centre_number' => $centreNumber,
            'module' => $variant === 'general' ? 'GENERAL TRAINING' : 'ACADEMIC',
            'name' => $student->name,
            ...self::splitName((string) $student->name),
            'code' => $student->code,
            'mock' => $student->mock?->name,
            'date' => $testDate ? strtoupper($testDate->format('d/M/Y')) : '',
            'issued' => now()->format('d/m/Y'),
            'form_number' => ($testDate ?? now())->format('y').preg_replace('/[^A-Z0-9]/', '', $centreNumber).$student->code.'M'.$student->id.($variant === 'general' ? 'G' : 'A'),
            'cefr' => self::cefr((float) $result['overall']),
            'listening' => $result['listening'],
            'reading' => $result['reading'],
            'writing' => $result['writing'],
            'speaking' => $result['speaking'],
            'overall' => $result['overall'],
        ];
    }

    /**
     * The PDF bytes of the given sheets.
     *
     * @param  array<int, array<string, mixed>>  $sheets
     */
    public function pdf(array $sheets): string
    {
        return Pdf::output('pdf.result-sheet', compact('sheets'));
    }

    /**
     * Family name / first name(s) for the report form. Uzbek names are usually written "Family First"; a surname
     * suffix (-ov, -eva, -iy …) at the end means "First Family".
     *
     * @return array{family: string, first: string}
     */
    public static function splitName(string $name): array
    {
        $words = preg_split('/\s+/u', trim($name), -1, PREG_SPLIT_NO_EMPTY) ?: [];
        if (count($words) < 2) {
            return ['family' => '-', 'first' => $words[0] ?? '-'];
        }
        $surname = '/(ov|ova|ev|eva|yev|yeva|iy|aya|in|ina|zoda|dze|yan|enko)$/iu';
        if (preg_match($surname, end($words)) && ! preg_match($surname, $words[0])) {
            return ['family' => array_pop($words), 'first' => implode(' ', $words)];
        }

        return ['family' => array_shift($words), 'first' => implode(' ', $words)];
    }

    /** CEFR level of an overall band (as on the web result page). */
    public static function cefr(float $overall): string
    {
        return match (true) {
            $overall >= 8.5 => 'C2',
            $overall >= 7.0 => 'C1',
            $overall >= 5.5 => 'B2',
            $overall >= 4.0 => 'B1',
            default => 'A2',
        };
    }
}
