<article class="glass group flex h-full flex-col rounded-[22px] p-6 transition hover:-translate-y-0.5">
    <div class="mb-3 flex items-center gap-2 text-xs font-medium text-muted-foreground">
        <span class="rounded-full bg-indigo-500/12 px-2.5 py-1 text-brand">{{ $article['category'] }}</span>
        <span>{{ $article['reading_minutes'] }} daqiqa o'qish</span>
    </div>
    <h3 class="text-lg font-bold leading-snug text-foreground">
        <a href="{{ route('blog.show', $article['slug']) }}" class="after:absolute after:inset-0 group-hover:text-brand">{{ $article['title'] }}</a>
    </h3>
    <p class="mt-2 line-clamp-3 text-sm text-muted-foreground">{{ $article['description'] }}</p>
    <time datetime="{{ $article['date']->toDateString() }}" class="mt-4 text-xs text-muted-foreground">{{ $article['date']->format('d.m.Y') }}</time>
</article>
