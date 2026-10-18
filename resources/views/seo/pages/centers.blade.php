@extends('seo.layout')

@section('title', "O'quv markazlari uchun IELTS mock test platformasi")
@section('description', "O'quv markazlari va IELTS o'qituvchilari uchun Mynine: o'z testlaringizni yarating, nomzod kodlari bilan mock imtihon o'tkazing, natijalarni avtomatik baholang, PDF va Excel hisobotlarni oling.")
@section('keywords', "IELTS mock test o'quv markazi, mock imtihon o'tkazish, IELTS test platformasi, o'quv markazi uchun dastur, IELTS o'qituvchi")

@section('content')
    <section class="bg-gradient-to-b from-[#6556ff]/10 to-white">
        <div class="mx-auto max-w-6xl px-4 pb-14 pt-10">
            @include('seo.partials.breadcrumbs', ['items' => [['Bosh sahifa', route('home')], ["O'quv markazlari uchun", null]]])
            <h1 class="mt-6 max-w-3xl text-4xl font-extrabold leading-tight tracking-tight text-gray-900 md:text-5xl">O'quv markazingizda IELTS mock imtihonlarini qog'ozsiz o'tkazing</h1>
            <p class="mt-5 max-w-2xl text-lg text-gray-600">Testni bir marta kiriting — keyin istalgan guruh uchun mock imtihon tashkil qiling. Javoblarni tekshirish, ball hisoblash va hisobot tayyorlashni Mynine bajaradi.</p>
            <div class="mt-7 flex flex-wrap gap-3">
                <a href="https://t.me/IslomFargniy" rel="noopener" target="_blank" class="rounded-xl bg-[#6556ff] px-6 py-3 font-semibold text-white hover:bg-[#5446e6]">Ulanish uchun yozing</a>
                <a href="{{ route('seo.page', 'ielts-mock-test') }}" class="rounded-xl border border-gray-200 bg-white px-6 py-3 font-semibold text-gray-800 hover:bg-gray-50">Talaba tajribasini ko'rish</a>
            </div>
        </div>
    </section>

    <section class="mx-auto max-w-6xl px-4 py-14">
        <h2 class="text-3xl font-bold text-gray-900">Imkoniyatlar</h2>
        <div class="mt-8 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            @foreach ([
                ['Test muharriri', "Listening audio, Reading matnlari va Writing topshiriqlarini qulay muharrirda kiriting. Barcha IELTS savol turlari: multiple choice, T/F/NG, matching, gap filling, drag and drop."],
                ["Matndan avtomatik import", "Tayyor testni .docx yoki matn ko'rinishida yuklang — sun'iy intellekt bo'limlar, savollar va javoblarni ajratib beradi, siz faqat tekshirasiz."],
                ['Nomzod kodlari', "Mock imtihon uchun talabalar ro'yxatini kiriting, har biriga alohida kod yaratiladi. Talaba akkauntsiz, faqat kod bilan imtihonga kiradi."],
                ['Vaqt oynasi', "Mock imtihon boshlanish va tugash vaqtini belgilang. Undan oldin yoki keyin kod ishlamaydi, har bir bo'lim o'z taymeri bilan yopiladi."],
                ['Avtomatik baholash', "Listening va Reading darhol tekshiriladi. Writing uchun AI baho va izoh beradi, o'qituvchi uni qayta ko'rib chiqishi mumkin. Speaking ballini o'qituvchi kiritadi."],
                ['Hisobotlar', "Har bir nomzod uchun TRF uslubidagi PDF hisobot, butun guruh natijalari uchun Excel eksport. Natijalar Telegram bot orqali ham yuboriladi."],
            ] as [$title, $text])
                <div class="rounded-2xl border border-gray-100 p-6 shadow-sm">
                    <h3 class="text-lg font-bold text-gray-900">{{ $title }}</h3>
                    <p class="mt-2 text-gray-600">{{ $text }}</p>
                </div>
            @endforeach
        </div>
    </section>

    <section class="bg-gray-50">
        <div class="mx-auto max-w-6xl px-4 py-14">
            <h2 class="text-3xl font-bold text-gray-900">Mock imtihon qanday o'tadi</h2>
            <ol class="mt-8 space-y-4">
                @foreach ([
                    "O'qituvchi testni tayyorlaydi yoki mavjud testni tanlaydi.",
                    "Mock imtihon yaratiladi: nom, sana va vaqt oynasi belgilanadi.",
                    "Talabalar ro'yxati kiritiladi — har biriga nomzod kodi beriladi.",
                    "Imtihon kuni talabalar mynine.uz ga kirib kodni kiritadi va testni boshlaydi.",
                    "Tugagach, natijalar o'qituvchi panelida, PDF hisobotda va Telegram botda paydo bo'ladi.",
                ] as $i => $step)
                    <li class="flex gap-4 rounded-2xl bg-white p-5">
                        <span class="flex size-9 shrink-0 items-center justify-center rounded-full bg-[#6556ff] font-bold text-white">{{ $i + 1 }}</span>
                        <p class="pt-1.5 text-gray-700">{{ $step }}</p>
                    </li>
                @endforeach
            </ol>
        </div>
    </section>

    <section class="mx-auto max-w-6xl px-4 py-14">
        <div class="prose prose-lg max-w-none">
            <h2>Nega mock imtihonni onlayn o'tkazish kerak</h2>
            <p>Qog'ozdagi mock imtihonda eng ko'p vaqt tekshirishga ketadi: 40 ta Listening va 40 ta Reading javobini har bir talaba uchun qo'lda solishtirish, band'ga aylantirish va natijani yetkazish. Onlayn formatda bu ishlar avtomatik bajariladi, o'qituvchi esa tahlil va dars berishga e'tibor qaratadi.</p>
            <p>Bundan tashqari, IELTS'ning katta qismi hozir kompyuterda topshiriladi. Talabalar imtihon interfeysiga oldindan o'rganib qolsa, haqiqiy imtihonda vaqtni boshqarish osonlashadi. Bu haqda batafsil: <a href="{{ route('blog.show', 'ielts-mock-test-nima-uchun-kerak') }}">Mock test nima uchun kerak</a>.</p>
        </div>
    </section>

    @include('seo.partials.latest-articles')
@endsection
