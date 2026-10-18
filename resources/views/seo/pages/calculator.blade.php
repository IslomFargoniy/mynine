@extends('seo.layout')

@section('title', 'IELTS ball kalkulyatori — Overall band score hisoblash')
@section('description', "IELTS band score kalkulyatori: Listening va Reading to'g'ri javoblar sonini band'ga aylantiring, Writing va Speaking ballarini kiriting va umumiy (overall) ballni CEFR darajasi bilan bilib oling.")
@section('keywords', 'IELTS ball kalkulyatori, IELTS band score calculator, IELTS overall hisoblash, IELTS listening ball, IELTS reading ball, IELTS ball jadvali')

@php
    $listening = [[39, 9.0], [37, 8.5], [35, 8.0], [32, 7.5], [30, 7.0], [26, 6.5], [23, 6.0], [18, 5.5], [16, 5.0], [13, 4.5], [10, 4.0], [8, 3.5], [6, 3.0], [4, 2.5], [3, 2.0], [2, 1.5], [1, 1.0]];
    $reading = [[39, 9.0], [37, 8.5], [35, 8.0], [33, 7.5], [30, 7.0], [27, 6.5], [23, 6.0], [19, 5.5], [15, 5.0], [13, 4.5], [10, 4.0], [8, 3.5], [6, 3.0], [4, 2.5], [3, 2.0], [2, 1.5], [1, 1.0]];
    $range = function (array $table, int $i) {
        $from = $table[$i][0];
        $to = $i === 0 ? 40 : $table[$i - 1][0] - 1;
        return $from === $to ? (string) $from : $from.'–'.$to;
    };
@endphp

@section('content')
    <section class="bg-gradient-to-b from-[#6556ff]/10 to-white">
        <div class="mx-auto max-w-4xl px-4 pb-10 pt-10">
            @include('seo.partials.breadcrumbs', ['items' => [['Bosh sahifa', route('home')], ['IELTS ball kalkulyatori', null]]])
            <h1 class="mt-6 text-4xl font-extrabold tracking-tight text-gray-900 md:text-5xl">IELTS ball kalkulyatori</h1>
            <p class="mt-4 text-lg text-gray-600">Listening va Reading'dagi to'g'ri javoblar sonini, Writing va Speaking ballarini kiriting — kalkulyator har bir bo'lim band'ini va umumiy (overall) ballni IELTS yaxlitlash qoidasi bo'yicha hisoblaydi.</p>
        </div>
    </section>

    <section class="mx-auto max-w-4xl px-4 pb-14">
        <form id="calc" class="grid gap-5 rounded-3xl border border-gray-100 p-6 shadow-sm md:grid-cols-2" onsubmit="return false">
            <label class="block">
                <span class="text-sm font-semibold text-gray-800">Listening — to'g'ri javoblar (0–40)</span>
                <input type="number" min="0" max="40" step="1" name="listening" inputmode="numeric" class="mt-2 w-full rounded-xl border border-gray-200 px-4 py-3 text-lg focus:border-[#6556ff] focus:outline-none" placeholder="masalan, 31">
            </label>
            <label class="block">
                <span class="text-sm font-semibold text-gray-800">Reading (Academic) — to'g'ri javoblar (0–40)</span>
                <input type="number" min="0" max="40" step="1" name="reading" inputmode="numeric" class="mt-2 w-full rounded-xl border border-gray-200 px-4 py-3 text-lg focus:border-[#6556ff] focus:outline-none" placeholder="masalan, 28">
            </label>
            <label class="block">
                <span class="text-sm font-semibold text-gray-800">Writing band (0–9)</span>
                <select name="writing" class="mt-2 w-full rounded-xl border border-gray-200 px-4 py-3 text-lg focus:border-[#6556ff] focus:outline-none">
                    <option value="">tanlang</option>
                    @for ($b = 9; $b >= 0; $b -= 0.5)<option value="{{ $b }}">{{ number_format($b, 1) }}</option>@endfor
                </select>
            </label>
            <label class="block">
                <span class="text-sm font-semibold text-gray-800">Speaking band (0–9)</span>
                <select name="speaking" class="mt-2 w-full rounded-xl border border-gray-200 px-4 py-3 text-lg focus:border-[#6556ff] focus:outline-none">
                    <option value="">tanlang</option>
                    @for ($b = 9; $b >= 0; $b -= 0.5)<option value="{{ $b }}">{{ number_format($b, 1) }}</option>@endfor
                </select>
            </label>

            <div class="rounded-2xl bg-[#6556ff] p-6 text-white md:col-span-2" aria-live="polite">
                <div class="grid grid-cols-2 gap-4 text-center sm:grid-cols-5">
                    <div><p class="text-xs uppercase tracking-wide text-white/70">Listening</p><p class="text-2xl font-bold" data-out="listening">—</p></div>
                    <div><p class="text-xs uppercase tracking-wide text-white/70">Reading</p><p class="text-2xl font-bold" data-out="reading">—</p></div>
                    <div><p class="text-xs uppercase tracking-wide text-white/70">Writing</p><p class="text-2xl font-bold" data-out="writing">—</p></div>
                    <div><p class="text-xs uppercase tracking-wide text-white/70">Speaking</p><p class="text-2xl font-bold" data-out="speaking">—</p></div>
                    <div class="col-span-2 sm:col-span-1"><p class="text-xs uppercase tracking-wide text-white/70">Overall</p><p class="text-4xl font-extrabold" data-out="overall">—</p></div>
                </div>
                <p class="mt-4 text-center text-sm text-white/80" data-out="cefr">To'rtta bo'limni to'ldiring — umumiy ball va CEFR darajasi shu yerda chiqadi.</p>
            </div>
        </form>
        <p class="mt-3 text-sm text-gray-500">Jadvallar taxminiy: rasmiy IELTS konvertatsiyasi har bir test variantida bir-ikki javobga farq qilishi mumkin. General Training Reading uchun jadval boshqacha (bir xil band uchun ko'proq to'g'ri javob kerak).</p>
    </section>

    <section class="mx-auto max-w-4xl px-4 pb-14">
        <div class="prose prose-lg max-w-none">
            <h2>Overall band score qanday hisoblanadi</h2>
            <p>Umumiy ball to'rtta bo'lim ballarining o'rtacha arifmetigi bo'lib, eng yaqin yarim yoki butun band'gacha yaxlitlanadi:</p>
            <ul>
                <li>o'rtacha qiymatning kasr qismi <strong>0.25 dan kichik</strong> bo'lsa — pastga yaxlitlanadi (6.125 → 6.0);</li>
                <li><strong>0.25 dan 0.75 gacha</strong> bo'lsa — .5 ga (6.25 → 6.5, 6.625 → 6.5);</li>
                <li><strong>0.75 va undan katta</strong> bo'lsa — keyingi butun songa (6.75 → 7.0).</li>
            </ul>
            <p>Masalan, Listening 7.0, Reading 6.5, Writing 6.0 va Speaking 6.5 bo'lsa, o'rtacha 6.5 bo'ladi va overall ham 6.5. Batafsilroq: <a href="{{ route('blog.show', 'ielts-band-score-qanday-hisoblanadi') }}">IELTS band score qanday hisoblanadi</a>.</p>
        </div>

        <div class="mt-10 grid gap-8 md:grid-cols-2">
            @foreach (['Listening' => $listening, 'Reading (Academic)' => $reading] as $name => $table)
                <div>
                    <h2 class="text-xl font-bold text-gray-900">{{ $name }} ball jadvali</h2>
                    <table class="mt-4 w-full overflow-hidden rounded-xl border border-gray-200 text-left text-sm">
                        <thead class="bg-gray-50"><tr><th class="px-4 py-2">To'g'ri javoblar</th><th class="px-4 py-2">Band</th></tr></thead>
                        <tbody>
                            @foreach ($table as $i => [$min, $band])
                                @continue($band < 4.0)
                                <tr class="border-t border-gray-100"><td class="px-4 py-2">{{ $range($table, $i) }}</td><td class="px-4 py-2 font-semibold">{{ number_format($band, 1) }}</td></tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endforeach
        </div>
    </section>

    @include('seo.partials.latest-articles')

    <script>
        (function () {
            const L = @json($listening), R = @json($reading);
            const toBand = (table, n) => { for (const [min, band] of table) { if (n >= min) return band; } return 0; };
            const round = (avg) => { const f = avg - Math.floor(avg); return f < 0.25 ? Math.floor(avg) : (f < 0.75 ? Math.floor(avg) + 0.5 : Math.ceil(avg)); };
            const cefr = (b) => b >= 8.5 ? 'C2' : b >= 7 ? 'C1' : b >= 5.5 ? 'B2' : b >= 4 ? 'B1' : 'A2 yoki past';
            const form = document.getElementById('calc');
            const out = (k, v) => form.querySelector('[data-out="' + k + '"]').textContent = v;
            const fmt = (b) => b === null ? '—' : b.toFixed(1);
            function update() {
                const raw = (name) => form.elements[name].value === '' ? null : Number(form.elements[name].value);
                const l = raw('listening'), r = raw('reading');
                const bands = {
                    listening: l === null ? null : toBand(L, Math.min(40, Math.max(0, Math.round(l)))),
                    reading: r === null ? null : toBand(R, Math.min(40, Math.max(0, Math.round(r)))),
                    writing: raw('writing'),
                    speaking: raw('speaking'),
                };
                Object.entries(bands).forEach(([k, v]) => out(k, fmt(v)));
                const values = Object.values(bands);
                if (values.every((v) => v !== null)) {
                    const overall = round(values.reduce((a, b) => a + b, 0) / 4);
                    out('overall', overall.toFixed(1));
                    out('cefr', 'Taxminiy CEFR darajasi: ' + cefr(overall));
                } else {
                    out('overall', '—');
                }
            }
            form.addEventListener('input', update);
        })();
    </script>

    @push('jsonld')
    <script type="application/ld+json">
        {!! json_encode([
            '@context' => 'https://schema.org',
            '@type' => 'WebApplication',
            'name' => 'IELTS ball kalkulyatori',
            'url' => route('seo.page', 'ielts-ball-kalkulyatori'),
            'applicationCategory' => 'EducationalApplication',
            'operatingSystem' => 'Web',
            'inLanguage' => 'uz',
            'offers' => ['@type' => 'Offer', 'price' => '0', 'priceCurrency' => 'UZS'],
        ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) !!}
    </script>
    @endpush
@endsection
