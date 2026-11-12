{{--
    Candidate code tickets for an 80 mm thermal receipt printer (Xprinter), laid out like a shop receipt:
    header (center, mock, date), the code large, the candidate's name and a short instruction. Black only,
    one ticket per page (the driver cuts after each page). The page has an explicit size — Chrome ignores
    "size: 80mm auto" and falls back to A4. A partner center's ticket shows its logo (grayscale) and name on top and
    "Powered by Mynine" at the bottom ($branding from CenterBranding; null for the Mynine center).
    Opens the print dialog on load and closes / goes back after printing.
--}}
@php
    // Monospace bold glyphs advance ~0.6em; keep a small safety margin inside the 66 mm text area.
    $fontSize = fn (string $code) => round(min(15, 64 / (max(1, mb_strlen($code)) * 0.62)), 2);
    $examDate = $mock->started_at ? \Illuminate\Support\Carbon::parse($mock->started_at)->format('d.m.Y') : null;
@endphp
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $mock->name }} — {{ __('code_tickets_title') }}</title>
    <style>
        @page { size: 80mm 70mm; margin: 0; }
        * { box-sizing: border-box; }
        html, body { margin: 0; padding: 0; background: #fff; color: #000; }
        body {
            width: 80mm;
            font-family: "Courier New", "Liberation Mono", "DejaVu Sans Mono", Menlo, Consolas, monospace;
            -webkit-print-color-adjust: exact; print-color-adjust: exact;
        }
        .ticket {
            width: 80mm;
            height: 70mm;
            padding: 4mm 7mm 3mm;
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
            overflow: hidden;
            page-break-after: always;
            break-after: page;
        }
        .ticket:last-child { page-break-after: auto; break-after: auto; }
        .center-logo { display: block; max-width: 40mm; max-height: 12mm; margin: 0 auto 1mm; filter: grayscale(1) contrast(1.4); }
        .brand { font-size: 4.2mm; font-weight: 900; letter-spacing: 0.6mm; text-transform: uppercase; }
        .sub { font-size: 3mm; margin-top: 0.8mm; }
        .rule { width: 100%; border-top: 0.4mm dashed #000; margin: 2.5mm 0; }
        .label { font-size: 2.8mm; text-transform: uppercase; letter-spacing: 0.4mm; }
        .code { display: block; font-weight: 900; line-height: 1; white-space: nowrap; margin: 1.5mm 0 1.2mm; }
        .name { font-size: 3.4mm; font-weight: 700; max-width: 100%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        .note { font-size: 2.8mm; line-height: 1.35; }
        .foot { margin-top: auto; font-size: 2.4mm; }
        @media screen {
            body { margin: 8px auto; }
            .ticket { border: 1px dashed #999; margin-bottom: 8px; }
        }
    </style>
</head>
<body>
    @foreach ($students as $student)
        <div class="ticket" data-id="{{ $student->id }}">
            @if ($branding)
                @if ($logo = $branding->logoUrl())
                    <img class="center-logo" src="{{ $logo }}" alt="">
                @endif
                <div class="brand">{{ $branding->name }}</div>
            @else
                <div class="brand">Mynine · IELTS</div>
            @endif
            <div class="sub">{{ $mock->name }}@if ($examDate) · {{ $examDate }}@endif</div>
            <div class="rule"></div>
            <div class="label">{{ __('ticket_code_label') }}</div>
            <span class="code" style="font-size: {{ $fontSize($student->code) }}mm">{{ $student->code }}</span>
            <div class="name">{{ $student->name }}</div>
            <div class="rule"></div>
            <div class="note">{{ __('ticket_note') }}</div>
            <div class="foot">{{ $branding ? 'Powered by Mynine' : 'mynine.uz' }} · {{ now()->format('d.m.Y H:i') }}</div>
        </div>
    @endforeach

    <script>
        window.addEventListener('load', function () {
            window.addEventListener('afterprint', function () {
                if (window.opener) {
                    window.close();
                } else if (window.history.length > 1) {
                    window.history.back();
                }
            });
            window.setTimeout(function () { window.print(); }, 150);
        });
    </script>
</body>
</html>
