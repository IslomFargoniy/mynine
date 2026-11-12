import { sanitizeHtml } from '@/utils/sanitize-html';

const getImagePrefix = () => {
    return process.env.NODE_ENV === 'production' ? '' : '';
};

const cleanTinyMce = (html: string | null | undefined): string => {
    if (!html) return '';

    let cleaned = html;

    // 1️⃣ Remove zero-width spaces and hidden chars
    cleaned = cleaned.replace(/[\u200B-\u200D\uFEFF]/g, '');

    // 2️⃣ Replace non-breaking spaces with normal space
    cleaned = cleaned.replace(/&nbsp;/gi, ' ');

    // 3️⃣ Fix missing spaces between inline tags like </span><span>
    cleaned = cleaned.replace(/<\/(span|b|i|u|strong|em)>(?=<\1)/gi, '</$1> ');
    cleaned = cleaned.replace(/<\/(span|b|i|u|strong|em)>(?=<[a-z])/gi, '</$1> ');

    // 4️⃣ Add space between closing and opening inline tags generally
    cleaned = cleaned.replace(/><(span|b|i|u|strong|em)/gi, '> <$1');

    // 5️⃣ Remove only problematic inline style properties (nowrap, fixed widths)
    // but PRESERVE formatting styles (font-weight, font-size, text-align, color, etc.)
    cleaned = cleaned.replace(/(<[a-z][a-z0-9]*\s+[^>]*?)style="([^"]*)"([^>]*?>)/gi, (match, before, styleVal, after) => {
        const cleanedStyle = styleVal
            .replace(/white-space\s*:\s*nowrap;?/gi, '')
            .replace(/word-break\s*:\s*[^;]+;?/gi, '')
            .replace(/overflow-wrap\s*:\s*[^;]+;?/gi, '')
            .trim();

        if (cleanedStyle) {
            return `${before}style="${cleanedStyle}"${after}`;
        }
        return `${before}${after}`.replace(/\s{2,}/g, ' ');
    });

    // 6️⃣ Collapse multiple spaces but keep one
    cleaned = cleaned.replace(/[ \t]{2,}/g, ' ');

    // 7️⃣ Trim, then allow-list sanitize (this helper feeds dangerouslySetInnerHTML)
    return sanitizeHtml(cleaned.trim());
};

export { getImagePrefix, cleanTinyMce };
