<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Mock result</title>
    {{-- The IELTS Test Report Form layout, issued under the center's own name: no IELTS / partner marks or
         validation stamp, and the note + footer say it is a mock result. Data we do not keep gets a default. --}}
    <style>
        @page { margin: 30pt 34pt 24pt; }
        body { font-family: 'DejaVu Sans', sans-serif; font-size: 10px; color: #111; margin: 0; }
        table { border-collapse: collapse; }
        .w100 { width: 100%; }
        .lbl { font-size: 10.5px; color: #222; white-space: nowrap; padding-right: 8pt; vertical-align: middle; line-height: 1.25; }
        .f { border: 0.9pt solid #333; padding: 0 9pt; height: 26pt; font-size: 10.5px; vertical-align: middle; }
        .g { background: #d9d9d9; }
        .rule { border-top: 0.8pt solid #555; }
        .h2 { font-size: 12.5px; font-weight: bold; }
        .rows { border-collapse: separate; border-spacing: 0 7pt; margin: -7pt 0; }
        .brand { font-size: 34px; font-weight: bold; letter-spacing: -0.5pt; line-height: 1; }
        .logo { max-height: 48pt; max-width: 120pt; }
        .watermark { position: absolute; top: 250pt; left: 0; right: 0; text-align: center; opacity: 0.06; }
        .watermark img { width: 330pt; }
        .note { font-size: 6.6px; font-style: italic; line-height: 1.3; }
        .photo { width: 112pt; height: 108pt; background: #e5e5e5; border: 0.6pt solid #bbb; text-align: center; vertical-align: middle; color: #8a8a8a; font-size: 34px; font-weight: bold; }
        .sl { font-size: 10.5px; font-weight: bold; white-space: nowrap; padding-right: 6pt; }
        .sc { border: 0.9pt solid #333; background: #d9d9d9; width: 34pt; height: 32pt; text-align: center; font-size: 10.5px; }
        .stamp { border: 0.9pt solid #333; height: 92pt; text-align: center; vertical-align: top; padding-top: 6pt; font-size: 10px; font-weight: bold; }
        .stamp img { max-height: 50pt; max-width: 100pt; margin-top: 6pt; }
        .stamp .nm { margin-top: 22pt; font-size: 12px; }
        .comments { border: 0.9pt solid #333; height: 78pt; }
        .footer { border-top: 0.8pt solid #555; padding-top: 5pt; font-size: 8px; text-align: center; }
        .page-break { page-break-after: always; }
    </style>
</head>
<body>
@php
    // No uploaded logo: the Mynine mark.
    $mynineIcon = public_path('images/icons/mynine-icon.png');
    $mynineLogo = is_file($mynineIcon) ? 'data:image/png;base64,'.base64_encode((string) file_get_contents($mynineIcon)) : null;
@endphp
@foreach ($sheets as $sheet)
    @php
        $branding = $sheet['branding'] ?? null;
        $logo = $branding?->logoDataUri() ?: $mynineLogo;
        $initials = collect(preg_split('/\s+/u', trim((string) $sheet['name'])))->filter()->take(2)
            ->map(fn ($w) => mb_strtoupper(mb_substr($w, 0, 1)))->implode('');
    @endphp

    @if ($logo)
        <div class="watermark"><img src="{{ $logo }}" alt=""></div>
    @endif

    {{-- Header --}}
    <table class="w100">
        <tr>
            <td style="vertical-align: bottom;">
                <table><tr>
                    @if ($logo)
                        <td style="padding-right: 10pt; vertical-align: middle;"><img class="logo" src="{{ $logo }}" alt=""></td>
                    @endif
                    <td style="vertical-align: middle;"><div class="brand"><span class="center-name">{{ $sheet['center_name'] }}</span></div></td>
                </tr></table>
                <div style="font-size: 13.5px; font-weight: bold; margin-top: 5pt;">Test Report Form</div>
            </td>
            <td style="width: 196pt; vertical-align: bottom;">
                <table class="w100"><tr><td class="f" style="height: 18pt; text-align: center; font-size: 11.5px;">{{ $sheet['module'] }}</td></tr></table>
            </td>
        </tr>
    </table>

    <table class="w100" style="margin-top: 5pt;">
        <tr>
            <td style="width: 40pt; vertical-align: top; font-weight: bold; font-size: 9.5px;">NOTE</td>
            <td class="note">
                This form reports the result of an IELTS-format mock examination held at {{ $sheet['center_name'] }}{{ $sheet['mock'] ? ' ('.$sheet['mock'].')' : '' }}. It is NOT an official IELTS Test Report Form
                and must not be used for admission, immigration or employment. Band scores are calculated with the official IELTS band tables and estimate the candidate's current level.
            </td>
        </tr>
    </table>

    <table class="w100" style="margin-top: 9pt;">
        <tr>
            <td class="lbl">Centre Number</td>
            <td class="f" style="width: 82pt;">{{ $sheet['centre_number'] }}</td>
            <td class="lbl" style="padding-left: 18pt;">Date</td>
            <td class="f" style="width: 104pt;">{{ $sheet['date'] }}</td>
            <td class="lbl" style="padding-left: 14pt;">Candidate Number</td>
            <td class="f" style="width: 74pt;">{{ $sheet['code'] }}</td>
        </tr>
    </table>

    <div class="rule" style="margin: 9pt 0 7pt;"></div>

    {{-- Candidate details + photo --}}
    <table class="w100">
        <tr>
            <td style="vertical-align: top;">
                <div class="h2" style="margin-bottom: 8pt;">Candidate Details</div>
                <table class="w100 rows">
                    <tr><td class="lbl" style="width: 76pt;">Family Name</td><td class="f g" colspan="2">{{ mb_strtoupper($sheet['family']) }}</td></tr>
                    <tr><td class="lbl">First Name(s)</td><td class="f g" colspan="2">{{ mb_strtoupper($sheet['first']) }}</td></tr>
                    <tr><td class="lbl">Candidate ID</td><td class="f g" style="width: 180pt;">{{ $sheet['code'] }}</td><td></td></tr>
                </table>
            </td>
            <td style="width: 124pt; vertical-align: bottom; padding-left: 12pt;">
                <table class="w100"><tr><td class="photo">{{ $initials ?: '—' }}</td></tr></table>
            </td>
        </tr>
    </table>

    <div class="rule" style="margin: 9pt 0;"></div>

    <table class="w100 rows">
        <tr>
            <td class="lbl" style="width: 76pt;">Date of Birth</td>
            <td class="f" style="width: 96pt;">-</td>
            <td class="lbl" style="padding-left: 16pt; text-align: right;">Sex (M/F)</td>
            <td class="f" style="width: 22pt; text-align: center;">-</td>
            <td class="lbl" style="padding-left: 12pt;">Scheme Code</td>
            <td class="f" style="width: 100pt;">Private Candidate</td>
        </tr>
        <tr><td class="lbl">Country or<br>Region of Origin</td><td class="f" colspan="5"></td></tr>
        <tr><td class="lbl">Country of<br>Nationality</td><td class="f" colspan="5">UZBEKISTAN</td></tr>
        <tr><td class="lbl">First Language</td><td class="f" colspan="5">UZBEK</td></tr>
    </table>

    <div class="rule" style="margin: 9pt 0 7pt;"></div>

    {{-- Test results --}}
    <div class="h2" style="margin-bottom: 6pt;">Test Results</div>
    <table class="w100">
        <tr>
            @foreach (['listening' => 'Listening', 'reading' => 'Reading', 'writing' => 'Writing', 'speaking' => 'Speaking'] as $key => $label)
                <td class="sl">{{ $label }}</td>
                <td class="sc">{{ $sheet[$key] !== null ? number_format($sheet[$key], 1) : '—' }}</td>
                <td style="width: 9pt;"></td>
            @endforeach
            <td class="sl" style="text-align: center; line-height: 1.2;">Overall<br>Band<br>Score</td>
            <td class="sc">{{ number_format($sheet['overall'], 1) }}</td>
            <td style="width: 9pt;"></td>
            <td class="sl" style="text-align: center; line-height: 1.2;">CEFR<br>Level</td>
            <td class="sc">{{ $sheet['cefr'] }}</td>
        </tr>
    </table>

    <div class="rule" style="margin: 7pt 0 6pt;"></div>

    {{-- Comments + stamps --}}
    <table class="w100">
        <tr>
            <td style="vertical-align: top; padding-right: 14pt;">
                <div style="font-size: 10px; font-weight: bold; margin-bottom: 6pt;">Administrator Comments</div>
                <table class="w100"><tr><td class="comments"></td></tr></table>
            </td>
            <td style="width: 114pt; padding-right: 10pt; vertical-align: top;">
                <table class="w100"><tr><td class="stamp">Centre stamp</td></tr></table>
            </td>
            <td style="width: 114pt; vertical-align: top;">
                <table class="w100"><tr><td class="stamp">
                    Issued by
                    @if ($logo)
                        <br><img src="{{ $logo }}" alt="">
                        <div style="font-size: 10px; margin-top: 4pt;">{{ $sheet['center_name'] }}</div>
                    @else
                        <div class="nm">{{ $sheet['center_name'] }}</div>
                    @endif
                </td></tr></table>
            </td>
        </tr>
    </table>

    <table class="w100" style="margin-top: 6pt;">
        <tr>
            <td style="width: 44%;"></td>
            <td class="lbl" style="font-weight: bold; font-size: 9.5px; vertical-align: bottom; padding-bottom: 4pt;">Administrator's<br>Signature</td>
            <td style="width: 10pt;"></td>
            <td style="border-bottom: 0.9pt solid #333; width: 238pt; height: 30pt;"></td>
        </tr>
    </table>

    <table class="w100" style="margin-top: 14pt;">
        <tr>
            <td style="width: 34%;"></td>
            <td class="lbl">Date</td>
            <td class="f" style="width: 94pt;">{{ $sheet['issued'] }}</td>
            <td class="lbl" style="padding-left: 18pt;">Test Report<br>Form Number</td>
            <td class="f g" style="width: 150pt;">{{ $sheet['form_number'] }}</td>
        </tr>
    </table>

    <div style="height: 60pt;"></div>
    <div class="footer">
        This mock examination result was issued by {{ $sheet['center_name'] }} and is not an official IELTS Test Report Form
        @if ($branding?->partner)
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
