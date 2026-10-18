<?php

test('sitemap lists only public pages', function () {
    $response = $this->get('/sitemap.xml')
        ->assertOk()
        ->assertHeader('Content-Type', 'application/xml; charset=UTF-8');

    $xml = $response->getContent();

    expect($xml)->toContain('<loc>'.route('home').'</loc>')
        ->and($xml)->toContain('<loc>'.route('login').'</loc>')
        ->and($xml)->toContain('<loc>'.route('register').'</loc>')
        ->and($xml)->not->toContain('/dashboard')
        ->and($xml)->not->toContain('/practice');
});

test('robots.txt points crawlers to the sitemap and away from the exam area', function () {
    $robots = file_get_contents(public_path('robots.txt'));

    expect($robots)->toContain('Sitemap: https://mynine.uz/sitemap.xml')
        ->and($robots)->toContain('Disallow: /practice')
        ->and($robots)->toContain('Disallow: /attempt');
});
