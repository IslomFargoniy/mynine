<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" @class(['dark' => ($appearance ?? 'system') == 'dark'])>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">

        <script src="https://telegram.org/js/telegram-web-app.js"></script>

        <script>
            // Only inside a real Telegram Mini App (initData is empty in a normal browser);
            // calling WebApp methods elsewhere just floods the console with postEvent logs.
            if (window.Telegram && window.Telegram.WebApp && window.Telegram.WebApp.initData) {
                const WebApp = window.Telegram.WebApp;
                WebApp.ready();

                // Always expand (safe for both mobile & desktop)
                WebApp.expand();

                // Fullscreen only on laptop/desktop (Bot API 8.0+)
                if ((WebApp.platform === "web" || WebApp.platform === "tdesktop") && WebApp.isVersionAtLeast && WebApp.isVersionAtLeast('8.0')) {
                    WebApp.requestFullscreen();
                }
            }
        </script>

        {{-- 🔑 Laravel CSRF token --}}
        <meta name="csrf-token" content="{{ csrf_token() }}">

        @laravelPWA

        {{-- Inline script to detect system dark mode preference and apply it immediately --}}
        <script>
            (function() {
                const appearance = '{{ $appearance ?? "system" }}';

                if (appearance === 'system') {
                    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;

                    if (prefersDark) {
                        document.documentElement.classList.add('dark');
                    }
                }
            })();
        </script>

        {{-- Inline style to set the HTML background color based on our theme in app.css --}}
        <style>
            html {
                background-color: oklch(1 0 0);
            }

            html.dark {
                background-color: oklch(0.145 0 0);
            }
        </style>

        <title inertia>{{ config('app.name', 'Laravel') }}</title>

        <link rel="preconnect" href="https://fonts.bunny.net">
        <link href="https://fonts.bunny.net/css?family=inter:400,500,600,700" rel="stylesheet" />

        @routes
        @viteReactRefresh
        @vite(['resources/js/app.tsx', "resources/js/pages/{$page['component']}.tsx"])
        @inertiaHead
    </head>
    <body class="font-sans antialiased overflow-x-hidden">
        @inertia
    </body>
</html>
