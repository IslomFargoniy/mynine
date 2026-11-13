import { useSyncExternalStore } from 'react';
import { Part, Question, Section } from '@/types';

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

export function passageSlots(part: Part | null | undefined): Map<number, PassageSlot> {
    const out = new Map<number, PassageSlot>();
    const html = part?.textarea ?? '';
    if (!part || !/\{\d{1,3}\}/.test(html)) return out;

    const present = new Set(Array.from(html.matchAll(MARKER), (m) => Number(m[1])));
    let order = Number(part.order ?? 0);
    (part.sections ?? []).forEach((section, sectionIndex) => {
        const start = order;
        if (section.question_type?.type === 'matching') {
            section.questions.forEach((question, i) => {
                const number = start + 1 + i;
                if (present.has(number)) out.set(number, { number, question, section, sectionIndex });
            });
        }
        order = start + section.questions.reduce((sum, q) => sum + Number(q.is_correct_count ?? 1), 0);
    });
    return out;
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
