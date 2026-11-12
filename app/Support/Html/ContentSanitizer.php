<?php

namespace App\Support\Html;

use Symfony\Component\HtmlSanitizer\HtmlSanitizer;
use Symfony\Component\HtmlSanitizer\HtmlSanitizerConfig;

/**
 * Allow-list sanitizer for test content HTML (parts, sections, questions, options). Test content written by
 * one center is shown to other people (SuperAdmin, candidates), so it must never carry scripts, event
 * handlers, javascript: links or layout-breaking CSS. Keeps the formatting the editor and the importers
 * produce and the "{answer}" / "{}" gap markers (braces are plain text).
 */
class ContentSanitizer
{
    private ?HtmlSanitizer $sanitizer = null;

    private const BLOCK = ['p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote', 'ul', 'ol', 'li', 'hr', 'br'];

    private const INLINE = ['span', 'strong', 'b', 'em', 'i', 'u', 's', 'strike', 'sup', 'sub', 'small', 'mark', 'code', 'pre'];

    private const TABLE = ['table', 'thead', 'tbody', 'tfoot', 'tr', 'caption', 'colgroup', 'col'];

    public function sanitize(?string $html): ?string
    {
        if ($html === null || $html === '') {
            return $html;
        }

        return $this->sanitizer()->sanitize($html);
    }

    /**
     * For fields that are usually plain text (question and option text): leave them untouched unless they
     * contain markup, so "A & B" or "x < y" are not turned into entities.
     */
    public function sanitizeIfHtml(?string $value): ?string
    {
        if ($value === null || ! preg_match('/<[a-z!\/?]|&#|&[a-z]+;/i', $value)) {
            return $value;
        }

        return $this->sanitize($value);
    }

    private function sanitizer(): HtmlSanitizer
    {
        if ($this->sanitizer) {
            return $this->sanitizer;
        }

        $config = (new HtmlSanitizerConfig)
            ->allowLinkSchemes(['http', 'https', 'mailto'])
            ->allowMediaSchemes(['http', 'https', 'data'])
            ->allowRelativeMedias()
            ->forceAttribute('a', 'rel', 'noopener noreferrer nofollow')
            ->withAttributeSanitizer(new StyleAttributeSanitizer)
            ->withMaxInputLength(5_000_000);

        foreach ([...self::BLOCK, ...self::INLINE, ...self::TABLE] as $element) {
            $config = $config->allowElement($element, ['style']);
        }
        foreach (['td', 'th'] as $cell) {
            $config = $config->allowElement($cell, ['style', 'colspan', 'rowspan', 'align', 'valign']);
        }
        $config = $config
            ->allowElement('table', ['style', 'border', 'cellpadding', 'cellspacing'])
            ->allowElement('col', ['style', 'span'])
            ->allowElement('ol', ['style', 'start', 'type'])
            ->allowElement('img', ['src', 'alt', 'title', 'width', 'height', 'style'])
            ->allowElement('a', ['href', 'title', 'rel']);

        return $this->sanitizer = new HtmlSanitizer($config);
    }
}
