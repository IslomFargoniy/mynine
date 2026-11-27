<?php

namespace App\Support;

/** Plain-text version of an HTML email: links kept as "text (url)", blocks on their own lines. */
class MailText
{
    public static function fromHtml(string $html): string
    {
        $html = preg_replace('#<(style|script|head)[^>]*>.*?</\1>#is', '', $html);
        $html = preg_replace_callback('#<a[^>]*href=["\']([^"\']+)["\'][^>]*>(.*?)</a>#is', function ($m) {
            $text = trim(strip_tags($m[2]));

            return $text === '' || $text === $m[1] ? $m[1] : "{$text} ({$m[1]})";
        }, $html);
        $html = preg_replace('#<br\s*/?>#i', "\n", $html);
        $html = preg_replace('#</(p|div|tr|h[1-6]|li|table)>#i', "\n", $html);
        $text = html_entity_decode(strip_tags($html), ENT_QUOTES | ENT_HTML5, 'UTF-8');
        $text = preg_replace("/[ \t]+/", ' ', $text);
        $text = preg_replace("/ *\n */", "\n", $text);

        return trim(preg_replace("/\n{3,}/", "\n\n", $text));
    }
}
