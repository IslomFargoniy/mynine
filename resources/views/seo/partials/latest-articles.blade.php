@if (($latestArticles ?? collect())->isNotEmpty())
    <section>
        <div class="mx-auto max-w-6xl px-4 py-12">
            <div class="flex items-end justify-between gap-4">
                <h2 class="text-2xl font-bold text-foreground">Blogdan foydali maqolalar</h2>
                <a href="{{ route('blog.index') }}" class="text-sm font-semibold text-brand hover:underline">Barcha maqolalar</a>
            </div>
            <div class="mt-6 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
                @foreach ($latestArticles as $article)
                    <div class="relative">@include('seo.partials.article-card', ['article' => $article])</div>
                @endforeach
            </div>
        </div>
    </section>
@endif
