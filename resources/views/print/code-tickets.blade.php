{{--
    Candidate code tickets for an 80 mm thermal receipt printer (Xprinter): ~72 mm printable width,
    black only, one ticket per page (the driver cuts after each page). The code is printed as large as fits
    on one line. A partner center's ticket also has its logo (grayscale) / name on top and a small
    "Powered by Mynine" line; the Mynine center's tickets print only the code.
    Opens the print dialog on load and closes / goes back after printing.
--}}
@php
    // Monospace bold glyphs advance ~0.6em; keep a small safety margin inside the 72 mm area.
    $fontSize = fn (string $code) => round(min(16, 68 / (max(1, mb_strlen($code)) * 0.62)), 2);
@endphp
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $mock->name }} — {{ __('code_tickets_title') }}</title>
    <style>
        @page { size: 80mm auto; margin: 0; }
        * { box-sizing: border-box; }
        html, body { margin: 0; padding: 0; background: #fff; color: #000; }
        body { width: 72mm; margin: 0 auto; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
        .ticket {
            width: 72mm;
            padding: 4mm 0;
            text-align: center;
            page-break-after: always;
            break-after: page;
        }
        .ticket:last-child { page-break-after: auto; break-after: auto; }
        .code {
            display: block;
            font-family: "Courier New", "Liberation Mono", "DejaVu Sans Mono", Menlo, Consolas, monospace;
            font-weight: 900;
            line-height: 1;
            letter-spacing: 0;
            white-space: nowrap;
            color: #000;
        }
        .center-logo { display: block; max-width: 40mm; max-height: 14mm; margin: 0 auto 1.5mm; filter: grayscale(1) contrast(1.4); }
        .center-name { display: block; font-family: Arial, "Helvetica Neue", sans-serif; font-size: 3.6mm; font-weight: 700; line-height: 1.2; margin: 0 2mm 2.5mm; word-wrap: break-word; }
        .powered { display: block; font-family: Arial, "Helvetica Neue", sans-serif; font-size: 2.4mm; line-height: 1; margin-top: 2.5mm; }
        @media screen {
            body { padding: 8px 0; }
            .ticket { border-bottom: 1px dashed #000; }
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
                <span class="center-name">{{ $branding->name }}</span>
            @endif
            <span class="code" style="font-size: {{ $fontSize($student->code) }}mm">{{ $student->code }}</span>
            @if ($branding)
                <span class="powered">Powered by Mynine</span>
            @endif
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
