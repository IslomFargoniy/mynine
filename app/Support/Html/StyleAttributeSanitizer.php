<?php

namespace App\Support\Html;

use Symfony\Component\HtmlSanitizer\HtmlSanitizerConfig;
use Symfony\Component\HtmlSanitizer\Visitor\AttributeSanitizer\AttributeSanitizerInterface;

/**
 * style="" keeps only harmless formatting declarations (no positioning, no url(), no expressions), and
 * img src keeps data: URLs only for raster images.
 */
class StyleAttributeSanitizer implements AttributeSanitizerInterface
{
    /** CSS properties test content may use (what TinyMCE and the importers produce). */
    private const PROPERTIES = [
        'text-align', 'font-weight', 'font-style', 'font-size', 'text-decoration', 'text-decoration-line',
        'color', 'background-color', 'vertical-align', 'text-indent', 'list-style-type',
        'padding', 'padding-left', 'padding-right', 'padding-top', 'padding-bottom',
        'margin-left', 'margin-right', 'margin-top', 'margin-bottom',
        'border', 'border-collapse', 'border-width', 'border-style', 'border-color',
        'width', 'max-width', 'height', 'line-height',
    ];

    public function getSupportedElements(): ?array
    {
        return null;
    }

    public function getSupportedAttributes(): ?array
    {
        return ['style', 'src'];
    }

    public function sanitizeAttribute(string $element, string $attribute, string $value, HtmlSanitizerConfig $config): ?string
    {
        if ($attribute === 'src') {
            if (str_starts_with(strtolower(ltrim($value)), 'data:')) {
                return preg_match('#^data:image/(png|jpe?g|gif|webp|bmp);base64,[a-z0-9+/=\s]+$#i', trim($value)) ? $value : null;
            }

            return $value;
        }

        $kept = [];
        foreach (explode(';', $value) as $declaration) {
            if (! str_contains($declaration, ':')) {
                continue;
            }
            [$property, $propertyValue] = array_map('trim', explode(':', $declaration, 2));
            $property = strtolower($property);

            if (! in_array($property, self::PROPERTIES, true) || $propertyValue === '') {
                continue;
            }
            // Only plain values: words, numbers, units, #colours, rgb()/rgba(), commas. No url(), expression(), escapes.
            if (! preg_match('/^[a-z0-9#%.,\s\-()]+$/i', $propertyValue) || preg_match('/(url|expression|var|image|attr)\s*\(/i', $propertyValue)) {
                continue;
            }
            $kept[] = $property.': '.$propertyValue;
        }

        return $kept === [] ? null : implode('; ', $kept);
    }
}
