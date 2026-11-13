import { sanitizeHtml } from '@/utils/sanitize-html';
import { normalizeContentHtml } from '@/utils/util';

export function sanitizeAndInsertWbr(html: string, maxLen = 40): string {
    if (!html) return '';

    const parser = new DOMParser();
    const doc = parser.parseFromString(sanitizeHtml(normalizeContentHtml(html)), 'text/html');

    const SKIP_TAGS = new Set(['PRE', 'CODE', 'STYLE', 'SCRIPT', 'TEXTAREA']);

    // Selectively clean styles
    const allEls = Array.from(doc.body.querySelectorAll('*'));
    allEls.forEach((el) => {
        if (SKIP_TAGS.has(el.tagName)) return;

        if (el.hasAttribute('style')) {
            const style = el.getAttribute('style') || '';
            // remove only problematic properties
            const cleaned = style
                .replace(/white-space\s*:\s*nowrap;?/gi, '')
                .replace(/word-break\s*:\s*[^;]+;?/gi, '')
                .replace(/overflow-wrap\s*:\s*[^;]+;?/gi, '')
                .replace(/width\s*:\s*[^;]+;?/gi, '')
                .replace(/height\s*:\s*[^;]+;?/gi, '');
            if (cleaned.trim()) {
                el.setAttribute('style', cleaned);
            } else {
                el.removeAttribute('style');
            }
        }

        el.removeAttribute('width');
        el.removeAttribute('height');
        if (el.hasAttribute('nowrap')) el.removeAttribute('nowrap');
    });

    // same text node cleanup + <wbr> insertion as before
    const walker = doc.createTreeWalker(doc.body, NodeFilter.SHOW_TEXT, null);
    const textNodes: Node[] = [];
    while (walker.nextNode()) textNodes.push(walker.currentNode);

    textNodes.forEach((tn) => {
        const parent = tn.parentElement;
        if (!parent) return;
        if (SKIP_TAGS.has(parent.tagName)) {
            tn.nodeValue = (tn.nodeValue ?? '')
                .replace(/\u00A0/g, ' ')
                .replace(/[\u200B-\u200D\uFEFF]/g, '');
            return;
        }

        const text = (tn.nodeValue ?? '')
            .replace(/\u00A0/g, ' ')
            .replace(/[\u200B-\u200D\uFEFF]/g, '');

        if (!text.trim()) {
            tn.nodeValue = text;
            return;
        }

        const parts = text.split(/(\s+)/);
        const frag = doc.createDocumentFragment();

        parts.forEach((part) => {
            if (part.length > 0 && !/\s+/.test(part) && part.length > maxLen) {
                for (let i = 0; i < part.length; i += maxLen) {
                    const slice = part.slice(i, i + maxLen);
                    frag.appendChild(doc.createTextNode(slice));
                    if (i + maxLen < part.length) frag.appendChild(doc.createElement('wbr'));
                }
            } else {
                frag.appendChild(doc.createTextNode(part));
            }
        });

        tn.parentNode?.replaceChild(frag, tn);
    });

    return sanitizeHtml(doc.body.innerHTML);
}
