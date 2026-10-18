@extends('seo.layout')

@section('title', "Savol-javob: Mynine va IELTS mock test haqida")
@section('description', "Mynine onlayn IELTS mock testi qanday ishlaydi, natija qanchalik aniq, Writing qanday baholanadi, nomzod kodi nima — eng ko'p beriladigan savollarga javoblar.")
@section('keywords', "IELTS mock test savollar, Mynine savol javob, IELTS nomzod kodi, IELTS natija qachon, IELTS writing AI baholash")

@php
    $faqs = [
        ["Mynine nima?", "Mynine — IELTS imtihoniga tayyorlanish uchun onlayn mock test platformasi. Unda Listening, Reading, Writing va Speaking bo'limlarini haqiqiy imtihon formatida topshirib, band score'ingizni bilib olasiz. O'quv markazlari esa platforma orqali o'z talabalari uchun mock imtihon o'tkazadi."],
        ["Mock test natijasi haqiqiy IELTS natijasiga qanchalik yaqin?", "Listening va Reading avtomatik tekshiriladi va to'g'ri javoblar soni keng qo'llaniladigan konvertatsiya jadvali bo'yicha band'ga aylantiriladi, shuning uchun bu ikki bo'lim natijasi odatda haqiqiy imtihonga yaqin bo'ladi. Writing va Speaking baholari esa taxminiy: ular sizga qaysi tomonda turganingizni ko'rsatadi, lekin rasmiy imtihon baholovchisi bahosining o'rnini bosmaydi."],
        ["Writing qanday baholanadi?", "Inshoni topshirganingizdan keyin sun'iy intellekt uni IELTS'ning to'rt mezoni — Task Response (Task Achievement), Coherence and Cohesion, Lexical Resource va Grammatical Range and Accuracy — bo'yicha baholaydi va batafsil izoh yozadi. 50 so'zdan qisqa insholar 0 ball oladi, chunki ularni mezonlar bo'yicha baholab bo'lmaydi. Agar mock imtihon o'quv markazi orqali bo'lsa, o'qituvchi bahoni qayta ko'rib chiqishi mumkin."],
        ["Speaking bo'limi qanday baholanadi?", "Speaking natijasini o'qituvchingiz yoki o'quv markazi mutaxassisi kiritadi. Mustaqil tayyorlanayotgan bo'lsangiz, Speaking savollari bo'yicha mashq qilish uchun blogdagi maslahatlardan foydalaning."],
        ["Nomzod kodi nima va uni qayerdan olaman?", "Nomzod kodi (masalan, TEST1-123456) — o'quv markazi mock imtihon uchun har bir talabaga beradigan shaxsiy kod. U bilan akkaunt ochmasdan imtihonga kirish va keyinchalik natijani Telegram bot orqali bilish mumkin. Kodni imtihon o'tkazayotgan o'quv markazidan olasiz."],
        ["Natijani qanday bilib olaman?", "Akkaunt orqali topshirgan bo'lsangiz, natija kabinetingizda chiqadi va PDF hisobotni yuklab olish mumkin. Nomzod kodi bilan topshirgan bo'lsangiz, kodni @MynineUzBot Telegram botiga yuboring. Writing'ning AI bahosi odatda bir necha daqiqada tayyor bo'ladi."],
        ["Test paytida internet uzilib qolsa nima bo'ladi?", "Javoblaringiz qurilmangizda saqlanib turadi va aloqa tiklanganda avtomatik yuboriladi. Listening audiosi test boshida oldindan yuklab olinadi. Biroq bo'lim taymeri server vaqti bo'yicha davom etadi, shuning uchun barqaror internetda topshirish tavsiya etiladi."],
        ["Testdan chiqib ketsam yoki boshqa oynaga o'tsam-chi?", "Imtihon oynasini tark etish qoidabuzarlik sifatida qayd qilinadi va o'qituvchi buni natijalarda ko'radi. Bu haqiqiy imtihon sharoitini saqlash uchun kerak."],
        ["Mynine bepulmi?", "Ro'yxatdan o'tish va ochiq testlarni topshirish bepul. O'quv markazlari uchun mock imtihon tashkil qilish shartlari bo'yicha Telegram orqali bog'laning."],
        ["Mynine rasmiy IELTS tashkilotimi?", "Yo'q. IELTS — British Council, IDP va Cambridge University Press & Assessment ga tegishli imtihon. Mynine ular bilan bog'liq emas; bu imtihonga tayyorlanish uchun mustaqil platforma. Rasmiy imtihonga yozilish uchun vakolatli test markazlariga murojaat qiling."],
    ];
@endphp

@section('content')
    <section class="mx-auto max-w-3xl px-4 py-10">
        @include('seo.partials.breadcrumbs', ['items' => [['Bosh sahifa', route('home')], ['Savol-javob', null]]])
        <h1 class="mt-6 text-4xl font-extrabold tracking-tight text-gray-900">Savol-javob</h1>
        <p class="mt-4 text-lg text-gray-600">Mynine va onlayn IELTS mock test haqida eng ko'p beriladigan savollar.</p>

        <div class="mt-8 divide-y divide-gray-100 rounded-2xl border border-gray-100">
            @foreach ($faqs as [$question, $answer])
                <details class="group p-5" @if ($loop->first) open @endif>
                    <summary class="flex cursor-pointer list-none items-center justify-between gap-4 text-lg font-semibold text-gray-900">
                        <h2 class="text-lg">{{ $question }}</h2>
                        <span class="text-2xl text-[#6556ff] transition group-open:rotate-45" aria-hidden="true">+</span>
                    </summary>
                    <p class="mt-3 text-gray-600">{{ $answer }}</p>
                </details>
            @endforeach
        </div>
    </section>

    @include('seo.partials.latest-articles')

    @push('jsonld')
    <script type="application/ld+json">
        {!! json_encode([
            '@context' => 'https://schema.org',
            '@type' => 'FAQPage',
            'mainEntity' => collect($faqs)->map(fn ($f) => [
                '@type' => 'Question',
                'name' => $f[0],
                'acceptedAnswer' => ['@type' => 'Answer', 'text' => $f[1]],
            ])->all(),
        ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) !!}
    </script>
    @endpush
@endsection
