@php
    // @section('x', $value) already HTML-escapes $value; decode once so {{ }} below escapes exactly once.
    $section = fn (string $name, string $default = '') => trim(html_entity_decode($__env->yieldContent($name, $default), ENT_QUOTES | ENT_HTML5));
    $pageTitle = $section('title');
    $fullTitle = $pageTitle ? $pageTitle.' | Mynine' : 'Mynine — IELTS mock testlar';
    $description = $section('description', 'Mynine — haqiqiy imtihon muhitida IELTS mock testlar, avtomatik baholash va AI yordamida Writing tahlili.');
    $keywords = $section('keywords');
    $canonical = $section('canonical', url()->current());
    $ogType = $section('og_type', 'website');
    $ogImage = asset('images/site/hero-illustration.png');
    $nav = [
        ['href' => route('home'), 'label' => 'Bosh sahifa'],
        ['href' => route('seo.page', 'ielts-mock-test'), 'label' => 'IELTS mock test'],
        ['href' => route('seo.page', 'ielts-ball-kalkulyatori'), 'label' => 'Ball kalkulyatori'],
        ['href' => route('blog.index'), 'label' => 'Blog'],
        ['href' => route('seo.page', 'savol-javob'), 'label' => 'Savol-javob'],
    ];
@endphp
<!DOCTYPE html>
<html lang="uz">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $fullTitle }}</title>
    <meta name="description" content="{{ $description }}">
    @if ($keywords)<meta name="keywords" content="{{ $keywords }}">@endif
    <meta name="robots" content="index, follow, max-image-preview:large">
    <link rel="canonical" href="{{ $canonical }}">

    <meta property="og:site_name" content="Mynine">
    <meta property="og:locale" content="uz_UZ">
    <meta property="og:type" content="{{ $ogType }}">
    <meta property="og:title" content="{{ $pageTitle ?: $fullTitle }}">
    <meta property="og:description" content="{{ $description }}">
    <meta property="og:url" content="{{ $canonical }}">
    <meta property="og:image" content="{{ $ogImage }}">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="{{ $pageTitle ?: $fullTitle }}">
    <meta name="twitter:description" content="{{ $description }}">
    <meta name="twitter:image" content="{{ $ogImage }}">

    <link rel="icon" href="{{ asset('favicon.ico') }}">
    <link rel="preconnect" href="https://fonts.bunny.net">
    <link href="https://fonts.bunny.net/css?family=inter:400,500,600,700,800" rel="stylesheet">
    @vite(['resources/css/app.css'])

    <script type="application/ld+json">
        {!! json_encode([
            '@context' => 'https://schema.org',
            '@type' => 'Organization',
            'name' => 'Mynine',
            'url' => url('/'),
            'logo' => asset('images/logo/logo.png'),
            'sameAs' => ['https://t.me/MynineUzBot'],
        ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) !!}
    </script>
    @stack('jsonld')
</head>
<body class="font-sans text-foreground antialiased">
    <div class="glass-backdrop" aria-hidden="true"><span></span><span></span><span></span></div>
    <header class="sticky top-0 z-40 px-3 pt-3">
        <div class="glass-pill mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-2 sm:px-6">
            <a href="{{ route('home') }}" class="flex items-center gap-2" aria-label="Mynine bosh sahifa">
                <img src="{{ asset('images/logo/logo.svg') }}" alt="Mynine" class="h-9 w-auto" width="120" height="36">
            </a>
            <nav class="hidden items-center gap-6 text-[15px] font-medium md:flex" aria-label="Asosiy menyu">
                @foreach ($nav as $item)
                    <a href="{{ $item['href'] }}"
                       class="{{ url()->current() === $item['href'] ? 'font-semibold text-brand' : 'text-muted-foreground hover:text-foreground' }}">{{ $item['label'] }}</a>
                @endforeach
            </nav>
            <div class="flex items-center gap-2">
                @auth
                    <a href="{{ route('dashboard') }}" class="btn-glass-primary rounded-full px-4 py-2 text-sm font-semibold hover:brightness-110">Kabinet</a>
                @else
                    <a href="{{ route('login') }}" class="hidden rounded-full px-4 py-2 text-sm font-semibold text-foreground hover:bg-accent sm:inline-block">Kirish</a>
                    <a href="{{ route('register') }}" class="btn-glass-primary rounded-full px-4 py-2 text-sm font-semibold hover:brightness-110">Bepul boshlash</a>
                @endauth
            </div>
        </div>
        <nav class="glass-pill mx-auto mt-2 flex max-w-6xl gap-4 overflow-x-auto px-4 py-2 text-sm font-medium text-muted-foreground md:hidden" aria-label="Mobil menyu">
            @foreach ($nav as $item)
                <a href="{{ $item['href'] }}" class="shrink-0 {{ url()->current() === $item['href'] ? 'font-semibold text-brand' : '' }}">{{ $item['label'] }}</a>
            @endforeach
        </nav>
    </header>

    <main>
        @yield('content')
    </main>

    <section class="py-12">
        <div class="mx-auto w-[calc(100%-2rem)] max-w-6xl glass rounded-[28px] flex flex-col items-start justify-between gap-6 px-6 py-10 sm:px-10 md:flex-row md:items-center">
            <div>
                <p class="text-2xl font-bold text-foreground md:text-3xl">Haqiqiy imtihondan oldin o'zingizni sinab ko'ring</p>
                <p class="mt-2 text-muted-foreground">Listening, Reading, Writing va Speaking bo'yicha to'liq IELTS mock test — natija va band score darhol.</p>
            </div>
            <a href="{{ route('register') }}" class="btn-glass-primary shrink-0 rounded-full px-6 py-3 font-semibold hover:brightness-110">Mock testni boshlash</a>
        </div>
    </section>

    <footer class="mx-auto w-[calc(100%-2rem)] max-w-6xl glass rounded-[28px] mb-6">
        <div class="grid gap-8 px-6 py-10 text-sm sm:px-10 md:grid-cols-4">
            <div class="md:col-span-2">
                <img src="{{ asset('images/logo/logo.svg') }}" alt="Mynine" class="h-8 w-auto" width="110" height="32" loading="lazy">
                <p class="mt-3 max-w-md text-muted-foreground">Mynine — IELTS ga tayyorlanayotganlar va o'quv markazlari uchun onlayn mock test platformasi.</p>
            </div>
            <div>
                <p class="mb-3 font-semibold text-foreground">Sahifalar</p>
                <ul class="space-y-2 text-muted-foreground">
                    <li><a href="{{ route('seo.page', 'ielts-mock-test') }}" class="hover:text-foreground">Onlayn IELTS mock test</a></li>
                    <li><a href="{{ route('seo.page', 'ielts-ball-kalkulyatori') }}" class="hover:text-foreground">IELTS ball kalkulyatori</a></li>
                    <li><a href="{{ route('seo.page', 'oquv-markazlari-uchun') }}" class="hover:text-foreground">O'quv markazlari uchun</a></li>
                    <li><a href="{{ route('seo.page', 'savol-javob') }}" class="hover:text-foreground">Savol-javob</a></li>
                </ul>
            </div>
            <div>
                <p class="mb-3 font-semibold text-foreground">Foydali</p>
                <ul class="space-y-2 text-muted-foreground">
                    <li><a href="{{ route('blog.index') }}" class="hover:text-foreground">Blog</a></li>
                    <li><a href="https://t.me/MynineUzBot" class="hover:text-foreground" rel="noopener" target="_blank">Telegram bot</a></li>
                    <li><a href="{{ route('login') }}" class="hover:text-foreground">Kirish</a></li>
                </ul>
            </div>
        </div>
        <div class="border-t border-divider px-6 py-4 text-center text-xs text-muted-foreground">© {{ date('Y') }} Mynine. IELTS — British Council, IDP va Cambridge University Press &amp; Assessment ning ro'yxatdan o'tgan savdo belgisi; Mynine ular bilan rasmiy bog'liq emas.</div>
    </footer>
</body>
</html>
