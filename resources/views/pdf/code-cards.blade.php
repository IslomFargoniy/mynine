<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Candidate codes - {{ $mock->name }}</title>
    <style>
        @page { margin: 20pt 22pt; }
        body { font-family: 'DejaVu Sans', sans-serif; font-size: 10px; color: #1e293b; margin: 0; }
        table.grid { width: 100%; border-collapse: separate; border-spacing: 8pt; }
        td.card { width: 50%; border: 1.5pt dashed #4f46e5; border-radius: 8pt; padding: 12pt; vertical-align: top; height: 165pt; }
        .brand { font-size: 9px; font-weight: bold; color: #4f46e5; letter-spacing: 1.5pt; text-transform: uppercase; }
        .mock { font-size: 9px; color: #64748b; margin-top: 2pt; }
        .name { font-size: 15px; font-weight: bold; margin: 8pt 0 6pt; }
        .code { background: #eef2ff; font-family: 'DejaVu Sans Mono', monospace; font-size: 20px; font-weight: bold; padding: 7pt; text-align: center; letter-spacing: 2pt; border-radius: 5pt; }
        .meta { margin-top: 8pt; font-size: 9.5px; }
        .meta b { color: #0f172a; }
        .hint { margin-top: 6pt; font-size: 8px; color: #64748b; }
        .page-break { page-break-after: always; }
    </style>
</head>
<body>
@foreach ($students->chunk(8) as $page)
    <table class="grid">
        @foreach ($page->chunk(2) as $row)
            <tr>
                @foreach ($row as $student)
                    <td class="card">
                        <div class="brand">Mynine Mock Exam</div>
                        <div class="mock">{{ $mock->name }} &middot; {{ $mock->started_at ? \Carbon\Carbon::parse($mock->started_at)->format('d.m.Y H:i') : '' }}</div>
                        <div class="name">{{ $student->name }}</div>
                        <div class="code">{{ $student->code }}</div>
                        <div class="meta">
                            Speaking: <b>{{ $student->speaking_at ? $student->speaking_at->format('d.m.Y H:i') : '—' }}</b>
                        </div>
                        <div class="hint">Enter this code on the Mynine exam computer. Keep the card until you receive your result.</div>
                    </td>
                @endforeach
                @if ($row->count() < 2)
                    <td></td>
                @endif
            </tr>
        @endforeach
    </table>
    @if (! $loop->last)
        <div class="page-break"></div>
    @endif
@endforeach
</body>
</html>
