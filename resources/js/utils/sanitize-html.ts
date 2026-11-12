import DOMPurify from 'dompurify';

/**
 * Allow-list sanitizer for test content HTML (passages, section text) before it reaches the DOM.
 * The server already sanitizes on save (App\Support\Html\ContentSanitizer); this is the second layer for
 * every dangerouslySetInnerHTML / innerHTML / html-react-parser use on test content.
 * Without a DOM (SSR) nothing is rendered rather than unsanitized HTML.
 */
export function sanitizeHtml(html: string | null | undefined): string {
    if (!html) return '';
    if (typeof window === 'undefined' || !DOMPurify.isSupported) return '';

    return DOMPurify.sanitize(html, {
        USE_PROFILES: { html: true },
        FORBID_TAGS: ['style', 'form', 'input', 'button', 'textarea', 'select', 'iframe', 'object', 'embed', 'svg', 'math'],
        FORBID_ATTR: ['action', 'formaction'],
        ALLOW_DATA_ATTR: true,
    });
}

if (typeof window !== 'undefined' && DOMPurify.isSupported) {
    DOMPurify.addHook('afterSanitizeAttributes', (node) => {
        if (node.tagName === 'A') {
            node.setAttribute('rel', 'noopener noreferrer nofollow');
            if (node.getAttribute('target')) node.setAttribute('target', '_blank');
        }
    });
}
