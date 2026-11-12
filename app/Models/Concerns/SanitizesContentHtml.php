<?php

namespace App\Models\Concerns;

use App\Support\Html\ContentSanitizer;

/**
 * Sanitizes the model's rich-text "textarea" on every save (editor, importers, AI imports, Mock Bank copies),
 * so stored test content is always allow-listed HTML.
 *
 * Models set $htmlAlways = true when the field is always HTML (parts, sections); otherwise it is sanitized
 * only when it contains markup (question / option text is usually plain text).
 */
trait SanitizesContentHtml
{
    public static function bootSanitizesContentHtml(): void
    {
        static::saving(function ($model) {
            if (! $model->isDirty('textarea')) {
                return;
            }

            $sanitizer = app(ContentSanitizer::class);
            $value = $model->getAttribute('textarea');
            $model->setAttribute('textarea', $model->sanitizesHtmlAlways()
                ? $sanitizer->sanitize($value)
                : $sanitizer->sanitizeIfHtml($value));
        });
    }

    protected function sanitizesHtmlAlways(): bool
    {
        return false;
    }
}
