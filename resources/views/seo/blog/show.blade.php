@extends('seo.layout')

@section('title', $article['title'])
@section('description', $article['description'])
@section('keywords', $article['keywords'])
@section('og_type', 'article')

@section('content')
    <article class="glass-strong mx-auto my-10 w-[calc(100%-2rem)] max-w-3xl rounded-[28px] px-5 py-8 sm:px-10 sm:py-10">
        @include('seo.partials.breadcrumbs', ['items' => [['Bosh sahifa', route('home')], ['Blog', route('blog.index')], [$article['title'], null]]])

        <header class="mt-6">
            <span class="rounded-full bg-indigo-500/12 px-3 py-1 text-xs font-semibold text-brand">{{ $article['category'] }}</span>
            <h1 class="mt-4 text-3xl font-extrabold leading-tight tracking-tight text-foreground md:text-4xl">{{ $article['title'] }}</h1>
            <p class="mt-4 text-lg text-muted-foreground">{{ $article['description'] }}</p>
            <div class="mt-4 flex flex-wrap gap-x-4 gap-y-1 text-sm text-muted-foreground">
                <span>Mynine jamoasi</span>
                <time datetime="{{ $article['date']->toDateString() }}">{{ $article['date']->format('d.m.Y') }}</time>
                @if ($article['updated']->gt($article['date']))
                    <span>Yangilangan: <time datetime="{{ $article['updated']->toDateString() }}">{{ $article['updated']->format('d.m.Y') }}</time></span>
                @endif
                <span>{{ $article['reading_minutes'] }} daqiqa o'qish</span>
            </div>
        </header>

        @php
            $toc = $article['toc'];
            if ($article['faq']) {
                $toc[] = ['id' => 'faq', 'title' => "Ko'p beriladigan savollar"];
            }
        @endphp
        @if (count($toc) > 2)
            <nav class="glass-subtle mt-8 rounded-[18px] p-5" aria-label="Mundarija">
                <p class="mb-2 text-sm font-semibold text-foreground">Mundarija</p>
                <ol class="list-decimal space-y-1 pl-5 text-sm text-muted-foreground">
                    @foreach ($toc as $item)
                        <li><a href="#{{ $item['id'] }}" class="hover:text-brand">{{ $item['title'] }}</a></li>
                    @endforeach
                </ol>
            </nav>
        @endif

        <div class="prose prose-lg mt-8 max-w-none prose-headings:scroll-mt-24 prose-headings:font-bold prose-a:text-brand prose-table:text-base">
            {!! $article['html'] !!}
        </div>

        @if ($article['faq'])
            <section class="mt-12 scroll-mt-24" id="faq" aria-labelledby="faq-title">
                <h2 id="faq-title" class="text-2xl font-bold text-foreground">Ko'p beriladigan savollar</h2>
                <div class="mt-6 divide-y divide-divider rounded-[18px] border border-divider">
                    @foreach ($article['faq'] as $item)
                        <details class="group p-5" @if ($loop->first) open @endif>
                            <summary class="flex cursor-pointer list-none items-center justify-between gap-4">
                                <h3 class="text-lg font-semibold text-foreground">{{ $item['q'] }}</h3>
                                <span class="text-2xl text-brand transition group-open:rotate-45" aria-hidden="true">+</span>
                            </summary>
                            <p class="mt-3 text-muted-foreground">{{ $item['a'] }}</p>
                        </details>
                    @endforeach
                </div>
            </section>
        @endif

        <aside class="mt-12 rounded-[22px] border border-indigo-500/15 bg-indigo-500/8 p-6">
            <p class="text-lg font-bold text-foreground">Bilimingizni sinab ko'ring</p>
            <p class="mt-1 text-muted-foreground">Mynine'da haqiqiy imtihon formatidagi mock testni topshiring va band score'ingizni darhol bilib oling.</p>
            <div class="mt-4 flex flex-wrap gap-3">
                <a href="{{ route('seo.page', 'ielts-mock-test') }}" class="btn-glass-primary rounded-full px-5 py-2.5 text-sm font-semibold hover:brightness-110">Mock test haqida</a>
                <a href="{{ route('seo.page', 'ielts-ball-kalkulyatori') }}" class="rounded-full border border-glass-edge bg-glass-subtle px-5 py-2.5 text-sm font-semibold text-foreground hover:bg-accent">Ball kalkulyatori</a>
            </div>
        </aside>
    </article>

    @if ($related->isNotEmpty())
        <section>
            <div class="mx-auto max-w-6xl px-4 py-12">
                <h2 class="text-2xl font-bold text-foreground">O'xshash maqolalar</h2>
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
    @if ($article['faq'])
    <script type="application/ld+json">
        {!! json_encode([
            '@context' => 'https://schema.org',
            '@type' => 'FAQPage',
            'mainEntity' => collect($article['faq'])->map(fn ($f) => [
                '@type' => 'Question',
                'name' => $f['q'],
                'acceptedAnswer' => ['@type' => 'Answer', 'text' => $f['a']],
            ])->all(),
        ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) !!}
    </script>
    @endif
    @endpush
@endsection
