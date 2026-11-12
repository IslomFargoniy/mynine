<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Mock result</title>
    <style>
        @page { margin: 40pt 45pt; }
        body { font-family: 'DejaVu Sans', sans-serif; font-size: 11px; color: #1e293b; margin: 0; }
        .sheet { border: 2pt solid #1e1b4b; padding: 28pt 30pt; height: 700pt; }
        .center { text-align: center; }
        .brand { font-size: 30px; font-weight: bold; color: #1e1b4b; letter-spacing: 3pt; }
        .subtitle { font-size: 11px; color: #64748b; letter-spacing: 2pt; text-transform: uppercase; margin-top: 4pt; }
        .divider { border-top: 1pt solid #cbd5e1; margin: 22pt 0; }
        table.info { width: 100%; border-collapse: collapse; }
        table.info td { padding: 6pt 0; font-size: 12px; }
        table.info td.label { color: #64748b; width: 120pt; }
        table.info td.value { font-weight: bold; font-size: 14px; }
        table.bands { width: 100%; border-collapse: separate; border-spacing: 8pt; margin-top: 10pt; }
        table.bands td { border: 1pt solid #c7d2fe; background: #eef2ff; border-radius: 6pt; text-align: center; padding: 14pt 4pt; width: 25%; }
        .band-label { font-size: 10px; color: #4338ca; text-transform: uppercase; letter-spacing: 1pt; font-weight: bold; }
        .band-value { font-size: 28px; font-weight: bold; color: #1e1b4b; margin-top: 6pt; }
        .overall { margin-top: 26pt; background: #1e1b4b; color: #ffffff; border-radius: 8pt; padding: 18pt; text-align: center; }
        .overall-label { font-size: 12px; letter-spacing: 2pt; text-transform: uppercase; }
        .overall-value { font-size: 46px; font-weight: bold; margin-top: 4pt; }
        .footer { margin-top: 40pt; font-size: 9px; color: #94a3b8; text-align: center; }
        .page-break { page-break-after: always; }
        .center-logo { max-height: 44pt; max-width: 200pt; margin-bottom: 4pt; }
        .center-name { font-size: 24px; font-weight: bold; color: #1e1b4b; letter-spacing: 1pt; }
        .powered { margin-top: 4pt; font-size: 8px; color: #94a3b8; }
    </style>
</head>
<body>
@foreach ($sheets as $sheet)
    <div class="sheet">
        <div class="center">
            @if ($branding = $sheet['branding'] ?? null)
                @if ($logo = $branding->logoDataUri())
                    <img class="center-logo" src="{{ $logo }}" alt="">
                @endif
                <div class="center-name">{{ $branding->name }}</div>
            @else
                <div class="brand">Mynine</div>
            @endif
            <div class="subtitle">IELTS Mock Exam Result</div>
        </div>

        <div class="divider"></div>

        <table class="info">
            <tr><td class="label">Candidate</td><td class="value">{{ $sheet['name'] }}</td></tr>
            <tr><td class="label">Candidate code</td><td class="value">{{ $sheet['code'] }}</td></tr>
            <tr><td class="label">Exam</td><td class="value">{{ $sheet['mock'] }}</td></tr>
            <tr><td class="label">Date</td><td class="value">{{ $sheet['date'] }}</td></tr>
        </table>

        <div class="divider"></div>

        <table class="bands">
            <tr>
                @foreach (['listening' => 'Listening', 'reading' => 'Reading', 'writing' => 'Writing', 'speaking' => 'Speaking'] as $key => $label)
                    <td>
                        <div class="band-label">{{ $label }}</div>
                        <div class="band-value">{{ $sheet[$key] !== null ? number_format($sheet[$key], 1) : '—' }}</div>
                    </td>
                @endforeach
            </tr>
        </table>

        <div class="overall">
            <div class="overall-label">Overall Band Score</div>
            <div class="overall-value">{{ number_format($sheet['overall'], 1) }}</div>
        </div>

        @if ($sheet['branding'] ?? null)
            <div class="footer">{{ $sheet['branding']->name }} &middot; This is a mock exam result and not an official IELTS Test Report Form.</div>
            <div class="footer powered" style="margin-top: 4pt;">Powered by Mynine</div>
        @else
            <div class="footer">mynine.uz &middot; This is a mock exam result and not an official IELTS Test Report Form.</div>
        @endif
    </div>
    @if (! $loop->last)
        <div class="page-break"></div>
    @endif
@endforeach
</body>
</html>
