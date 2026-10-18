<?php

namespace App\Http\Controllers;

use App\Services\BlogRepository;

/**
 * Public landing pages that are rendered on the server so search engines see the full content.
 */
class SeoPageController extends Controller
{
    /**
     * slug => view name, used by the routes and by the sitemap.
     */
    public const PAGES = [
        'ielts-mock-test' => 'seo.pages.mock-test',
        'ielts-ball-kalkulyatori' => 'seo.pages.calculator',
        'oquv-markazlari-uchun' => 'seo.pages.centers',
        'savol-javob' => 'seo.pages.faq',
    ];

    public function __construct(private readonly BlogRepository $blog) {}

    public function show(string $page)
    {
        abort_unless(isset(self::PAGES[$page]), 404);

        return view(self::PAGES[$page], [
            'latestArticles' => $this->blog->all()->take(3),
        ]);
    }
}
