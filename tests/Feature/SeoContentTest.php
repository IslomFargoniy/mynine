<?php

use App\Http\Controllers\SeoPageController;
use App\Services\BlogRepository;

test('blog index lists every article with crawlable links', function () {
    $articles = app(BlogRepository::class)->all();
    expect($articles)->not->toBeEmpty();

    $response = $this->get(route('blog.index'))->assertOk()->assertSee('<html lang="uz">', false);

    foreach ($articles as $article) {
        $response->assertSee(route('blog.show', $article['slug']), false);
    }
});

test('each article renders server-side with meta tags and structured data', function () {
    foreach (app(BlogRepository::class)->all() as $article) {
        $this->get(route('blog.show', $article['slug']))
            ->assertOk()
            ->assertSee('<h1', false)
            ->assertSee(e($article['title']), false)
            ->assertSee('<meta name="description" content="'.e($article['description']).'">', false)
            ->assertSee('<link rel="canonical" href="'.route('blog.show', $article['slug']).'">', false)
            ->assertSee('"@type":"BlogPosting"', false)
            ->assertSee('"@type":"BreadcrumbList"', false);
    }
});

test('unknown articles return 404', function () {
    $this->get('/blog/mavjud-emas')->assertNotFound();
});

test('every internal link inside articles points to an existing page', function () {
    $known = collect(app(BlogRepository::class)->all())->map(fn ($a) => '/blog/'.$a['slug'])
        ->merge(collect(array_keys(SeoPageController::PAGES))->map(fn ($p) => '/'.$p))
        ->push('/blog', '/', '/login', '/register');

    foreach (app(BlogRepository::class)->all() as $article) {
        preg_match_all('/href="(\/[^"#]*)/', $article['html'], $m);
        foreach ($m[1] as $href) {
            expect($known->contains($href))->toBeTrue("Broken link {$href} in {$article['slug']}");
        }
    }
});

test('landing pages render with their own titles', function () {
    foreach (array_keys(SeoPageController::PAGES) as $page) {
        $this->get('/'.$page)->assertOk()->assertSee('<h1', false)->assertSee('<link rel="canonical"', false);
    }

    $this->get('/savol-javob')->assertSee('"@type":"FAQPage"', false);
    $this->get('/ielts-ball-kalkulyatori')->assertSee('id="calc"', false);
});

test('sitemap contains landing pages and all articles', function () {
    $xml = $this->get('/sitemap.xml')->assertOk()->getContent();

    expect($xml)->toContain('<loc>'.route('blog.index').'</loc>');
    foreach (array_keys(SeoPageController::PAGES) as $page) {
        expect($xml)->toContain('<loc>'.route('seo.page', $page).'</loc>');
    }
    foreach (app(BlogRepository::class)->all() as $article) {
        expect($xml)->toContain('<loc>'.route('blog.show', $article['slug']).'</loc>');
    }

    $parsed = simplexml_load_string($xml);
    expect($parsed)->not->toBeFalse();
});
