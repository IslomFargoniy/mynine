<?php

/**
 * Every static t('key') / i18n.t('key') used in resources/js must exist in resources/lang/{en,uz,ru}.json
 * (flat key, or a dotted path into the nested objects the frontend reads). Dynamic keys (template literals,
 * variables) cannot be checked statically and are skipped.
 */
function translationKeysUsedInJs(): array
{
    $keys = [];
    $files = new RecursiveIteratorIterator(new RecursiveDirectoryIterator(dirname(__DIR__, 2).'/resources/js', FilesystemIterator::SKIP_DOTS));

    foreach ($files as $file) {
        if (! preg_match('/\.(tsx?|jsx?)$/', $file->getFilename())) {
            continue;
        }
        $source = file_get_contents($file->getPathname());
        // t('key'), t("key"), i18n.t('key') — not part of a longer identifier (e.g. "split(" or "post(").
        preg_match_all('/(?<![\w$])(?:i18n\.)?t\(\s*([\'"])([A-Za-z0-9_.\-]+)\1/', $source, $matches);
        foreach ($matches[2] as $key) {
            $keys[$key][] = str_replace(dirname(__DIR__, 2).'/', '', $file->getPathname());
        }
    }

    ksort($keys);

    return $keys;
}

function translationHasKey(array $dictionary, string $key): bool
{
    if (array_key_exists($key, $dictionary) && is_string($dictionary[$key])) {
        return true;
    }

    $node = $dictionary;
    foreach (explode('.', $key) as $segment) {
        if (! is_array($node) || ! array_key_exists($segment, $node)) {
            return false;
        }
        $node = $node[$segment];
    }

    return is_string($node);
}

test('every t() key used in resources/js exists in en, uz and ru', function () {
    $used = translationKeysUsedInJs();
    expect($used)->not->toBeEmpty();

    $missing = [];
    foreach (['en', 'uz', 'ru'] as $locale) {
        $dictionary = json_decode(file_get_contents(dirname(__DIR__, 2)."/resources/lang/{$locale}.json"), true, 512, JSON_THROW_ON_ERROR);
        foreach ($used as $key => $files) {
            if (! translationHasKey($dictionary, $key)) {
                $missing[] = "{$locale}: {$key} (".implode(', ', array_unique($files)).')';
            }
        }
    }

    expect($missing)->toBe([], "Missing translation keys:\n".implode("\n", $missing));
});

test('the three translation files have the same keys', function () {
    $flatten = function (array $data, string $prefix = '') use (&$flatten): array {
        $keys = [];
        foreach ($data as $key => $value) {
            $path = $prefix === '' ? (string) $key : $prefix.'.'.$key;
            $keys = is_array($value) ? [...$keys, ...$flatten($value, $path)] : [...$keys, $path];
        }

        return $keys;
    };

    $sets = [];
    foreach (['en', 'uz', 'ru'] as $locale) {
        $sets[$locale] = $flatten(json_decode(file_get_contents(dirname(__DIR__, 2)."/resources/lang/{$locale}.json"), true, 512, JSON_THROW_ON_ERROR));
    }

    expect(array_values(array_diff($sets['en'], $sets['uz'])))->toBe([], 'in en, not in uz')
        ->and(array_values(array_diff($sets['uz'], $sets['en'])))->toBe([], 'in uz, not in en')
        ->and(array_values(array_diff($sets['en'], $sets['ru'])))->toBe([], 'in en, not in ru')
        ->and(array_values(array_diff($sets['ru'], $sets['en'])))->toBe([], 'in ru, not in en');
});

test('every __() message used by the backend exists in en, uz and ru', function () {
    $root = dirname(__DIR__, 2);
    $keys = [];
    foreach (['app', 'resources/views', 'routes'] as $dir) {
        $files = new RecursiveIteratorIterator(new RecursiveDirectoryIterator("{$root}/{$dir}", FilesystemIterator::SKIP_DOTS));
        foreach ($files as $file) {
            if (str_ends_with($file->getFilename(), '.php')) {
                preg_match_all('/__\(\s*\'((?:[^\'\\\\]|\\\\.)+)\'/', file_get_contents($file->getPathname()), $matches);
                foreach ($matches[1] as $key) {
                    $keys[stripslashes($key)] = true;
                }
            }
        }
    }

    $missing = [];
    foreach (['en', 'uz', 'ru'] as $locale) {
        $dictionary = json_decode(file_get_contents("{$root}/resources/lang/{$locale}.json"), true, 512, JSON_THROW_ON_ERROR);
        foreach (array_keys($keys) as $key) {
            // PHP translation groups shipped by the framework (auth.*, validation.*, ...) are not ours.
            if (preg_match('/^(auth|validation|passwords|pagination)\./', $key)) {
                continue;
            }
            // Flat key (Laravel reads these) or a nested key the frontend translates from the flash message.
            if (! (array_key_exists($key, $dictionary) || translationHasKey($dictionary, $key))) {
                $missing[] = "{$locale}: {$key}";
            }
        }
    }

    expect($missing)->toBe([], "Missing backend translations:\n".implode("\n", $missing));
});
