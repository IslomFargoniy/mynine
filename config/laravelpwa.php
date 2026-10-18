<?php

return [
    'name' => 'Mynine.Uz',
    'manifest' => [
        'name' => env('APP_NAME', 'Mynine.Uz'),
        'short_name' => 'Mynine.Uz',
        'start_url' => '/',
        'background_color' => '#ffffff',
        'theme_color' => '#000000',
        'display' => 'standalone',
        'orientation' => 'any',
        'status_bar' => 'black',
        'icons' => [
            '72x72' => [
                'path' => '/images/logo/logo.png',
                'purpose' => 'any',
            ],
            '96x96' => [
                'path' => '/images/logo/logo.png',
                'purpose' => 'any',
            ],
            '128x128' => [
                'path' => '/images/logo/logo.png',
                'purpose' => 'any',
            ],
            '144x144' => [
                'path' => '/images/logo/logo.png',
                'purpose' => 'any',
            ],
            '152x152' => [
                'path' => '/images/logo/logo.png',
                'purpose' => 'any',
            ],
            '192x192' => [
                'path' => '/images/logo/logo.png',
                'purpose' => 'any',
            ],
            '384x384' => [
                'path' => '/images/logo/logo.png',
                'purpose' => 'any',
            ],
            '512x512' => [
                'path' => '/images/logo/logo.png',
                'purpose' => 'any',
            ],
        ],
        'splash' => [
            '640x1136' => '/images/logo/logo.png',
            '750x1334' => '/images/logo/logo.png',
            '828x1792' => '/images/logo/logo.png',
            '1125x2436' => '/images/logo/logo.png',
            '1242x2208' => '/images/logo/logo.png',
            '1242x2688' => '/images/logo/logo.png',
            '1536x2048' => '/images/logo/logo.png',
            '1668x2224' => '/images/logo/logo.png',
            '1668x2388' => '/images/logo/logo.png',
            '2048x2732' => '/images/logo/logo.png',
        ],
        'shortcuts' => [
            [
                'name' => 'Shortcut Link 1',
                'description' => 'Shortcut Link 1 Description',
                'url' => '/shortcutlink1',
                'icons' => [
                    'src' => '/images/logo/logo.png',
                    'purpose' => 'any',
                ],
            ],
            [
                'name' => 'Shortcut Link 2',
                'description' => 'Shortcut Link 2 Description',
                'url' => '/shortcutlink2',
                'icons' => [
                    'src' => '/images/logo/logo.png',
                    'purpose' => 'any',
                ],
            ],
        ],
        'custom' => [],
    ],
];
