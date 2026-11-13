import { useState } from 'react';
import { HEADING_MIME, headingPick, PassageSlot, readHeadingDrag, usePickedHeading, writeHeadingDrag } from '@/utils/passageSlots';

interface Props {
    slot: PassageSlot;
    value: string;
    /** Text shown for the value (the full heading when the answer is its number). */
    display?: string;
    onPlace: (label: string, fromQuestionId?: number) => void;
    onClear: () => void;
}

/**
 * A heading box inside the passage (IELTS computer test): empty it shows the question number; a heading is dropped
 * in from the list (or tapped in after picking it), can be dragged on to another box, and × sends it back.
 */
export default function PassageDropZone({ slot, value, display, onPlace, onClear }: Props) {
    const [over, setOver] = useState(false);
    const picked = usePickedHeading();
    const qId = slot.question.id;

    const accepts = (e: React.DragEvent) => Array.from(e.dataTransfer.types).includes(HEADING_MIME);

    return (
        <span
            id={`question-${qId}`}
            data-testid={`passage-drop-${slot.number}`}
            onDragOver={(e) => {
                if (!accepts(e)) return;
                e.preventDefault();
                e.dataTransfer.dropEffect = 'move';
                if (!over) setOver(true);
            }}
            onDragLeave={() => setOver(false)}
            onDrop={(e) => {
                setOver(false);
                const drag = readHeadingDrag(e);
                if (!drag) return;
                e.preventDefault();
                if (drag.fromQuestionId === qId) return;
                onPlace(drag.label, drag.fromQuestionId);
            }}
            onClick={() => {
                if (!picked) return;
                onPlace(picked);
                headingPick.set(null);
            }}
            className={`my-1 inline-flex min-h-[36px] min-w-[260px] max-w-full items-center gap-2 border-2 px-2.5 py-1 align-middle text-[14px] leading-snug select-none ${
                over || picked
                    ? 'border-dashed border-blue-600 bg-blue-50 dark:bg-blue-950/40'
                    : value
                      ? 'border-solid border-black bg-white dark:border-white dark:bg-gray-900'
                      : 'border-dashed border-gray-500 bg-white dark:bg-gray-900'
            } ${picked ? 'cursor-pointer' : ''}`}
        >
            <span className="shrink-0 font-bold text-black dark:text-white">{slot.number}</span>
            {value ? (
                <>
                    <span
                        draggable
                        onDragStart={(e) => writeHeadingDrag(e, { label: value, fromQuestionId: qId })}
                        className="min-w-0 flex-1 cursor-grab font-semibold break-words text-black dark:text-white"
                    >
                        {display || value}
                    </span>
                    <button
                        type="button"
                        aria-label={`Clear ${slot.number}`}
                        onClick={(e) => {
                            e.stopPropagation();
                            onClear();
                        }}
                        className="shrink-0 px-1 text-base leading-none text-gray-500 hover:text-red-600"
                    >
                        ×
                    </button>
                </>
            ) : (
                <span className="flex-1" />
            )}
        </span>
    );
}
