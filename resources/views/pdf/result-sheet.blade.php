<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Mock result</title>
    {{-- Laid out like an IELTS Test Report Form, issued under the center's own name (no IELTS / partner marks). --}}
    <style>
        @page { margin: 26pt 30pt; }
        body { font-family: 'DejaVu Sans', sans-serif; font-size: 10.5px; color: #000; margin: 0; }
        table { border-collapse: collapse; }
        .w100 { width: 100%; }
        .box { border: 1pt solid #000; padding: 6pt 8pt; font-size: 12px; }
        .grey { background: #b5b5b5; }
        .label { font-size: 12px; padding-right: 8pt; white-space: nowrap; }
        .rule { border-top: 0.8pt solid #444; margin: 9pt 0; }
        .h2 { font-size: 15px; font-weight: bold; margin: 0 0 7pt; }
        .logo { max-height: 52pt; max-width: 210pt; }
        .center-name { font-size: 26px; font-weight: bold; letter-spacing: 0.5pt; line-height: 1.1; }
        .title { font-size: 19px; font-weight: bold; margin-top: 6pt; }
        .note { font-size: 8px; font-style: italic; line-height: 1.35; }
        table.gap { border-collapse: separate; border-spacing: 0 6pt; margin: -6pt 0; }
        .score-label { font-size: 11.5px; font-weight: bold; padding-right: 5pt; white-space: nowrap; }
        .score { border: 1pt solid #000; background: #b5b5b5; width: 32pt; height: 34pt; text-align: center; font-size: 13px; }
        .stamp { border: 1pt solid #000; height: 108pt; text-align: center; vertical-align: top; padding-top: 5pt; font-weight: bold; font-size: 12px; }
        .stamp-name { margin-top: 18pt; font-size: 13px; }
        .stamp img { max-height: 58pt; max-width: 120pt; margin-top: 10pt; }
        .comments { border: 1.4pt solid #000; height: 92pt; padding: 6pt; font-size: 11px; vertical-align: top; }
        .footer { border-top: 0.8pt solid #444; padding-top: 6pt; font-size: 9.5px; text-align: center; }
        .page-break { page-break-after: always; }
    </style>
</head>
<body>
@foreach ($sheets as $sheet)
    @php($branding = $sheet['branding'] ?? null)
    {{-- Header: center logo / name, "Test Report Form", module box --}}
    <table class="w100">
        <tr>
            <td style="vertical-align: bottom;">
                @if ($branding && ($logo = $branding->logoDataUri()))
                    <img class="logo" src="{{ $logo }}" alt=""><br>
                @endif
                <span class="center-name">{{ $sheet['center_name'] }}</span>
                <div class="title">Test Report Form</div>
            </td>
            <td style="width: 190pt; vertical-align: bottom; padding-bottom: 3pt;">
                <div class="box" style="text-align: center;">{{ $sheet['module'] }}</div>
            </td>
        </tr>
    </table>

    <table class="w100" style="margin-top: 6pt;">
        <tr>
            <td style="width: 34pt; vertical-align: top; font-weight: bold; font-size: 12px;">NOTE</td>
            <td class="note">
                This is the result of an IELTS-format mock exam held at {{ $sheet['center_name'] }}{{ $sheet['mock'] ? ' ('.$sheet['mock'].')' : '' }}.<br>
                It is <strong>not</strong> an official IELTS Test Report Form and cannot be used for admission, immigration or employment.<br>
                Band scores are calculated with the official IELTS band tables and are an estimate of the candidate's current level.
            </td>
        </tr>
    </table>

    <table class="w100" style="margin-top: 12pt;">
        <tr>
            <td class="label">Centre Number</td>
            <td class="box" style="width: 92pt;">{{ $sheet['centre_number'] }}</td>
            <td class="label" style="padding-left: 22pt;">Date</td>
            <td class="box" style="width: 98pt;">{{ $sheet['date'] }}</td>
            <td class="label" style="padding-left: 22pt;">Candidate Number</td>
            <td class="box" style="width: 78pt;">{{ $sheet['code'] }}</td>
        </tr>
    </table>

    <div class="rule"></div>

    {{-- Candidate details --}}
    <div class="h2">Candidate Details</div>
    <table class="w100 gap">
        <tr>
            <td class="label" style="width: 92pt;">Candidate Name</td>
            <td class="box grey" colspan="2">{{ mb_strtoupper($sheet['name']) }}</td>
        </tr>
        <tr>
            <td class="label">Candidate ID</td>
            <td class="box grey" style="width: 200pt;">{{ $sheet['code'] }}</td><td></td>
        </tr>
        <tr>
            <td class="label">Phone</td>
            <td class="box" style="width: 200pt;">{{ $sheet['phone'] ?: '—' }}</td><td></td>
        </tr>
        <tr>
            <td class="label">Test</td>
            <td class="box" colspan="2">{{ $sheet['mock'] ?: '—' }}</td>
        </tr>
    </table>

    <div class="rule"></div>

    {{-- Test results --}}
    <div class="h2">Test Results</div>
    <table class="w100">
        <tr>
            @foreach (['listening' => 'Listening', 'reading' => 'Reading', 'writing' => 'Writing', 'speaking' => 'Speaking'] as $key => $label)
                <td class="score-label">{{ $label }}</td>
                <td class="score">{{ $sheet[$key] !== null ? number_format($sheet[$key], 1) : '—' }}</td>
                <td style="width: 7pt;"></td>
            @endforeach
            <td class="score-label" style="line-height: 1.15;">Overall<br>Band<br>Score</td>
            <td class="score">{{ number_format($sheet['overall'], 1) }}</td>
            <td style="width: 7pt;"></td>
            <td class="score-label" style="line-height: 1.15;">CEFR<br>Level</td>
            <td class="score">{{ $sheet['cefr'] }}</td>
        </tr>
    </table>

    <div class="rule"></div>

    {{-- Comments, center stamp, issuer --}}
    <table class="w100">
        <tr>
            <td style="vertical-align: top; padding-right: 16pt;">
                <div style="font-size: 12px; font-weight: bold; margin-bottom: 8pt;">Administrator Comments</div>
                <table class="w100"><tr><td class="comments"></td></tr></table>
            </td>
            <td style="width: 118pt; padding-right: 8pt;">
                <table class="w100"><tr><td class="stamp">
                    Centre stamp
                </td></tr></table>
            </td>
            <td style="width: 118pt;">
                <table class="w100"><tr><td class="stamp">
                    Issued by
                    @if ($branding && ($logo = $branding->logoDataUri()))
                        <br><img src="{{ $logo }}" alt="">
                    @else
                        <div class="stamp-name">{{ $sheet['center_name'] }}</div>
                    @endif
                </td></tr></table>
            </td>
        </tr>
    </table>

    <table class="w100" style="margin-top: 14pt;">
        <tr>
            <td style="width: 50%;"></td>
            <td class="label" style="vertical-align: bottom;">Administrator's<br>Signature</td>
            <td style="border-bottom: 0.8pt solid #000; width: 200pt; height: 30pt;"></td>
        </tr>
    </table>

    <table class="w100" style="margin-top: 14pt;">
        <tr>
            <td style="width: 22%;"></td>
            <td class="label">Date</td>
            <td class="box" style="width: 92pt; text-align: center;">{{ $sheet['issued'] }}</td>
            <td class="label" style="padding-left: 18pt; line-height: 1.15;">Test Report Form<br>Number</td>
            <td class="box grey" style="text-align: center;">{{ $sheet['form_number'] }}</td>
        </tr>
    </table>

    <div style="height: 120pt;"></div>
    <div class="footer">
        {{ $sheet['center_name'] }} &middot; IELTS-format mock exam result &middot; not an official IELTS Test Report Form
        @if ($branding)
            &middot; Powered by Mynine
        @else
            &middot; mynine.uz
        @endif
    </div>

    @if (! $loop->last)
        <div class="page-break"></div>
    @endif
@endforeach
</body>
</html>
