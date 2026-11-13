import { sanitizeHtml } from '@/utils/sanitize-html';

const getImagePrefix = () => {
    return process.env.NODE_ENV === 'production' ? '' : '';
};

/**
 * Content pasted from Word / PDFs / the AI import, made readable everywhere it is shown:
 *   - spans glued word to word (`<span>The</span><span>Model</span>`) get a space, but nothing is added before
 *     punctuation (`America</span><span>.` stays "America.");
 *   - inline styles that break the page's typography or width go (word / letter spacing, font family / size, line
 *     height, indent, nowrap, word-break, fixed widths and heights except on images); bold, italic, colour and
 *     alignment stay;
 *   - text tokenised word by word is rejoined: "America ." → "America.", "California ' s" → "California's".
 */
export function normalizeContentHtml(html: string): string {
    if (!html) return '';
    let out = html.replace(
        /([\p{L}\p{N}])(<\/(?:span|b|i|u|strong|em)>)(<(?:span|b|i|u|strong|em)(?:\s[^>]*)?>)(?=[\p{L}\p{N}])/gu,
        '$1$2 $3',
    );
    out = out.replace(/(<([a-z][a-z0-9]*)\s[^>]*?)style="([^"]*)"([^>]*>)/gi, (_m, before: string, tag: string, styleVal: string, after: string) => {
        // Fixed sizes make pasted blocks wider than the pane (images keep theirs).
        const sizes = tag.toLowerCase() === 'img' ? '' : '|width|min-width|max-width|height|min-height';
        const drop = new RegExp(`^(word-spacing|letter-spacing|font-family|font-size|line-height|text-indent|white-space|word-break|overflow-wrap${sizes})\\s*:`, 'i');
        const kept = styleVal
            .split(';')
            .map((d) => d.trim())
            .filter((d) => d && !drop.test(d))
            .join('; ');
        return kept ? `${before}style="${kept}"${after}` : `${before.trimEnd()}${after}`;
    });
    out = out.replace(/(<(?:table|td|th|div|p|col|colgroup)\b[^>]*?)\s(?:width|height)="[^"]*"/gi, '$1');
    // Text only (never inside tags or `{…}` blanks).
    return out
        .split(/(<[^>]+>)/)
        .map((part) =>
            part.startsWith('<')
                ? part
                : part
                      .replace(/([\p{L}\p{N}"'”’)\]}]) +([.,;:!?%)](?=\s|$))/gu, '$1$2')
                      .replace(/(\p{L}) ?['’] ?(s|t|d|m|ll|re|ve)\b/gu, "$1'$2"),
        )
        .join('');
}

const cleanTinyMce = (html: string | null | undefined): string => {
    if (!html) return '';

    let cleaned = html;

    // 1️⃣ Remove zero-width spaces and hidden chars
    cleaned = cleaned.replace(/[\u200B-\u200D\uFEFF]/g, '');

    // 2️⃣ Replace non-breaking spaces with normal space
    cleaned = cleaned.replace(/&nbsp;/gi, ' ');

    cleaned = normalizeContentHtml(cleaned);

    // 6️⃣ Collapse multiple spaces but keep one
    cleaned = cleaned.replace(/[ \t]{2,}/g, ' ');

    // 7️⃣ Trim, then allow-list sanitize (this helper feeds dangerouslySetInnerHTML)
    return sanitizeHtml(cleaned.trim());
};

export { getImagePrefix, cleanTinyMce };
