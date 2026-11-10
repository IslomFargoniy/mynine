<?php

test('sitemap lists only public pages', function () {
    $response = $this->get('/sitemap.xml')
        ->assertOk()
        ->assertHeader('Content-Type', 'application/xml; charset=UTF-8');

    $xml = $response->getContent();

    expect($xml)->toContain('<loc>'.route('home').'</loc>')
        ->and($xml)->not->toContain('<loc>'.route('login').'</loc>')
        ->and($xml)->not->toContain('<loc>'.route('register').'</loc>')
        ->and($xml)->not->toContain('/dashboard')
        ->and($xml)->not->toContain('/practice');
});

test('robots.txt points crawlers to the sitemap and away from the exam area', function () {
    $robots = file_get_contents(public_path('robots.txt'));

    expect($robots)->toContain('Sitemap: https://mynine.uz/sitemap.xml')
        ->and($robots)->toContain('Disallow: /practice')
        ->and($robots)->toContain('Disallow: /attempt');
});

test('the home page has server-rendered SEO tags and auth pages are noindex', function () {
    $html = $this->get('/')->assertOk()->getContent();
    expect($html)->toContain('<meta name="description"')
        ->and($html)->toContain('<link rel="canonical" href="'.url('/').'"')
        ->and($html)->toContain('"@type":"EducationalOrganization"')
        ->and($html)->toContain('IELTS mock test');

    expect($this->get('/login')->getContent())->toContain('<meta name="robots" content="noindex, follow">');
    expect($this->get('/register')->getContent())->toContain('<meta name="robots" content="noindex, follow">');
});
