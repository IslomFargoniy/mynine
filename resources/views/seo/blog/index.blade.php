@extends('seo.layout')

@section('title', 'IELTS blog: maslahatlar, strategiyalar va tayyorlanish rejalari')
@section('description', "IELTS Listening, Reading, Writing va Speaking bo'yicha o'zbek tilidagi amaliy maqolalar: band score hisoblash, tayyorlanish rejasi va imtihon strategiyalari.")
@section('keywords', 'IELTS blog, IELTS maslahatlar, IELTS tayyorlanish, IELTS writing, IELTS listening, IELTS reading, IELTS speaking')

@section('content')
    <section class="border-b border-gray-100 bg-gradient-to-b from-[#6556ff]/5 to-white">
        <div class="mx-auto max-w-6xl px-4 py-12">
            @include('seo.partials.breadcrumbs', ['items' => [['Bosh sahifa', route('home')], ['Blog', null]]])
            <h1 class="mt-4 text-3xl font-extrabold tracking-tight text-gray-900 md:text-5xl">IELTS blog</h1>
            <p class="mt-4 max-w-2xl text-lg text-gray-600">IELTS imtihoniga tayyorlanish bo'yicha o'zbek tilida yozilgan amaliy qo'llanmalar. Har bir maqolada aniq misollar va mashq qilish uchun tavsiyalar bor.</p>
        </div>
    </section>

    <section class="mx-auto max-w-6xl px-4 py-12">
        <div class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            @foreach ($articles as $article)
                <div class="relative">@include('seo.partials.article-card', ['article' => $article])</div>
            @endforeach
        </div>
    </section>

    @push('jsonld')
    <script type="application/ld+json">
        {!! json_encode([
            '@context' => 'https://schema.org',
            '@type' => 'Blog',
            'name' => 'Mynine IELTS blog',
            'url' => route('blog.index'),
            'inLanguage' => 'uz',
            'blogPost' => $articles->map(fn ($a) => [
                '@type' => 'BlogPosting',
                'headline' => $a['title'],
                'url' => route('blog.show', $a['slug']),
                'datePublished' => $a['date']->toAtomString(),
                'dateModified' => $a['updated']->toAtomString(),
            ])->all(),
        ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) !!}
    </script>
    @endpush
@endsection
