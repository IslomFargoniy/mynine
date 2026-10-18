<?php

namespace App\Services;

use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;
use League\CommonMark\Environment\Environment;
use League\CommonMark\Extension\CommonMark\CommonMarkCoreExtension;
use League\CommonMark\Extension\FrontMatter\FrontMatterExtension;
use League\CommonMark\Extension\FrontMatter\Output\RenderedContentWithFrontMatter;
use League\CommonMark\Extension\GithubFlavoredMarkdownExtension;
use League\CommonMark\Extension\HeadingPermalink\HeadingPermalinkExtension;
use League\CommonMark\MarkdownConverter;

/**
 * Blog articles live as Markdown files with YAML front matter in resources/content/blog.
 * Rendered articles are cached and the cache key changes whenever a file changes.
 */
class BlogRepository
{
    public function __construct(private ?string $directory = null)
    {
        $this->directory ??= resource_path('content/blog');
    }

    /**
     * @return Collection<int, array<string, mixed>> newest first
     */
    public function all(): Collection
    {
        $files = glob($this->directory.'/*.md') ?: [];
        $signature = md5(implode('|', array_map(fn ($f) => $f.filemtime($f), $files)));

        $articles = Cache::rememberForever('blog.articles.'.$signature, function () use ($files) {
            return collect($files)
                ->map(fn (string $file) => $this->parse($file))
                ->filter(fn (array $article) => $article['published'])
                ->sortByDesc(fn (array $article) => $article['date']->timestamp)
                ->values()
                ->all();
        });

        return collect($articles);
    }

    public function find(string $slug): ?array
    {
        return $this->all()->firstWhere('slug', $slug);
    }

    /**
     * Other articles, preferring the same category.
     */
    public function related(array $article, int $limit = 3): Collection
    {
        return $this->all()
            ->reject(fn ($a) => $a['slug'] === $article['slug'])
            ->sortByDesc(fn ($a) => $a['category'] === $article['category'] ? 1 : 0)
            ->take($limit)
            ->values();
    }

    private function parse(string $file): array
    {
        $result = $this->converter()->convert(file_get_contents($file));
        $meta = $result instanceof RenderedContentWithFrontMatter ? (array) $result->getFrontMatter() : [];
        $html = (string) $result->getContent();

        $text = trim(strip_tags($html));
        $words = str_word_count($text, 0, "ʻ'‘’oʻgʻOʻGʻ");

        $date = Carbon::parse($meta['date'] ?? filemtime($file));

        return [
            'slug' => pathinfo($file, PATHINFO_FILENAME),
            'title' => $meta['title'] ?? pathinfo($file, PATHINFO_FILENAME),
            'description' => $meta['description'] ?? mb_substr($text, 0, 160),
            'keywords' => $meta['keywords'] ?? '',
            'category' => $meta['category'] ?? 'IELTS',
            'date' => $date,
            'updated' => isset($meta['updated']) ? Carbon::parse($meta['updated']) : $date,
            'published' => ($meta['published'] ?? true) !== false,
            'reading_minutes' => max(1, (int) ceil($words / 200)),
            'html' => $html,
            'toc' => $this->tableOfContents($html),
        ];
    }

    /**
     * @return array<int, array{id: string, title: string}>
     */
    private function tableOfContents(string $html): array
    {
        preg_match_all('/<h2[^>]*id="([^"]+)"[^>]*>(.*?)<\/h2>/s', $html, $matches, PREG_SET_ORDER);

        return array_map(fn ($m) => ['id' => $m[1], 'title' => trim(strip_tags($m[2]))], $matches);
    }

    private function converter(): MarkdownConverter
    {
        $environment = new Environment([
            'html_input' => 'strip',
            'allow_unsafe_links' => false,
            'heading_permalink' => [
                'html_class' => 'heading-anchor',
                'id_prefix' => '',
                'fragment_prefix' => '',
                'symbol' => '',
                'insert' => 'after',
                'min_heading_level' => 2,
                'max_heading_level' => 3,
                'aria_hidden' => true,
            ],
        ]);
        $environment->addExtension(new CommonMarkCoreExtension);
        $environment->addExtension(new GithubFlavoredMarkdownExtension);
        $environment->addExtension(new FrontMatterExtension);
        $environment->addExtension(new HeadingPermalinkExtension);

        return new MarkdownConverter($environment);
    }
}
