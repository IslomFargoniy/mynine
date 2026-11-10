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

test('optional faq front matter is parsed, and malformed or missing faq stays backward compatible', function () {
    $dir = sys_get_temp_dir().'/blog-faq-'.uniqid();
    mkdir($dir);
    file_put_contents($dir.'/with-faq.md', <<<'MD'
---
title: "With FAQ"
date: 2026-10-20
faq:
  - q: "Birinchi savol?"
    a: "Birinchi javob."
  - q: "Javobsiz savol"
  - "noto'g'ri element"
---

Matn.
MD);
    file_put_contents($dir.'/without-faq.md', "---\ntitle: \"Without\"\ndate: 2026-10-21\n---\n\nMatn.\n");

    $repo = new BlogRepository($dir);

    expect($repo->find('with-faq')['faq'])->toBe([['q' => 'Birinchi savol?', 'a' => 'Birinchi javob.']])
        ->and($repo->find('without-faq')['faq'])->toBe([]);

    array_map('unlink', glob($dir.'/*.md'));
    rmdir($dir);
});

test('articles with faq render a visible faq and valid FAQPage structured data', function () {
    $withFaq = app(BlogRepository::class)->all()->filter(fn ($a) => $a['faq'] !== []);
    expect($withFaq)->not->toBeEmpty();

    foreach ($withFaq as $article) {
        $html = $this->get(route('blog.show', $article['slug']))->assertOk()
            ->assertSee('id="faq"', false)
            ->assertSee(e($article['faq'][0]['q']), false)
            ->getContent();

        preg_match_all('/<script type="application\/ld\+json">(.*?)<\/script>/s', $html, $m);
        $types = collect($m[1])->map(function ($json) use ($article) {
            $data = json_decode(trim($json), true);
            expect($data)->toBeArray("Invalid JSON-LD in {$article['slug']}");

            return $data['@type'];
        });
        expect($types->all())->toContain('BlogPosting', 'FAQPage', 'BreadcrumbList');

        $faq = collect($m[1])->map(fn ($j) => json_decode(trim($j), true))->firstWhere('@type', 'FAQPage');
        expect($faq['mainEntity'])->toHaveCount(count($article['faq']));
    }
});

test('articles without faq do not emit FAQPage markup', function () {
    $article = app(BlogRepository::class)->all()->first(fn ($a) => $a['faq'] === []);
    if (! $article) {
        $this->markTestSkipped('every article has an faq');
    }

    $this->get(route('blog.show', $article['slug']))->assertOk()->assertDontSee('"@type":"FAQPage"', false);
});
