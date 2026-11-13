import { useSyncExternalStore } from 'react';
import { Part, Question, Section } from '@/types';
import { buildRange } from '@/utils/rangeHelpers';

/**
 * IELTS "matching headings" placed inside the passage: the author writes `{14}` in the passage where question 14's
 * heading goes (normally on its own line above the paragraph). Such questions are answered by dragging a heading from
 * the right pane into that box instead of using the select. Only numbers of `matching` sections of the same part count;
 * any other `{…}` text in a passage is left alone.
 */
const MARKER = /\{(\d{1,3})\}/g;

export interface PassageSlot {
    number: number;
    question: Question;
    section: Section;
    sectionIndex: number;
}

/** Plain text of an HTML fragment. */
function plain(html: string | null | undefined): string {
    return (html ?? '')
        .replace(/<[^>]*>/g, ' ')
        .replace(/&nbsp;/gi, ' ')
        .replace(/\s+/g, ' ')
        .trim();
}

/** "Section A" / "Paragraph B" / "C" → the paragraph letter. */
export function paragraphLetter(questionHtml: string | null | undefined): string | null {
    const m = plain(questionHtml).match(/^(?:section|paragraph)?\s*([A-Za-z])\.?$/i);
    return m ? m[1].toUpperCase() : null;
}

/** First question number of each section (the right pane's numbering). */
function sectionStarts(part: Part): number[] {
    let order = Number(part.order ?? 0);
    return (part.sections ?? []).map((section) => {
        const start = order;
        order = start + section.questions.reduce((sum, q) => sum + Number(q.is_correct_count ?? 1), 0);
        return start;
    });
}

/**
 * How a paragraph's letter is written in the passages we have:
 *   clear: `<p><strong>A</strong> text…`, `<p><b>A.</b>…`, the letter alone on its line (`<p>A</p>`, `<h3>A</h3>`,
 *          `<p><strong>A</strong></p>`), inside spans or not;
 *   plain: `<p>A text…` / `<p>A. text…` (only trusted when every letter is found in order).
 */
export function paragraphLabelPattern(letter: string, clear: boolean): string {
    const ws = '(?:\\s|&nbsp;)';
    const tags = '(?:\\s|&nbsp;|<[^>]+>)';
    const open = '<(?:p|div|h[1-6])(?:\\s[^>]*)?>';
    if (clear) {
        const bold = `${open}${ws}*(?:<(?:span|em)[^>]*>)*<(?:strong|b)(?:\\s[^>]*)?>${ws}*${letter}[.:)]?${ws}*</(?:strong|b)>`;
        const alone = `${open}${tags}*${letter}[.:)]?${tags}*</(?:p|div|h[1-6])>`;
        return `(?:${bold}|${alone})`;
    }
    return `<(?:p|div)(?:\\s[^>]*)?>${ws}*${letter}[.:)]?${ws}+`;
}

/**
 * Without `{n}` markers: a matching section whose questions are "Section A" … "Section F" gets a box above each
 * passage paragraph that opens with that letter (bold "A", or a plain "A " when every letter is found in order).
 */
export function insertAutoMarkers(html: string, part: Part): string {
    if (!html || /\{\d{1,3}\}/.test(html) || /passage-drop/.test(html)) return html;
    const starts = sectionStarts(part);
    let out = html;
    (part.sections ?? []).forEach((section, si) => {
        if (section.question_type?.type !== 'matching') return;
        const wanted = section.questions
            .map((q, i) => ({ letter: paragraphLetter(q.textarea), number: starts[si] + 1 + i }))
            .filter((w): w is { letter: string; number: number } => !!w.letter);
        if (wanted.length === 0) return;

        const find = (letter: string, bold: boolean, from: number): number => {
            const re = new RegExp(paragraphLabelPattern(letter, bold), 'g');
            re.lastIndex = from;
            const m = re.exec(out);
            return m ? m.index : -1;
        };
        for (const bold of [true, false]) {
            const at: number[] = [];
            let from = 0;
            for (const w of wanted) {
                const i = find(w.letter, bold, from);
                if (i < 0) break;
                at.push(i);
                from = i + 1;
            }
            // Clear labels (bold, or alone on their line) may be partial; a plain "A " opening a sentence only counts
            // when every letter is found in order.
            if (at.length === 0 || (!bold && at.length < wanted.length)) continue;
            for (let k = at.length - 1; k >= 0; k--) out = `${out.slice(0, at[k])}<p>{${wanted[k].number}}</p>${out.slice(at[k])}`;
            return;
        }
    });
    return out;
}

/**
 * "Which paragraph contains the following information?" (matching with letters A–H, statements as questions): the
 * candidate drags the question numbers onto the paragraphs. A zone `{z<sectionId>:A}` goes above each paragraph
 * letter found in the passage; the answer of a question dropped there is that letter (as with the box / select).
 */
export interface ParagraphZone {
    key: string;
    letter: string;
    section: Section;
    sectionIndex: number;
}

const ZONE = /\{z(\d+):([A-Z])\}/g;

export function isParagraphInfoSection(section: Section): boolean {
    if (section.question_type?.type !== 'matching' || (section.options?.length ?? 0) > 0) return false;
    const letters = buildRange(section.from_option, section.to_option);
    if (letters.length < 2 || !letters.every((l) => /^[A-Z]$/.test(l))) return false;
    if (Object.keys(headingTexts(section.textarea, letters)).length > 0) return false;
    // "Section A" questions are headings for the paragraphs (boxes of their own), not information to place.
    return !section.questions.some((q) => paragraphLetter(q.textarea));
}

export function insertParagraphZones(html: string, part: Part): string {
    if (!html || /\{z\d+:[A-Z]\}/.test(html) || /passage-zone/.test(html)) return html;
    const sectionIndex = (part.sections ?? []).findIndex(isParagraphInfoSection);
    if (sectionIndex < 0) return html;
    const section = part.sections[sectionIndex];
    const letters = buildRange(section.from_option, section.to_option);
    for (const clear of [true, false]) {
        const at: { letter: string; index: number }[] = [];
        let from = 0;
        for (const letter of letters) {
            const re = new RegExp(paragraphLabelPattern(letter, clear), 'g');
            re.lastIndex = from;
            const m = re.exec(html);
            if (!m) continue;
            at.push({ letter, index: m.index });
            from = m.index + 1;
        }
        if (at.length < 2 || (!clear && at.length < letters.length)) continue;
        let out = html;
        for (let k = at.length - 1; k >= 0; k--) {
            out = `${out.slice(0, at[k].index)}<p>{z${section.id}:${at[k].letter}}</p>${out.slice(at[k].index)}`;
        }
        return out;
    }
    return html;
}

/** The passage HTML with the heading boxes' markers (written by the author, or found from "Section A"…) and the
 *  paragraph zones of a "which paragraph contains…" task. */
export function passageHtml(part: Part | null | undefined): string {
    if (!part) return '';
    return insertParagraphZones(insertAutoMarkers(part.textarea ?? '', part), part);
}

export function passageZones(part: Part | null | undefined): Map<string, ParagraphZone> {
    const out = new Map<string, ParagraphZone>();
    if (!part) return out;
    for (const m of passageHtml(part).matchAll(ZONE)) {
        const sectionIndex = (part.sections ?? []).findIndex((s) => s.id === Number(m[1]));
        if (sectionIndex < 0) continue;
        const key = `${m[1]}:${m[2]}`;
        out.set(key, { key, letter: m[2], section: part.sections[sectionIndex], sectionIndex });
    }
    return out;
}

/** Replaces the zone markers with empty `span.passage-zone` hosts (React fills them through portals). */
export function mountParagraphZones(root: HTMLElement, zones: Map<string, ParagraphZone>): Map<string, HTMLElement> {
    const hosts = new Map<string, HTMLElement>();
    root.querySelectorAll<HTMLElement>('span.passage-zone').forEach((el) => {
        const key = el.dataset.zone ?? '';
        if (zones.has(key) && !hosts.has(key)) {
            el.innerHTML = '';
            el.contentEditable = 'false';
            hosts.set(key, el);
        } else {
            el.remove();
        }
    });
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    const texts: Text[] = [];
    while (walker.nextNode()) {
        const t = walker.currentNode as Text;
        if (/\{z\d+:[A-Z]\}/.test(t.data)) texts.push(t);
    }
    texts.forEach((t) => {
        const frag = document.createDocumentFragment();
        t.data.split(/(\{z\d+:[A-Z]\})/).forEach((p) => {
            const m = p.match(/^\{z(\d+):([A-Z])\}$/);
            const key = m ? `${m[1]}:${m[2]}` : '';
            if (m && zones.has(key) && !hosts.has(key)) {
                const host = document.createElement('span');
                host.className = 'passage-zone';
                host.dataset.zone = key;
                host.contentEditable = 'false';
                hosts.set(key, host);
                frag.appendChild(host);
            } else if (p && !m) {
                frag.appendChild(document.createTextNode(p));
            }
        });
        t.replaceWith(frag);
    });
    return hosts;
}

/** Drag payload of a question number (onto a paragraph zone). */
export const QUESTION_MIME = 'application/x-mynine-question';

export function writeQuestionDrag(e: React.DragEvent, questionId: number) {
    e.dataTransfer.setData(QUESTION_MIME, String(questionId));
    e.dataTransfer.setData('text/plain', String(questionId));
    e.dataTransfer.effectAllowed = 'move';
}

export function readQuestionDrag(e: React.DragEvent): number | null {
    const v = Number(e.dataTransfer.getData(QUESTION_MIME));
    return Number.isFinite(v) && v > 0 ? v : null;
}

export function passageSlots(part: Part | null | undefined): Map<number, PassageSlot> {
    const out = new Map<number, PassageSlot>();
    if (!part) return out;
    const html = passageHtml(part);
    if (!/\{\d{1,3}\}/.test(html)) return out;

    const present = new Set(Array.from(html.matchAll(MARKER), (m) => Number(m[1])));
    const starts = sectionStarts(part);
    (part.sections ?? []).forEach((section, sectionIndex) => {
        if (section.question_type?.type !== 'matching') return;
        section.questions.forEach((question, i) => {
            const number = starts[sectionIndex] + 1 + i;
            if (present.has(number)) out.set(number, { number, question, section, sectionIndex });
        });
    });
    return out;
}

/**
 * Headings given only as a range (i–vii) with their texts in the section's instructions (`<li>vi Developments…</li>`):
 * value → full text, so the chips and boxes show the heading, while the answer stays the number.
 */
export function headingTexts(sectionHtml: string | null | undefined, values: string[]): Record<string, string> {
    const items = Array.from((sectionHtml ?? '').matchAll(/<li[^>]*>([\s\S]*?)<\/li>/gi), (m) => plain(m[1]));
    const out: Record<string, string> = {};
    values.forEach((v) => {
        const hit = items.find((t) => t.toLowerCase().startsWith(`${v.toLowerCase()} `) || t.toLowerCase().startsWith(`${v.toLowerCase()}.`));
        if (hit) out[v] = hit;
    });
    return out;
}

/** In drag mode the list of headings becomes the draggable list: the static copy in the instructions goes. */
export function stripHeadingList(sectionHtml: string, values: string[]): string {
    const texts = headingTexts(sectionHtml, values);
    if (Object.keys(texts).length < Math.max(2, values.length - 1)) return sectionHtml;
    return sectionHtml
        .replace(/<(ul|ol)[^>]*>([\s\S]*?)<\/\1>/gi, (list, _t, inner: string) => {
            const lis = Array.from(inner.matchAll(/<li[^>]*>([\s\S]*?)<\/li>/gi), (m) => plain(m[1]).toLowerCase());
            const isHeadings = lis.length > 0 && lis.every((t) => values.some((v) => t.startsWith(`${v.toLowerCase()} `) || t.startsWith(`${v.toLowerCase()}.`)));
            return isHeadings ? '' : list;
        })
        .replace(/<(p|h[1-6])[^>]*>(?:\s|&nbsp;|<\/?(?:strong|b|em)>)*list of headings(?:\s|&nbsp;|<\/?(?:strong|b|em)>)*<\/\1>/gi, '');
}

/** Question ids answered in the passage (their select is not shown in the right pane). */
export function passageSlotQuestionIds(slots: Map<number, PassageSlot>): Set<number> {
    return new Set(Array.from(slots.values(), (s) => s.question.id));
}

/** A marker that opens a paragraph is moved to its own line above it (as in the real test). */
export function hoistPassageMarkers(html: string): string {
    return html
        .replace(/<p(\s[^>]*)?>(?:\s|&nbsp;)*(\{\d{1,3}\})(?:\s|&nbsp;)*/gi, '<p>$2</p><p$1>')
        .replace(/(<p>\{\d{1,3}\}<\/p>)<p(?:\s[^>]*)?>(?:\s|&nbsp;|<br\s*\/?>)*<\/p>/gi, '$1');
}

/**
 * Replaces the markers of [slots] in the rendered passage with empty `span.passage-drop` hosts (React fills them
 * through portals) and empties hosts restored from saved highlight HTML. Returns the hosts by question number.
 */
export function mountPassageSlots(root: HTMLElement, slots: Map<number, PassageSlot>): Map<number, HTMLElement> {
    const hosts = new Map<number, HTMLElement>();
    root.querySelectorAll<HTMLElement>('span.passage-drop').forEach((el) => {
        const n = Number(el.dataset.num);
        if (slots.has(n) && !hosts.has(n)) {
            el.innerHTML = '';
            el.contentEditable = 'false';
            hosts.set(n, el);
        } else {
            el.replaceWith(document.createTextNode(`{${el.dataset.num}}`));
        }
    });

    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    const texts: Text[] = [];
    while (walker.nextNode()) {
        const t = walker.currentNode as Text;
        if (/\{\d{1,3}\}/.test(t.data)) texts.push(t);
    }
    texts.forEach((t) => {
        const parts = t.data.split(/(\{\d{1,3}\})/);
        const frag = document.createDocumentFragment();
        parts.forEach((p) => {
            const m = p.match(/^\{(\d{1,3})\}$/);
            const n = m ? Number(m[1]) : NaN;
            if (m && slots.has(n) && !hosts.has(n)) {
                const host = document.createElement('span');
                host.className = 'passage-drop';
                host.dataset.num = String(n);
                host.contentEditable = 'false';
                hosts.set(n, host);
                frag.appendChild(host);
            } else if (p) {
                frag.appendChild(document.createTextNode(p));
            }
        });
        t.replaceWith(frag);
    });
    return hosts;
}

/** Drag payload type of a heading (from the list, or moved out of another box). */
export const HEADING_MIME = 'application/x-mynine-heading';

export interface HeadingDrag {
    label: string;
    /** Question whose box the heading was dragged out of. */
    fromQuestionId?: number;
}

export function readHeadingDrag(e: React.DragEvent): HeadingDrag | null {
    try {
        const raw = e.dataTransfer.getData(HEADING_MIME);
        return raw ? (JSON.parse(raw) as HeadingDrag) : null;
    } catch {
        return null;
    }
}

export function writeHeadingDrag(e: React.DragEvent, drag: HeadingDrag) {
    e.dataTransfer.setData(HEADING_MIME, JSON.stringify(drag));
    e.dataTransfer.setData('text/plain', drag.label);
    e.dataTransfer.effectAllowed = 'move';
}

/** Tap-to-place (touch screens, keyboard): the heading picked in the list waits for a tap on a box. */
let picked: string | null = null;
const listeners = new Set<() => void>();

export const headingPick = {
    get: () => picked,
    set(v: string | null) {
        picked = v;
        listeners.forEach((f) => f());
    },
    subscribe(f: () => void) {
        listeners.add(f);
        return () => {
            listeners.delete(f);
        };
    },
};

export function usePickedHeading(): string | null {
    return useSyncExternalStore(headingPick.subscribe, headingPick.get, headingPick.get);
}

/** Tap-to-place for statements ("which paragraph contains…"): the picked question waits for a tap on a paragraph. */
let pickedQuestion: number | null = null;
const questionListeners = new Set<() => void>();

export const questionPick = {
    get: () => pickedQuestion,
    set(v: number | null) {
        pickedQuestion = v;
        questionListeners.forEach((f) => f());
    },
    subscribe(f: () => void) {
        questionListeners.add(f);
        return () => {
            questionListeners.delete(f);
        };
    },
};

export function usePickedQuestion(): number | null {
    return useSyncExternalStore(questionPick.subscribe, questionPick.get, questionPick.get);
}
