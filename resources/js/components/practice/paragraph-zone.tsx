import { useState } from 'react';
import { ParagraphZone, QUESTION_MIME, questionPick, readQuestionDrag, usePickedQuestion, writeQuestionDrag } from '@/utils/passageSlots';

interface Props {
    zone: ParagraphZone;
    /** Statements placed on this paragraph (their answer is its letter). */
    placed: { id: number; number: number; text: string }[];
    onPlace: (questionId: number) => void;
    onRemove: (questionId: number) => void;
}

/**
 * Above a paragraph of the passage ("Which paragraph contains…"): the statements are dragged here from the questions
 * pane (or from another paragraph), or tapped in after picking one; × sends a statement back.
 */
export default function ParagraphZoneBox({ zone, placed, onPlace, onRemove }: Props) {
    const [over, setOver] = useState(false);
    const picked = usePickedQuestion();
    const pickedHere = picked !== null && zone.section.questions.some((q) => q.id === picked);
    const accepts = (e: React.DragEvent) => Array.from(e.dataTransfer.types).includes(QUESTION_MIME);

    return (
        <span
            data-testid={`paragraph-zone-${zone.letter}`}
            onDragOver={(e) => {
                if (!accepts(e)) return;
                e.preventDefault();
                e.dataTransfer.dropEffect = 'move';
                if (!over) setOver(true);
            }}
            onDragLeave={() => setOver(false)}
            onDrop={(e) => {
                setOver(false);
                const id = readQuestionDrag(e);
                if (!id) return;
                e.preventDefault();
                onPlace(id);
            }}
            onClick={() => {
                if (!pickedHere || picked === null) return;
                onPlace(picked);
                questionPick.set(null);
            }}
            className={`my-1 flex min-h-[40px] w-full max-w-full flex-col gap-1.5 border-2 border-dashed p-1.5 select-none ${
                over || pickedHere ? 'cursor-pointer border-blue-600 bg-blue-50 dark:bg-blue-950/40' : placed.length ? 'border-gray-500 bg-white dark:bg-gray-900' : 'border-gray-400 bg-white/60 dark:bg-gray-900/60'
            }`}
        >
            {placed.map((q) => (
                <span
                    key={q.id}
                    draggable
                    onDragStart={(e) => writeQuestionDrag(e, q.id)}
                    className="flex cursor-grab items-start gap-2 border border-black bg-white px-2 py-1 text-[13px] leading-snug text-black dark:border-white dark:bg-gray-800 dark:text-white"
                >
                    <b className="shrink-0">{q.number}</b>
                    <span className="min-w-0 flex-1">{q.text}</span>
                    <button
                        type="button"
                        aria-label={`Remove ${q.number}`}
                        onClick={(e) => {
                            e.stopPropagation();
                            onRemove(q.id);
                        }}
                        className="shrink-0 px-1 text-base leading-none text-gray-500 hover:text-red-600"
                    >
                        ×
                    </button>
                </span>
            ))}
        </span>
    );
}
