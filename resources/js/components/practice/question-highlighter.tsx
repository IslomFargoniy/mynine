import { Highlighter, StickyNote, X } from 'lucide-react';
import { type ReactNode, useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react';

/**
 * Highlight / Note in the questions pane (question texts, options, section texts — also around gap inputs).
 *
 * React renders this pane, so the text is never wrapped in <mark> (that would break React's DOM): highlights
 * are kept as character offsets inside the nearest `[data-hl]` element and painted with the CSS Custom Highlight
 * API. Inputs, selects and buttons inside that element take no offsets, so typing an answer, picking an
 * option or dropping a chip never moves a highlight. Notes join the passage's "Candidate Notes" list.
 */

type Mark = { s: number; e: number; note?: string };
type Store = Record<string, Mark[]>;

const SKIP = 'input, textarea, select, option, button, [data-hl-skip]';

/** Text nodes of [root] that count for offsets (not inside form controls / buttons / skipped parts). */
function textNodes(root: Element): Text[] {
    const out: Text[] = [];
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
        acceptNode: (n) => (n.parentElement?.closest(SKIP) ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT),
    });
    for (let n = walker.nextNode(); n; n = walker.nextNode()) out.push(n as Text);
    return out;
}

/** Offset of a DOM point inside [root]'s counted text (a point in a skipped part maps to the next counted text). */
function offsetOf(root: Element, node: Node, offset: number): number | null {
    const point = document.createRange();
    try {
        point.setStart(node, offset);
    } catch {
        return null;
    }
    point.collapse(true);
    let at = 0;
    for (const t of textNodes(root)) {
        if (t === node) return at + offset;
        // comparePoint: -1 = before the point. A text node that ends before the point counts whole.
        if (point.comparePoint(t, t.length) < 0) {
            at += t.length;
            continue;
        }
        return at;
    }
    return at;
}

/** One range per counted text node between offsets [s, e) (gap inputs, number buttons in between stay unpainted). */
function rangesOf(root: Element, s: number, e: number): Range[] {
    const out: Range[] = [];
    let at = 0;
    for (const t of textNodes(root)) {
        const end = at + t.length;
        const from = Math.max(s, at);
        const to = Math.min(e, end);
        if (from < to) {
            const r = document.createRange();
            r.setStart(t, from - at);
            r.setEnd(t, to - at);
            out.push(r);
        }
        if (end >= e) break;
        at = end;
    }
    return out;
}

const supported = () => typeof CSS !== 'undefined' && 'highlights' in CSS && typeof Highlight !== 'undefined';

interface Props {
    attemptId: number;
    partId: number;
    children: ReactNode;
}

export default function QuestionHighlighter({ attemptId, partId, children }: Props) {
    const rootRef = useRef<HTMLDivElement | null>(null);
    const storageKey = `q-highlights-${attemptId}-${partId}`;
    const notesKey = `notes-part-${partId}-${attemptId}`;
    const [store, setStore] = useState<Store>(() => {
        try {
            return JSON.parse(localStorage.getItem(storageKey) ?? '{}') as Store;
        } catch {
            return {};
        }
    });
    const [pick, setPick] = useState<{ key: string; s: number; e: number; text: string; top: number; left: number; marked: boolean } | null>(null);
    const [noteFor, setNoteFor] = useState<{ key: string; s: number; e: number; text: string } | null>(null);
    const [noteText, setNoteText] = useState('');

    const save = useCallback(
        (next: Store) => {
            setStore(next);
            try {
                localStorage.setItem(storageKey, JSON.stringify(next));
            } catch {
                /* storage unavailable */
            }
        },
        [storageKey],
    );

    // Paint the stored ranges (again after every DOM change of the pane: React re-renders, part switches).
    const paint = useCallback(() => {
        const root = rootRef.current;
        if (!root || !supported()) return;
        const plain: Range[] = [];
        const notes: Range[] = [];
        root.querySelectorAll<HTMLElement>('[data-hl]').forEach((el) => {
            for (const m of store[el.dataset.hl ?? ''] ?? []) {
                (m.note ? notes : plain).push(...rangesOf(el, m.s, m.e));
            }
        });
        CSS.highlights.set(`q-hl-${partId}`, new Highlight(...plain));
        CSS.highlights.set(`q-note-${partId}`, new Highlight(...notes));
    }, [store, partId]);

    useLayoutEffect(() => {
        paint();
        const root = rootRef.current;
        if (!root) return;
        let frame = 0;
        const observer = new MutationObserver(() => {
            cancelAnimationFrame(frame);
            frame = requestAnimationFrame(paint);
        });
        observer.observe(root, { subtree: true, childList: true, characterData: true });
        return () => {
            observer.disconnect();
            cancelAnimationFrame(frame);
        };
    }, [paint]);

    useEffect(
        () => () => {
            if (supported()) {
                CSS.highlights.delete(`q-hl-${partId}`);
                CSS.highlights.delete(`q-note-${partId}`);
            }
        },
        [partId],
    );

    // A note deleted from the Candidate Notes list drops its highlight too.
    useEffect(() => {
        const sync = () => {
            let ids: string[] = [];
            try {
                ids = (JSON.parse(localStorage.getItem(notesKey) ?? '[]') as { id: string }[]).map((n) => n.id);
            } catch {
                return;
            }
            setStore((prev) => {
                let changed = false;
                const next: Store = {};
                for (const [k, marks] of Object.entries(prev)) {
                    next[k] = marks.filter((m) => {
                        const keep = !m.note || ids.includes(m.note);
                        if (!keep) changed = true;
                        return keep;
                    });
                }
                if (changed) localStorage.setItem(storageKey, JSON.stringify(next));
                return changed ? next : prev;
            });
        };
        window.addEventListener('practice-notes-changed', sync);
        return () => window.removeEventListener('practice-notes-changed', sync);
    }, [notesKey, storageKey]);

    const onMouseUp = () => {
        const sel = window.getSelection();
        const root = rootRef.current;
        if (!sel || sel.rangeCount === 0 || sel.isCollapsed || !root) {
            setPick(null);
            return;
        }
        const range = sel.getRangeAt(0);
        const startEl = (range.startContainer.nodeType === Node.TEXT_NODE ? range.startContainer.parentElement : (range.startContainer as Element))?.closest<HTMLElement>('[data-hl]');
        // One block at a time (a question text, an option, a section text), as on the desktop.
        if (!startEl || !root.contains(startEl) || !startEl.contains(range.endContainer)) {
            setPick(null);
            return;
        }
        const s = offsetOf(startEl, range.startContainer, range.startOffset);
        const e = offsetOf(startEl, range.endContainer, range.endOffset);
        if (s === null || e === null || e <= s) {
            setPick(null);
            return;
        }
        const key = startEl.dataset.hl ?? '';
        const rect = range.getBoundingClientRect();
        const marked = (store[key] ?? []).some((m) => m.s < e && m.e > s);
        setPick({ key, s, e, text: sel.toString(), top: rect.top - 48, left: Math.max(10, rect.left + rect.width / 2 - 70), marked });
    };

    const clearSelection = () => {
        window.getSelection()?.removeAllRanges();
        setPick(null);
    };

    const add = (mark: Mark, key: string) => save({ ...store, [key]: [...(store[key] ?? []), mark] });

    const highlight = () => {
        if (!pick) return;
        add({ s: pick.s, e: pick.e }, pick.key);
        clearSelection();
    };

    const clear = () => {
        if (!pick) return;
        const removedNotes = (store[pick.key] ?? []).filter((m) => m.note && m.s < pick.e && m.e > pick.s).map((m) => m.note!);
        save({ ...store, [pick.key]: (store[pick.key] ?? []).filter((m) => !(m.s < pick.e && m.e > pick.s)) });
        if (removedNotes.length > 0) {
            try {
                const notes = JSON.parse(localStorage.getItem(notesKey) ?? '[]') as { id: string }[];
                localStorage.setItem(notesKey, JSON.stringify(notes.filter((n) => !removedNotes.includes(n.id))));
                window.dispatchEvent(new Event('practice-notes-changed'));
            } catch {
                /* storage unavailable */
            }
        }
        clearSelection();
    };

    const startNote = () => {
        if (!pick) return;
        setNoteFor({ key: pick.key, s: pick.s, e: pick.e, text: pick.text.trim() });
        setNoteText('');
        clearSelection();
    };

    const saveNote = () => {
        if (!noteFor) return;
        const id = Date.now().toString();
        try {
            const notes = JSON.parse(localStorage.getItem(notesKey) ?? '[]') as unknown[];
            notes.push({
                id,
                text: noteFor.text,
                note: noteText.trim(),
                createdAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
            });
            localStorage.setItem(notesKey, JSON.stringify(notes));
        } catch {
            /* storage unavailable */
        }
        add({ s: noteFor.s, e: noteFor.e, note: id }, noteFor.key);
        setNoteFor(null);
        window.dispatchEvent(new Event('practice-notes-changed'));
    };

    return (
        <div ref={rootRef} onMouseUp={onMouseUp} className="relative">
            <style>{`
                ::highlight(q-hl-${partId}) { background-color: yellowgreen; color: inherit; }
                ::highlight(q-note-${partId}) { background-color: #93c5fd; text-decoration: underline; text-decoration-color: #2563eb; }
            `}</style>
            {children}

            {pick && (
                <div
                    className="fixed z-50 flex items-center overflow-hidden rounded-md border border-gray-300 bg-white text-xs font-semibold text-gray-800 shadow-lg"
                    style={{ top: Math.max(8, pick.top), left: pick.left }}
                    onMouseDown={(e) => e.preventDefault()}
                    onMouseUp={(e) => e.stopPropagation()}
                >
                    <button type="button" onClick={startNote} className="flex items-center gap-1 px-3 py-2 hover:bg-gray-100">
                        <StickyNote className="h-3.5 w-3.5" /> Note
                    </button>
                    {pick.marked ? (
                        <button type="button" onClick={clear} className="flex items-center gap-1 border-l border-gray-200 px-3 py-2 hover:bg-gray-100">
                            <X className="h-3.5 w-3.5" /> Clear
                        </button>
                    ) : (
                        <button type="button" onClick={highlight} className="flex items-center gap-1 border-l border-gray-200 px-3 py-2 hover:bg-gray-100">
                            <Highlighter className="h-3.5 w-3.5" /> Highlight
                        </button>
                    )}
                </div>
            )}

            {noteFor && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onMouseUp={(e) => e.stopPropagation()}>
                    <div className="w-full max-w-md rounded-md bg-white p-4 text-gray-900 shadow-xl">
                        <div className="mb-2 rounded border-l-4 border-amber-400 bg-amber-50 p-2 text-xs italic">"{noteFor.text}"</div>
                        <textarea
                            autoFocus
                            value={noteText}
                            onChange={(e) => setNoteText(e.target.value)}
                            rows={4}
                            className="w-full rounded border border-gray-300 p-2 text-sm"
                            placeholder="Your note"
                        />
                        <div className="mt-3 flex justify-end gap-2">
                            <button type="button" onClick={() => setNoteFor(null)} className="rounded px-3 py-1.5 text-sm hover:bg-gray-100">
                                Cancel
                            </button>
                            <button type="button" onClick={saveNote} className="rounded bg-black px-3 py-1.5 text-sm font-semibold text-white">
                                Save note
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
