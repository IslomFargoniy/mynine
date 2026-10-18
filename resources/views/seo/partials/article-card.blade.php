<article class="group flex flex-col rounded-2xl border border-gray-100 bg-white p-6 shadow-sm transition hover:shadow-md">
    <div class="mb-3 flex items-center gap-2 text-xs font-medium text-gray-500">
        <span class="rounded-full bg-[#6556ff]/10 px-2.5 py-1 text-[#6556ff]">{{ $article['category'] }}</span>
        <span>{{ $article['reading_minutes'] }} daqiqa o'qish</span>
    </div>
    <h3 class="text-lg font-bold leading-snug text-gray-900">
        <a href="{{ route('blog.show', $article['slug']) }}" class="after:absolute after:inset-0 group-hover:text-[#6556ff]">{{ $article['title'] }}</a>
    </h3>
    <p class="mt-2 line-clamp-3 text-sm text-gray-600">{{ $article['description'] }}</p>
    <time datetime="{{ $article['date']->toDateString() }}" class="mt-4 text-xs text-gray-400">{{ $article['date']->format('d.m.Y') }}</time>
</article>
