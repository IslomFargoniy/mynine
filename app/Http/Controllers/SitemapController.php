<?php

namespace App\Http\Controllers;

use App\Services\BlogRepository;
use Illuminate\Http\Response;

class SitemapController extends Controller
{
    /**
     * Public, indexable URLs only. Everything else needs a login or a candidate code
     * and is disallowed in robots.txt.
     */
    public function index(BlogRepository $blog): Response
    {
        $articles = $blog->all();
        $latest = $articles->max(fn ($a) => $a['updated']) ?? now()->startOfWeek();
        $pagesUpdated = now()->startOfMonth();

        $urls = [
            ['loc' => route('home'), 'lastmod' => $latest, 'changefreq' => 'weekly', 'priority' => '1.0'],
            ['loc' => route('blog.index'), 'lastmod' => $latest, 'changefreq' => 'weekly', 'priority' => '0.9'],
        ];

        foreach (array_keys(SeoPageController::PAGES) as $page) {
            $urls[] = ['loc' => route('seo.page', $page), 'lastmod' => $pagesUpdated, 'changefreq' => 'monthly', 'priority' => '0.8'];
        }

        foreach ($articles as $article) {
            $urls[] = ['loc' => route('blog.show', $article['slug']), 'lastmod' => $article['updated'], 'changefreq' => 'monthly', 'priority' => '0.7'];
        }

        $urls[] = ['loc' => route('login'), 'lastmod' => $pagesUpdated, 'changefreq' => 'yearly', 'priority' => '0.3'];
        $urls[] = ['loc' => route('register'), 'lastmod' => $pagesUpdated, 'changefreq' => 'yearly', 'priority' => '0.4'];

        $xml = '<?xml version="1.0" encoding="UTF-8"?>'."\n";
        $xml .= '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'."\n";
        foreach ($urls as $url) {
            $xml .= "  <url>\n";
            $xml .= '    <loc>'.e($url['loc'])."</loc>\n";
            $xml .= '    <lastmod>'.$url['lastmod']->toAtomString()."</lastmod>\n";
            $xml .= '    <changefreq>'.$url['changefreq']."</changefreq>\n";
            $xml .= '    <priority>'.$url['priority']."</priority>\n";
            $xml .= "  </url>\n";
        }
        $xml .= '</urlset>';

        return response($xml, 200, [
            'Content-Type' => 'application/xml; charset=UTF-8',
            'Cache-Control' => 'public, max-age=3600',
        ]);
    }
}
