import { useState } from 'react';
import { ParagraphZone, QUESTION_MIME, readQuestionDrag, writeQuestionDrag } from '@/utils/passageSlots';

interface Props {
    zone: ParagraphZone;
    /** Questions answered with this paragraph's letter, with their numbers. */
    placed: { id: number; number: number }[];
    onPlace: (questionId: number) => void;
    onRemove: (questionId: number) => void;
}

/**
 * Above a paragraph of the passage ("Which paragraph contains…"): question numbers are dragged here from the
 * questions pane (or from another paragraph); × takes one back off.
 */
export default function ParagraphZoneBox({ zone, placed, onPlace, onRemove }: Props) {
    const [over, setOver] = useState(false);
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
            className={`my-1 inline-flex min-h-[36px] min-w-[200px] max-w-full flex-wrap items-center gap-1.5 border-2 border-dashed px-2 py-1 align-middle select-none ${
                over ? 'border-blue-600 bg-blue-50 dark:bg-blue-950/40' : placed.length ? 'border-gray-500 bg-white dark:bg-gray-900' : 'border-gray-400 bg-white/60 dark:bg-gray-900/60'
            }`}
        >
            {placed.length === 0 && <span className="px-1 text-xs text-gray-400">&nbsp;</span>}
            {placed.map((q) => (
                <span
                    key={q.id}
                    draggable
                    onDragStart={(e) => writeQuestionDrag(e, q.id)}
                    className="inline-flex cursor-grab items-center gap-1 border border-black bg-white px-2 py-0.5 text-[13px] font-bold text-black dark:border-white dark:bg-gray-800 dark:text-white"
                >
                    {q.number}
                    <button
                        type="button"
                        aria-label={`Remove ${q.number}`}
                        onClick={(e) => {
                            e.stopPropagation();
                            onRemove(q.id);
                        }}
                        className="text-sm leading-none font-normal text-gray-500 hover:text-red-600"
                    >
                        ×
                    </button>
                </span>
            ))}
        </span>
    );
}
