{{-- $items: [[label, url|null], ...] --}}
<nav aria-label="Breadcrumb" class="text-sm text-gray-500">
    <ol class="flex flex-wrap items-center gap-1">
        @foreach ($items as $i => [$label, $url])
            <li class="flex items-center gap-1">
                @if ($url)
                    <a href="{{ $url }}" class="hover:text-gray-800">{{ $label }}</a>
                @else
                    <span class="text-gray-700" aria-current="page">{{ $label }}</span>
                @endif
                @if (! $loop->last)<span aria-hidden="true">/</span>@endif
            </li>
        @endforeach
    </ol>
</nav>
@push('jsonld')
<script type="application/ld+json">
    {!! json_encode([
        '@context' => 'https://schema.org',
        '@type' => 'BreadcrumbList',
        'itemListElement' => collect($items)->values()->map(fn ($item, $i) => array_filter([
            '@type' => 'ListItem',
            'position' => $i + 1,
            'name' => $item[0],
            'item' => $item[1] ?? url()->current(),
        ]))->all(),
    ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) !!}
</script>
@endpush
