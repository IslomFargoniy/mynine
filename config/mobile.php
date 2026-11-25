<?php

/*
|--------------------------------------------------------------------------
| Mobile apps (Android, iOS) — student API /api/v1/student, docs/mobile/API.md
|--------------------------------------------------------------------------
*/

return [
    // Latest store version and the oldest one the API still serves. The apps only warn below `min_supported`
    // before a NEW attempt starts; a running exam is never blocked.
    'android' => [
        'latest' => env('MOBILE_ANDROID_LATEST', '1.0.0'),
        'min_supported' => env('MOBILE_ANDROID_MIN', '1.0.0'),
        'store_url' => env('MOBILE_ANDROID_STORE_URL', 'https://play.google.com/store/apps/details?id=uz.mynine.app'),
    ],
    'ios' => [
        'latest' => env('MOBILE_IOS_LATEST', '1.0.0'),
        'min_supported' => env('MOBILE_IOS_MIN', '1.0.0'),
        'store_url' => env('MOBILE_IOS_STORE_URL', 'https://apps.apple.com/app/mynine'),
    ],

    // Google id_token audiences accepted by POST /student/auth/google (web client + Android/iOS clients).
    'google_client_ids' => array_values(array_filter(array_merge(
        [env('GOOGLE_CLIENT_ID')],
        explode(',', (string) env('GOOGLE_MOBILE_CLIENT_IDS', '')),
    ))),

    // Apple bundle id (the identityToken "aud").
    'apple_bundle_id' => env('APPLE_BUNDLE_ID', 'uz.mynine.app'),

    // App Store / Google Play review sign-in: a fixed code that signs in to this Student account. Empty = off.
    'reviewer_code' => env('MOBILE_REVIEWER_CODE'),
    'reviewer_email' => env('MOBILE_REVIEWER_EMAIL'),

    'telegram_bot' => env('MOBILE_TELEGRAM_BOT', 'MynineUzBot'),

    // Sanctum token lifetime (days) for the apps.
    'token_days' => (int) env('MOBILE_TOKEN_DAYS', 90),
];
