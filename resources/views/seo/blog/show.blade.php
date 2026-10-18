@extends('seo.layout')

@section('title', $article['title'])
@section('description', $article['description'])
@section('keywords', $article['keywords'])
@section('og_type', 'article')

@section('content')
    <article class="mx-auto max-w-3xl px-4 py-10">
        @include('seo.partials.breadcrumbs', ['items' => [['Bosh sahifa', route('home')], ['Blog', route('blog.index')], [$article['title'], null]]])

        <header class="mt-6">
            <span class="rounded-full bg-[#6556ff]/10 px-3 py-1 text-xs font-semibold text-[#6556ff]">{{ $article['category'] }}</span>
            <h1 class="mt-4 text-3xl font-extrabold leading-tight tracking-tight text-gray-900 md:text-4xl">{{ $article['title'] }}</h1>
            <p class="mt-4 text-lg text-gray-600">{{ $article['description'] }}</p>
            <div class="mt-4 flex flex-wrap gap-x-4 gap-y-1 text-sm text-gray-500">
                <span>Mynine jamoasi</span>
                <time datetime="{{ $article['date']->toDateString() }}">{{ $article['date']->format('d.m.Y') }}</time>
                @if ($article['updated']->gt($article['date']))
                    <span>Yangilangan: <time datetime="{{ $article['updated']->toDateString() }}">{{ $article['updated']->format('d.m.Y') }}</time></span>
                @endif
                <span>{{ $article['reading_minutes'] }} daqiqa o'qish</span>
            </div>
        </header>

        @if (count($article['toc']) > 2)
            <nav class="mt-8 rounded-2xl border border-gray-100 bg-gray-50 p-5" aria-label="Mundarija">
                <p class="mb-2 text-sm font-semibold text-gray-900">Mundarija</p>
                <ol class="list-decimal space-y-1 pl-5 text-sm text-gray-700">
                    @foreach ($article['toc'] as $item)
                        <li><a href="#{{ $item['id'] }}" class="hover:text-[#6556ff]">{{ $item['title'] }}</a></li>
                    @endforeach
                </ol>
            </nav>
        @endif

        <div class="prose prose-lg mt-8 max-w-none prose-headings:scroll-mt-24 prose-headings:font-bold prose-a:text-[#6556ff] prose-table:text-base">
            {!! $article['html'] !!}
        </div>

        <aside class="mt-12 rounded-2xl bg-[#6556ff]/5 p-6">
            <p class="text-lg font-bold text-gray-900">Bilimingizni sinab ko'ring</p>
            <p class="mt-1 text-gray-600">Mynine'da haqiqiy imtihon formatidagi mock testni topshiring va band score'ingizni darhol bilib oling.</p>
            <div class="mt-4 flex flex-wrap gap-3">
                <a href="{{ route('seo.page', 'ielts-mock-test') }}" class="rounded-xl bg-[#6556ff] px-5 py-2.5 text-sm font-semibold text-white hover:bg-[#5446e6]">Mock test haqida</a>
                <a href="{{ route('seo.page', 'ielts-ball-kalkulyatori') }}" class="rounded-xl border border-gray-200 bg-white px-5 py-2.5 text-sm font-semibold text-gray-800 hover:bg-gray-50">Ball kalkulyatori</a>
            </div>
        </aside>
    </article>

    @if ($related->isNotEmpty())
        <section class="border-t border-gray-100 bg-gray-50">
            <div class="mx-auto max-w-6xl px-4 py-12">
                <h2 class="text-2xl font-bold text-gray-900">O'xshash maqolalar</h2>
                <div class="mt-6 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
                    @foreach ($related as $item)
                        <div class="relative">@include('seo.partials.article-card', ['article' => $item])</div>
                    @endforeach
                </div>
            </div>
        </section>
    @endif

    @push('jsonld')
    <script type="application/ld+json">
        {!! json_encode([
            '@context' => 'https://schema.org',
            '@type' => 'BlogPosting',
            'headline' => $article['title'],
            'description' => $article['description'],
            'inLanguage' => 'uz',
            'mainEntityOfPage' => route('blog.show', $article['slug']),
            'datePublished' => $article['date']->toAtomString(),
            'dateModified' => $article['updated']->toAtomString(),
            'image' => asset('images/site/hero-illustration.png'),
            'author' => ['@type' => 'Organization', 'name' => 'Mynine', 'url' => url('/')],
            'publisher' => ['@type' => 'Organization', 'name' => 'Mynine', 'logo' => ['@type' => 'ImageObject', 'url' => asset('images/logo/logo.png')]],
            'keywords' => $article['keywords'],
        ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) !!}
    </script>
    @endpush
@endsection
