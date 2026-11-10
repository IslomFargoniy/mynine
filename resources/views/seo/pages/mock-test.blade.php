@extends('seo.layout')

@section('title', "Onlayn IELTS mock test — haqiqiy imtihon formatida bepul sinov")
@section('description', "Mynine'da IELTS mock testni onlayn topshiring: Listening, Reading, Writing va Speaking, imtihondagidek taymer, avtomatik band score va AI yordamida Writing tahlili.")
@section('keywords', 'IELTS mock test, onlayn IELTS test, IELTS mock test online, IELTS sinov testi, IELTS practice test, IELTS test topshirish')

@section('content')
    <section class="pt-8">
        <div class="mx-auto w-[calc(100%-2rem)] max-w-6xl glass rounded-[28px] px-6 pb-12 pt-8 sm:px-10">
            @include('seo.partials.breadcrumbs', ['items' => [['Bosh sahifa', route('home')], ['IELTS mock test', null]]])
            <div class="mt-6 grid items-center gap-10 md:grid-cols-2">
                <div>
                    <h1 class="text-4xl font-extrabold leading-tight tracking-tight text-foreground md:text-5xl">Onlayn IELTS mock test — haqiqiy imtihon tajribasi</h1>
                    <p class="mt-5 text-lg text-muted-foreground">Imtihon kunidan oldin to'liq IELTS testini xuddi kompyuterda topshiriladigan imtihondagidek bajaring. Har bir bo'lim alohida taymer bilan, natija esa rasmiy jadvallarga yaqin band score ko'rinishida.</p>
                    <div class="mt-7 flex flex-wrap gap-3">
                        <a href="{{ route('register') }}" class="btn-glass-primary rounded-full px-6 py-3 font-semibold hover:brightness-110">Bepul ro'yxatdan o'tish</a>
                        <a href="{{ route('seo.page', 'ielts-ball-kalkulyatori') }}" class="rounded-full border border-glass-edge bg-glass-subtle px-6 py-3 font-semibold text-foreground hover:bg-accent">Band score'ni hisoblash</a>
                    </div>
                </div>
                <img src="{{ asset('images/site/hero-illustration.png') }}" alt="Mynine onlayn IELTS mock test interfeysi" class="w-full rounded-[22px]" width="640" height="480" loading="eager">
            </div>
        </div>
    </section>

    <section class="mx-auto max-w-6xl px-4 py-14">
        <h2 class="text-3xl font-bold text-foreground">Mock testda nimalar bor</h2>
        <div class="mt-8 grid gap-6 md:grid-cols-2 lg:grid-cols-4">
            @foreach ([
                ['Listening', "4 qism, 40 savol. Audio bir marta eshittiriladi, savollar imtihondagidek turlarga bo'lingan: gap filling, multiple choice, matching, map labelling."],
                ['Reading', "3 ta matn, 40 savol, 60 daqiqa. True/False/Not Given, matching headings, sentence completion va boshqa barcha savol turlari."],
                ['Writing', "Task 1 va Task 2. Insho topshirilgach, sun'iy intellekt to'rtta mezon bo'yicha baho va batafsil izoh beradi."],
                ['Speaking', "Imtihon tuzilishidagi savollar. Natijani o'qituvchingiz yoki o'quv markazi mutaxassisi baholaydi."],
            ] as [$name, $text])
                <div class="glass rounded-[22px] p-6">
                    <h3 class="text-xl font-bold text-foreground">{{ $name }}</h3>
                    <p class="mt-2 text-muted-foreground">{{ $text }}</p>
                </div>
            @endforeach
        </div>
    </section>

    <section>
        <div class="mx-auto max-w-6xl px-4 py-14">
            <h2 class="text-3xl font-bold text-foreground">Nega aynan Mynine</h2>
            <div class="mt-8 grid gap-8 md:grid-cols-3">
                <div class="glass rounded-[22px] p-6">
                    <h3 class="text-lg font-semibold text-foreground">Imtihondagi interfeys</h3>
                    <p class="mt-2 text-muted-foreground">Savollar raqamlar paneli, belgilash (flag), matnni ajratib qo'yish (highlight) va eslatmalar — kompyuterdagi IELTS bilan bir xil ish tartibi. Imtihon kuni hech narsa notanish bo'lmaydi.</p>
                </div>
                <div class="glass rounded-[22px] p-6">
                    <h3 class="text-lg font-semibold text-foreground">Darhol natija</h3>
                    <p class="mt-2 text-muted-foreground">Listening va Reading avtomatik tekshiriladi. To'g'ri javoblar soni band score'ga aylantiriladi, umumiy ball esa IELTS yaxlitlash qoidasi bilan hisoblanadi.</p>
                </div>
                <div class="glass rounded-[22px] p-6">
                    <h3 class="text-lg font-semibold text-foreground">Xatolar ustida ishlash</h3>
                    <p class="mt-2 text-muted-foreground">Har bir savol bo'yicha sizning javobingiz va to'g'ri javob yonma-yon ko'rsatiladi. Natijani PDF hisobot ko'rinishida yuklab olish mumkin.</p>
                </div>
                <div class="glass rounded-[22px] p-6">
                    <h3 class="text-lg font-semibold text-foreground">Internet uzilsa ham</h3>
                    <p class="mt-2 text-muted-foreground">Javoblar qurilmada saqlanib turadi va aloqa tiklanishi bilan serverga yuboriladi. Listening audiosi oldindan yuklab olinadi.</p>
                </div>
                <div class="glass rounded-[22px] p-6">
                    <h3 class="text-lg font-semibold text-foreground">Telegram orqali natija</h3>
                    <p class="mt-2 text-muted-foreground">Nomzod kodini <a href="https://t.me/MynineUzBot" class="text-brand underline" rel="noopener" target="_blank">@MynineUzBot</a> ga yuborib, natijani istalgan vaqtda bilib olasiz.</p>
                </div>
                <div class="glass rounded-[22px] p-6">
                    <h3 class="text-lg font-semibold text-foreground">Adolatli muhit</h3>
                    <p class="mt-2 text-muted-foreground">Imtihon oynasini tark etish qayd qilinadi, vaqt server bo'yicha hisoblanadi. Natija haqiqiy bilim darajangizni ko'rsatadi.</p>
                </div>
            </div>
        </div>
    </section>

    <section class="mx-auto max-w-6xl px-4 py-14">
        <h2 class="text-3xl font-bold text-foreground">Qanday boshlash mumkin</h2>
        <ol class="mt-8 grid gap-6 md:grid-cols-3">
            @foreach ([
                ["Ro'yxatdan o'ting", "Google, GitHub yoki Telegram orqali bir daqiqada akkaunt oching."],
                ['Testni tanlang', "Ochiq testlar ro'yxatidan birini tanlang yoki o'quv markazingiz bergan nomzod kodini kiriting."],
                ['Natijani tahlil qiling', "Band score, har bir bo'lim bo'yicha xatolar va Writing uchun AI izohini ko'rib chiqing."],
            ] as $i => [$step, $text])
                <li class="glass rounded-[22px] p-6">
                    <span class="flex size-10 items-center justify-center rounded-full bg-primary font-bold text-primary-foreground">{{ $i + 1 }}</span>
                    <h3 class="mt-4 text-lg font-semibold text-foreground">{{ $step }}</h3>
                    <p class="mt-1 text-muted-foreground">{{ $text }}</p>
                </li>
            @endforeach
        </ol>
    </section>

    @include('seo.partials.latest-articles')

    @push('jsonld')
    <script type="application/ld+json">
        {!! json_encode([
            '@context' => 'https://schema.org',
            '@type' => 'WebApplication',
            'name' => 'Mynine IELTS mock test',
            'url' => route('seo.page', 'ielts-mock-test'),
            'applicationCategory' => 'EducationalApplication',
            'operatingSystem' => 'Web',
            'inLanguage' => ['uz', 'en'],
            'offers' => ['@type' => 'Offer', 'price' => '0', 'priceCurrency' => 'UZS'],
            'description' => "Listening, Reading, Writing va Speaking bo'yicha onlayn IELTS mock test, avtomatik band score va AI Writing tahlili.",
        ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) !!}
    </script>
    @endpush
@endsection
