import React, { useRef, useEffect, useState } from 'react';
import { Attempt, Part } from '@/types';
import { sanitizeAndInsertWbr } from '@/utils/sanitizeAndInsertWbr';
import { Highlighter, FileText, X, Trash2, StickyNote, ChevronDown, ChevronUp } from 'lucide-react';

interface PartUpdateProps {
    part: Part;
    attempt: Attempt;
}

export default function PracticePart({ attempt, part }: PartUpdateProps) {
    const textRef = useRef<HTMLDivElement>(null);
    const toolbarRef = useRef<HTMLDivElement>(null);

    const [isAlreadyHighlighted, setIsAlreadyHighlighted] = useState(false);
    const [selectionRange, setSelectionRange] = useState<Range | null>(null);
    const [toolbarPos, setToolbarPos] = useState<{ top: number; left: number } | null>(null);
    const [noteModalOpen, setNoteModalOpen] = useState(false);
    const [selectedText, setSelectedText] = useState('');
    const [noteContent, setNoteContent] = useState('');
    const [isNotesOpen, setIsNotesOpen] = useState(false);
    
    const notesStorageKey = `notes-part-${part.id}-${attempt.id}`;
    const highlightStorageKey = `highlight-part-${part.id}-${attempt.id}`;

    const [savedNotes, setSavedNotes] = useState<Array<{ id: string; text: string; note: string; createdAt: string }>>(() => {
        try {
            const raw = localStorage.getItem(notesStorageKey);
            return raw ? JSON.parse(raw) : [];
        } catch {
            return [];
        }
    });

    useEffect(() => {
        const handleToggleNotes = () => setIsNotesOpen(prev => !prev);
        window.addEventListener('toggle-candidate-notes', handleToggleNotes);
        return () => window.removeEventListener('toggle-candidate-notes', handleToggleNotes);
    }, []);

    useEffect(() => {
        if (!textRef.current) return;

        const saved = localStorage.getItem(highlightStorageKey);
        if (saved) {
            textRef.current.innerHTML = sanitizeAndInsertWbr(saved, 40);
        } else {
            textRef.current.innerHTML = sanitizeAndInsertWbr(part.textarea || '', 40);
        }
    }, [part.textarea, highlightStorageKey]);

    const handleMouseUp = () => {
        const selection = window.getSelection();
        if (!selection || selection.rangeCount === 0) {
            setToolbarPos(null);
            setSelectionRange(null);
            setIsAlreadyHighlighted(false);
            return;
        }

        const range = selection.getRangeAt(0);
        if (!textRef.current?.contains(range.commonAncestorContainer)) {
            setToolbarPos(null);
            setSelectionRange(null);
            setIsAlreadyHighlighted(false);
            return;
        }

        if (selection.isCollapsed) {
            setToolbarPos(null);
            setSelectionRange(null);
            setIsAlreadyHighlighted(false);
            return;
        }

        let hasHighlight = false;
        let containerNode: Node | null = range.commonAncestorContainer;
        if (containerNode.nodeType === Node.TEXT_NODE) {
            containerNode = containerNode.parentElement;
        }
        if (containerNode && (containerNode as HTMLElement).closest('mark.highlight')) {
            hasHighlight = true;
        } else if (textRef.current) {
            const marks = textRef.current.querySelectorAll('mark.highlight');
            marks.forEach((mark) => {
                const markRange = document.createRange();
                markRange.selectNodeContents(mark);
                if (
                    range.compareBoundaryPoints(Range.END_TO_START, markRange) < 0 &&
                    range.compareBoundaryPoints(Range.START_TO_END, markRange) > 0
                ) {
                    hasHighlight = true;
                }
            });
        }

        setIsAlreadyHighlighted(hasHighlight);

        const rect = range.getBoundingClientRect();
        const containerRect = textRef.current.getBoundingClientRect();

        setToolbarPos({
            top: rect.top - containerRect.top + textRef.current.scrollTop - 52,
            left: Math.max(10, rect.left - containerRect.left + textRef.current.scrollLeft + (rect.width / 2) - 45),
        });
        setSelectionRange(range);
    };

    const wrapRangeWithMark = (range: Range, className = 'highlight', extraAttrs: Record<string, string> = {}) => {
        const walker = document.createTreeWalker(
            range.commonAncestorContainer,
            NodeFilter.SHOW_TEXT,
            {
                acceptNode: (node) => {
                    if (!node.nodeValue?.trim()) return NodeFilter.FILTER_REJECT;
                    if (node.parentElement?.classList.contains('highlight'))
                        return NodeFilter.FILTER_REJECT;

                    const nodeRange = document.createRange();
                    nodeRange.selectNodeContents(node);

                    if (
                        range.compareBoundaryPoints(Range.END_TO_START, nodeRange) >= 0 ||
                        range.compareBoundaryPoints(Range.START_TO_END, nodeRange) <= 0
                    )
                        return NodeFilter.FILTER_REJECT;

                    return NodeFilter.FILTER_ACCEPT;
                }
            }
        );

        const nodes: Text[] = [];
        while (walker.nextNode()) nodes.push(walker.currentNode as Text);

        nodes.forEach((node) => {
            const nodeRange = document.createRange();
            nodeRange.selectNodeContents(node);

            const start =
                range.compareBoundaryPoints(Range.START_TO_END, nodeRange) > 0
                    ? 0
                    : range.startOffset;
            const end =
                range.compareBoundaryPoints(Range.END_TO_START, nodeRange) < 0
                    ? node.length
                    : range.endOffset;

            const textToHighlight = node.splitText(start);
            textToHighlight.splitText(end - start);

            const mark = document.createElement('mark');
            mark.className = className;
            Object.entries(extraAttrs).forEach(([k, v]) => mark.setAttribute(k, v));
            mark.textContent = textToHighlight.nodeValue;

            textToHighlight.parentNode?.replaceChild(mark, textToHighlight);
        });
    };

    const handleHighlight = () => {
        if (!selectionRange) return;
        wrapRangeWithMark(selectionRange);
        window.getSelection()?.removeAllRanges();
        setToolbarPos(null);
        setSelectionRange(null);
        saveHighlights();
    };

    const handleClearHighlight = () => {
        if (!selectionRange || !textRef.current) return;
        const marks = Array.from(textRef.current.querySelectorAll('mark.highlight'));
        marks.forEach((mark) => {
            const markRange = document.createRange();
            markRange.selectNodeContents(mark);

            if (
                selectionRange.compareBoundaryPoints(Range.END_TO_START, markRange) < 0 &&
                selectionRange.compareBoundaryPoints(Range.START_TO_END, markRange) > 0
            ) {
                const parent = mark.parentNode;
                if (parent) {
                    while (mark.firstChild) parent.insertBefore(mark.firstChild, mark);
                    parent.removeChild(mark);
                }
            }
        });

        window.getSelection()?.removeAllRanges();
        setToolbarPos(null);
        setSelectionRange(null);
        setIsAlreadyHighlighted(false);
        saveHighlights();
    };

    const handleNoteClick = () => {
        if (!selectionRange) return;
        const text = selectionRange.toString().trim();
        setSelectedText(text);
        setNoteContent('');
        setNoteModalOpen(true);
        setToolbarPos(null);
    };

    const saveNote = () => {
        if (!selectedText) return;
        const newNote = {
            id: Date.now().toString(),
            text: selectedText,
            note: noteContent.trim(),
            createdAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        };
        const updated = [...savedNotes, newNote];
        setSavedNotes(updated);
        localStorage.setItem(notesStorageKey, JSON.stringify(updated));

        if (selectionRange) {
            wrapRangeWithMark(selectionRange, 'highlight note-highlight', { 'data-note-id': newNote.id });
            saveHighlights();
        }

        setNoteModalOpen(false);
        setSelectionRange(null);
        setIsNotesOpen(true); // Open notes drawer automatically
    };

    const deleteNote = (noteId: string) => {
        const updated = savedNotes.filter(n => n.id !== noteId);
        setSavedNotes(updated);
        localStorage.setItem(notesStorageKey, JSON.stringify(updated));
    };

    const saveHighlights = () => {
        if (!textRef.current) return;
        localStorage.setItem(highlightStorageKey, textRef.current.innerHTML);
    };

    return (
        <div key={part.id} className="relative">
            {/* Header & Notes Drawer Button */}
            <div className="flex justify-between items-center mb-3">
                <h2 className="font-bold text-lg text-gray-900">{part.name}</h2>
                {savedNotes.length > 0 && (
                    <button
                        onClick={() => setIsNotesOpen(!isNotesOpen)}
                        className="flex items-center gap-1.5 px-3 py-1 bg-amber-50 hover:bg-amber-100 text-amber-900 border border-amber-300 rounded text-xs font-semibold shadow-2xs transition-colors"
                    >
                        <StickyNote className="w-3.5 h-3.5 text-amber-600" />
                        <span>Candidate Notes ({savedNotes.length})</span>
                        {isNotesOpen ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
                    </button>
                )}
            </div>

            {/* Right-Side Fixed Slide-Over Candidate Notes Drawer */}
            {isNotesOpen && (
                <div className="fixed top-10 right-0 bottom-10 w-80 sm:w-96 bg-white border-l border-gray-300 shadow-2xl z-50 flex flex-col animate-in slide-in-from-right duration-200">
                    <div className="bg-[#0f172a] text-white px-4 py-3 flex justify-between items-center border-b border-gray-800">
                        <div className="flex items-center gap-2 font-bold text-sm">
                            <StickyNote className="w-4 h-4 text-amber-400" />
                            <span>Candidate Notes ({savedNotes.length})</span>
                        </div>
                        <button
                            onClick={() => setIsNotesOpen(false)}
                            className="text-gray-400 hover:text-white p-1 rounded hover:bg-slate-800 transition-colors"
                        >
                            <X className="w-4 h-4" />
                        </button>
                    </div>

                    <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-slate-50">
                        {savedNotes.length === 0 ? (
                            <div className="text-center py-10 text-gray-400 text-xs">
                                <FileText className="w-8 h-8 mx-auto mb-2 opacity-50" />
                                <p className="font-semibold text-gray-600">No candidate notes yet</p>
                                <p className="mt-1">Select any text in the reading passage and click <strong className="text-gray-700 font-bold">"Note"</strong> to save your notes.</p>
                            </div>
                        ) : (
                            savedNotes.map((n) => (
                                <div key={n.id} className="bg-white border border-gray-200 rounded-md p-3 shadow-2xs space-y-2">
                                    <div className="text-xs italic text-gray-800 bg-amber-50 p-2 rounded border-l-3 border-amber-400">
                                        "{n.text}"
                                    </div>
                                    <div className="text-xs text-gray-700 font-medium">
                                        {n.note || <span className="text-gray-400 italic">No notes written</span>}
                                    </div>
                                    <div className="flex justify-between items-center pt-2 border-t border-gray-100 text-[10px] text-gray-400">
                                        <span>{n.createdAt}</span>
                                        <button
                                            onClick={() => deleteNote(n.id)}
                                            className="text-red-500 hover:text-red-700 flex items-center gap-1 font-semibold hover:bg-red-50 px-1.5 py-0.5 rounded transition-colors"
                                        >
                                            <Trash2 className="w-3 h-3" />
                                            Delete
                                        </button>
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </div>
            )}

            {/* Passage Text Container */}
            <div
                ref={textRef}
                className="prose dark:prose-invert text-[14px] leading-[1.7] break-words max-w-full ielts-passage font-sans text-black"
                onMouseUp={handleMouseUp}
            />

            {/* Official Inspera Floating Toolbar (White card with Clear/Note and Highlight) */}
            {toolbarPos && (
                <div
                    ref={toolbarRef}
                    className="flex items-center bg-white border border-gray-300 shadow-xl rounded px-2 py-1 gap-1.5 text-gray-700 select-none animate-in fade-in zoom-in-95 duration-100 z-50"
                    style={{
                        position: 'absolute',
                        top: Math.max(10, toolbarPos.top),
                        left: Math.max(10, toolbarPos.left),
                    }}
                >
                    {isAlreadyHighlighted ? (
                        <button
                            onClick={handleClearHighlight}
                            className="flex flex-col items-center justify-center p-1 hover:bg-red-50 rounded text-red-600 hover:text-red-700 transition-colors min-w-[34px]"
                            title="Clear Highlight"
                        >
                            <Trash2 className="w-3.5 h-3.5" />
                            <span className="text-[9px] font-semibold mt-0.5 uppercase tracking-tighter">Clear</span>
                        </button>
                    ) : (
                        <button
                            onClick={handleNoteClick}
                            className="flex flex-col items-center justify-center p-1 hover:bg-gray-100 rounded text-gray-700 hover:text-black transition-colors min-w-[34px]"
                            title="Add Note"
                        >
                            <FileText className="w-3.5 h-3.5" />
                            <span className="text-[9px] font-semibold mt-0.5 uppercase tracking-tighter">Note</span>
                        </button>
                    )}
                    <div className="w-[1px] h-6 bg-gray-200"></div>
                    <button
                        onClick={handleHighlight}
                        className="flex flex-col items-center justify-center p-1 hover:bg-gray-100 rounded text-gray-700 hover:text-black transition-colors min-w-[42px]"
                        title="Highlight Text"
                    >
                        <Highlighter className="w-3.5 h-3.5" />
                        <span className="text-[9px] font-semibold mt-0.5 uppercase tracking-tighter">Highlight</span>
                    </button>
                </div>
            )}

            {/* Note Dialog Modal */}
            {noteModalOpen && (
                <div className="fixed inset-0 z-50 bg-black/40 flex items-center justify-center p-4">
                    <div className="bg-white rounded-md shadow-2xl border border-gray-300 w-full max-w-md p-4 animate-in fade-in zoom-in-95 duration-150">
                        <div className="flex justify-between items-center border-b border-gray-200 pb-2 mb-3">
                            <h3 className="font-bold text-sm text-gray-900 flex items-center gap-1.5">
                                <FileText className="w-4 h-4 text-blue-600" />
                                Add Candidate Note
                            </h3>
                            <button
                                onClick={() => setNoteModalOpen(false)}
                                className="text-gray-400 hover:text-black"
                            >
                                <X className="w-4 h-4" />
                            </button>
                        </div>
                        <div className="bg-gray-50 border border-gray-200 p-2 rounded text-xs text-gray-700 italic mb-3 max-h-24 overflow-y-auto">
                            "{selectedText}"
                        </div>
                        <textarea
                            value={noteContent}
                            onChange={(e) => setNoteContent(e.target.value)}
                            placeholder="Type your notes here..."
                            rows={3}
                            autoFocus
                            spellCheck={false}
                            autoCorrect="off"
                            autoCapitalize="off"
                            data-gramm="false"
                            className="w-full text-xs p-2 border border-gray-300 rounded focus:ring-1 focus:ring-blue-600 focus:outline-none mb-3"
                        />
                        <div className="flex justify-end gap-2">
                            <button
                                onClick={() => setNoteModalOpen(false)}
                                className="px-3 py-1 text-xs border border-gray-300 rounded hover:bg-gray-100"
                            >
                                Cancel
                            </button>
                            <button
                                onClick={saveNote}
                                className="px-3 py-1 text-xs bg-blue-600 text-white font-semibold rounded hover:bg-blue-700"
                            >
                                Save Note
                            </button>
                        </div>
                    </div>
                </div>
            )}

            <style>{`
                mark.highlight {
                  background-color: rgba(253, 224, 71, 0.5);
                  color: inherit;
                  border-radius: 2px;
                  padding: 1px 0;
                  transition: background-color 0.2s;
                }
                mark.note-highlight {
                  background-color: rgba(147, 197, 253, 0.5);
                  border-bottom: 2px solid #2563eb;
                }
            `}</style>
        </div>
    );
}
