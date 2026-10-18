import React, { useState, useEffect, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { DndContext, DragEndEvent, useDraggable, useDroppable } from '@dnd-kit/core';
import { Attempt, Part, Question, Section } from '@/types';
import parse, { Text } from 'html-react-parser';
import { debounce } from 'lodash';
import { toast } from 'sonner';
import { cleanTinyMce } from '@/utils/util';
import PracticeQuestion from '@/components/practice/practice-question';
import MatchingHeadings from '@/components/practice/matching-headings';
import { syncQueue } from '@/services/sync-queue';

interface DragOption {
    id: string | number;
    label: string;
    order: number;
}

interface SectionUpdateProps {
    order: number;
    section: Section;
    attempt: Attempt;
    partIndex: number;
    sectionIndex: number;
    setSelectedPart: React.Dispatch<React.SetStateAction<Part | null>>;
    flaggedIds: Set<number>;
    toggleFlag: (id: number) => void;
}

export default function PracticeSection({
                                            order,
                                            section,
                                            attempt,
                                            sectionIndex,
                                            setSelectedPart,
                                            flaggedIds,
                                            toggleFlag
                                        }: SectionUpdateProps) {
    const { t } = useTranslation();

    const [selectedAnswers, setSelectedAnswers] = useState<
        Record<number, { optionId: string | number | null; text: string }>
    >({});
    const [availableOptions, setAvailableOptions] = useState<DragOption[]>([]);

    /**
     * Drag-and-drop choices are built on the server (answers + distractors, mixed and
     * sorted, with neutral ids) so the client never learns which labels are correct.
     */
    const allOptions = useMemo<DragOption[]>(
        () => (section.drag_options ?? []).map((o, idx) => ({ id: o.id, label: o.label.trim(), order: idx })),
        [section.drag_options]
    );

    const normalize = (s?: string) => (s ?? '').trim().toLowerCase();

    /** ✅ Initial setup */
    useEffect(() => {
        const avail = [...allOptions];
        const selected: Record<number, { optionId: string | number | null; text: string }> = {};

        (section.questions || []).forEach((slot: Question) => {
            const attemptText = slot?.attempt_answer?.answer_text;
            if (attemptText) {
                const match = allOptions.find(
                    (o) => normalize(o.label) === normalize(attemptText)
                );
                if (match) {
                    selected[slot.id] = { optionId: match.id, text: match.label };
                    const idx = avail.findIndex((a) => a.id === match.id);
                    if (idx >= 0) avail.splice(idx, 1);
                } else {
                    selected[slot.id] = { optionId: null, text: attemptText };
                }
            }
        });

        setAvailableOptions(avail);
        setSelectedAnswers(selected);
    }, [allOptions, section.questions]);

    /** ✅ Debounced save (works even for long deletes) */
    const debouncedSave = useMemo(
        () =>
            debounce(async (qId: number, value: string) => {
                try {
                    const res = await syncQueue.saveAnswer({
                        attemptId: attempt.id,
                        partId: section.part_id,
                        questionId: qId,
                        answerText: value.trim() === '' ? null : value.trim(),
                    });

                    if (res.error && !res.offline) {
                        throw new Error(res.error);
                    }

                    setSelectedPart((prev) => {
                        if (!prev) return null;
                        const updatedSections = prev.sections.map((s: Section, idx) =>
                            idx !== sectionIndex
                                ? s
                                : {
                                    ...s,
                                    questions: s.questions.map((q: Question) =>
                                        q.id === qId
                                            ? {
                                                ...q,
                                                attempt_answer:
                                                    value.trim() === ''
                                                        ? undefined
                                                        : ({
                                                            id: Date.now(),
                                                            question_id: qId,
                                                            answer_text: value.trim()
                                                        } as unknown as Question['attempt_answer'])
                                            }
                                            : q
                                    )
                                }
                        );
                        return { ...prev, sections: updatedSections };
                    });
                } catch (error) {
                    const message =
                        error instanceof Error
                            ? error.message
                            : typeof error === 'string'
                                ? error
                                : t('error_occurred');

                    toast.error(message);
                }
            }, 600),
        [attempt.id, section.part_id, sectionIndex, setSelectedPart, t]
    );

    const handleInputChange = (slotId: number, text: string) => {
        setSelectedAnswers((prev) => ({
            ...prev,
            [slotId]: { optionId: prev[slotId]?.optionId ?? null, text }
        }));
        debouncedSave(slotId, text);
    };

    const handleRemove = (slotId: number) => {
        setSelectedAnswers((prev) => {
            const copy = { ...prev };
            delete copy[slotId];
            return copy;
        });
        debouncedSave(slotId, '');
    };

    const handleDragEnd = (event: DragEndEvent) => {
        const { active, over } = event;
        if (!over || !active) return;
        const overId = String(over.id);
        if (!overId.startsWith('drop-')) return;
        const slotId = Number(overId.replace('drop-', ''));

        const activeId = String(active.id);
        if (!activeId.startsWith('drag-')) return;
        const draggedId = activeId.replace('drag-', '');
        const draggedOpt = allOptions.find((o) => String(o.id) === draggedId);
        if (!draggedOpt) return;

        setSelectedAnswers((prev) => ({
            ...prev,
            [slotId]: { optionId: draggedOpt.id, text: draggedOpt.label }
        }));

        setAvailableOptions((prev) => prev.filter((o) => o.id !== draggedOpt.id));
        debouncedSave(slotId, draggedOpt.label);
    };

    const DraggableOption = ({ opt }: { opt: DragOption }) => {
        const { setNodeRef, listeners, attributes, transform, isDragging } = useDraggable({
            id: `drag-${opt.id}`
        });
        const style: React.CSSProperties = transform
            ? { transform: `translate3d(${transform.x}px, ${transform.y}px, 0)` }
            : {};
        return (
            <div
                ref={setNodeRef}
                {...listeners}
                {...attributes}
                style={style}
                className={`cursor-grab select-none rounded-md border-[2px] px-3 py-1 text-sm shadow-sm transition-colors duration-200
                border-blue-500 bg-white text-gray-900
                dark:border-blue-400 dark:bg-gray-800 dark:text-gray-100
                hover:bg-blue-50 dark:hover:bg-gray-700
                active:scale-[0.97]
                ${isDragging ? 'opacity-50' : ''}
            `}
            >
                {opt.label}
            </div>
        );
    };

    const DroppablePlaceholder = ({ slotQuestion, number }: { slotQuestion: Question; number: number }) => {
        const nodeId = `drop-${slotQuestion.id}`;
        const { setNodeRef, isOver } = useDroppable({ id: nodeId });
        const assigned = selectedAnswers[slotQuestion.id];
        const displayText = assigned?.text ?? slotQuestion?.attempt_answer?.answer_text ?? '';

        return (
            <span
                ref={setNodeRef}
                className={`inline-flex items-center gap-2 min-w-[120px] rounded-md border border-dashed px-2 py-1 text-sm mx-1 ${
                    isOver ? 'bg-blue-100 dark:bg-blue-900/40 border-blue-400' : 'border-gray-400 dark:border-gray-600'
                }`}
            >
                <span className="text-blue-600 font-semibold">{number}.</span>
                <span className="truncate max-w-[10rem]">{displayText || '_____'}</span>
                {displayText && (
                    <button
                        onClick={() => handleRemove(slotQuestion.id)}
                        type="button"
                        className="text-xs text-red-500 hover:text-red-700"
                    >
                        ❌
                    </button>
                )}
            </span>
        );
    };

    let qIndex = 0;
    let section_order = order ?? 0;

    const parsedContent =
        ['complete_section', 'drag_and_drop'].includes(section.question_type.type) &&
        parse(cleanTinyMce(section.textarea) ?? '', {
            replace: (domNode) => {
                if (domNode instanceof Text) {
                    const text = domNode.data;
                    const parts = text.split(/(\{.*?\})/g);
                    if (parts.length > 1) {
                        return (
                            <>
                                {parts.map((part) => {
                                    if (part.match(/^\{.*\}$/)) {
                                        const question = section.questions[qIndex++];
                                        section_order++;
                                        if (!question) return null;
                                        const number = section_order;
                                        if (section.question_type.type === 'drag_and_drop')
                                            return (
                                                <DroppablePlaceholder
                                                    key={question.id}
                                                    slotQuestion={question}
                                                    number={number}
                                                />
                                            );
                                        return (
                                            <span key={question.id} className="inline-block whitespace-nowrap align-middle">
                                                <span className="text-blue-600 font-semibold mr-1">{number}.</span>
                                                <input
                                                    type="text"
                                                    className="ielts-gap-input"
                                                    value={
                                                        selectedAnswers[question.id]?.text ??
                                                        question.attempt_answer?.answer_text ??
                                                        ''
                                                    }
                                                    onChange={(e) =>
                                                        handleInputChange(question.id, e.target.value)
                                                    }
                                                    spellCheck={false}
                                                    autoCorrect="off"
                                                    autoCapitalize="off"
                                                    autoComplete="off"
                                                    data-gramm="false"
                                                />
                                            </span>
                                        );
                                    }
                                    return part;
                                })}
                            </>
                        );
                    }
                }
            }
        });

    return (
        <div key={section.id} className="p-1 mb-6">
            <div className="prose dark:prose-invert text-[16px] leading-[1.7] break-words max-w-full prose-p:my-1.5 prose-ul:my-1.5 prose-li:my-0 prose-headings:my-2 prose-table:my-2">
                {section.question_type.type === 'drag_and_drop' ? (
                    <DndContext onDragEnd={handleDragEnd}>
                        {parsedContent}
                        <div className="mt-4 flex flex-wrap gap-2">
                            {availableOptions.map((opt) => (
                                <DraggableOption key={opt.id} opt={opt} />
                            ))}
                        </div>
                    </DndContext>
                ) : section.question_type.type === 'complete_section' ? (
                    <div className="ielts-gap-section">{parsedContent}</div>
                ) : (
                    <div
                        className="text-base/8"
                        dangerouslySetInnerHTML={{ __html: cleanTinyMce(section.textarea) }}
                    />
                )}
            </div>

            {section.question_type.type === 'matching' ? (
                <div className="px-3 pb-4">
                    <MatchingHeadings
                        section={section}
                        attemptId={attempt.id}
                        order={order + 1}
                        answers={Object.fromEntries(
                            (section.questions || []).map((q) => [
                                q.id,
                                selectedAnswers[q.id]?.text ?? q.attempt_answer?.answer_text ?? ''
                            ])
                        )}
                        onAnswerChange={(qId, val) => {
                            handleInputChange(qId, val);
                        }}
                        flaggedIds={flaggedIds}
                        toggleFlag={toggleFlag}
                    />
                </div>
            ) : (section.question_type.type !== 'complete_section' &&
                section.question_type.type !== 'drag_and_drop' &&
                section.question_type.type !== 'essay') && (
                <div className="px-3 pb-4 text-sm text-gray-600 dark:text-gray-400">
                    <div className="space-y-3">
                        {section.questions.map((question, qIndex) => {
                            const increment = question.is_correct_count
                                ? Number(question.is_correct_count)
                                : 1;
                            section_order += increment;

                            return (
                                <PracticeQuestion
                                    key={qIndex}
                                    order={section_order}
                                    attempt={attempt}
                                    section={section}
                                    question={question}
                                    index={qIndex}
                                    setSelectedPart={setSelectedPart}
                                    isFlagged={flaggedIds.has(question.id)}
                                    toggleFlag={() => toggleFlag(question.id)}
                                />
                            );
                        })}
                    </div>
                </div>
            )}
        </div>
    );
}
