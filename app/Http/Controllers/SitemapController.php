<?php

namespace App\Http\Controllers;

use Illuminate\Http\Response;

class SitemapController extends Controller
{
    /**
     * Only the public marketing/auth pages are indexable; everything else requires a login
     * or a candidate code, so it is deliberately left out (and disallowed in robots.txt).
     */
    public function index(): Response
    {
        $urls = [
            ['loc' => route('home'), 'changefreq' => 'weekly', 'priority' => '1.0'],
            ['loc' => route('login'), 'changefreq' => 'monthly', 'priority' => '0.5'],
            ['loc' => route('register'), 'changefreq' => 'monthly', 'priority' => '0.5'],
        ];

        $lastmod = now()->startOfWeek()->toAtomString();

        $xml = '<?xml version="1.0" encoding="UTF-8"?>'."\n";
        $xml .= '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'."\n";
        foreach ($urls as $url) {
            $xml .= "  <url>\n";
            $xml .= '    <loc>'.e($url['loc'])."</loc>\n";
            $xml .= '    <lastmod>'.$lastmod."</lastmod>\n";
            $xml .= '    <changefreq>'.$url['changefreq']."</changefreq>\n";
            $xml .= '    <priority>'.$url['priority']."</priority>\n";
            $xml .= "  </url>\n";
        }
        $xml .= '</urlset>';

        return response($xml, 200, [
            'Content-Type' => 'application/xml; charset=UTF-8',
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }
}
