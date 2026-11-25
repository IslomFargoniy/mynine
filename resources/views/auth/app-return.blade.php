<!doctype html>
<html lang="uz">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex">
    <title>Mynine</title>
    <style>
        body { margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center; background: #EEF1F8; font-family: system-ui, -apple-system, sans-serif; color: #0F172A; }
        .card { text-align: center; padding: 32px 24px; max-width: 360px; }
        h1 { font-size: 22px; margin: 0 0 8px; }
        p { color: #475569; margin: 0 0 24px; line-height: 1.5; }
        a { display: inline-block; background: #4F46E5; color: #fff; text-decoration: none; font-weight: 700; padding: 16px 32px; border-radius: 999px; }
    </style>
</head>
<body>
<div class="card">
    <h1>Mynine ilovasiga qayting</h1>
    <p>Ilova o'zi ochilmasa, tugmani bosing.</p>
    <a id="back" href="{{ $url }}">Ilovaga qaytish</a>
</div>
<script>window.location.replace(document.getElementById('back').href);</script>
</body>
</html>
