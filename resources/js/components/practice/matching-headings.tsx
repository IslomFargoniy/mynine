import React, { useState } from 'react';
import { Section, Question } from '@/types';
import { buildRange } from '@/utils/rangeHelpers';
import { GripVertical, X } from 'lucide-react';

interface MatchingHeadingsProps {
    section: Section;
    attemptId: number;
    order: number;
    answers: Record<number, string>; // questionId -> answerText
    onAnswerChange: (questionId: number, value: string) => void;
    flaggedIds?: Set<number>;
    toggleFlag?: (questionId: number) => void;
}

export default function MatchingHeadings({
    section,
    order,
    answers,
    onAnswerChange,
    flaggedIds,
    toggleFlag
}: MatchingHeadingsProps) {
    const [selectedHeading, setSelectedHeading] = useState<string | null>(null);
    const [draggedHeading, setDraggedHeading] = useState<string | null>(null);

    // Build the list of available headings/options
    const headingOptions: string[] = section.options && section.options.length > 0
        ? section.options.map((o: any) => o.textarea || o.option_text || String(o))
        : buildRange(section.from_option, section.to_option);

    const handleDragStart = (e: React.DragEvent, heading: string) => {
        e.dataTransfer.setData('text/plain', heading);
        setDraggedHeading(heading);
    };

    const handleDrop = (e: React.DragEvent, questionId: number) => {
        e.preventDefault();
        const heading = e.dataTransfer.getData('text/plain') || draggedHeading;
        if (heading) {
            onAnswerChange(questionId, heading);
            setDraggedHeading(null);
            setSelectedHeading(null);
        }
    };

    const handleDragOver = (e: React.DragEvent) => {
        e.preventDefault();
    };

    const handleSlotClick = (questionId: number) => {
        if (selectedHeading) {
            onAnswerChange(questionId, selectedHeading);
            setSelectedHeading(null);
        }
    };

    const handleClearSlot = (questionId: number) => {
        onAnswerChange(questionId, '');
    };

    return (
        <div className="my-4 space-y-6">
            {/* List of Headings Container */}
            <div className="p-4 bg-gray-50 dark:bg-gray-800/80 border-2 border-gray-300 dark:border-gray-700 rounded-lg shadow-xs">
                <h4 className="text-sm font-bold uppercase tracking-wider text-gray-800 dark:text-gray-200 mb-3 flex items-center justify-between">
                    <span>List of Headings</span>
                    <span className="text-xs text-gray-500 font-normal lowercase">(drag heading or click to place)</span>
                </h4>

                <div className="flex flex-wrap gap-2.5">
                    {headingOptions.map((heading, idx) => {
                        const isUsed = Object.values(answers).includes(heading);
                        const isSelected = selectedHeading === heading;

                        return (
                            <div
                                key={idx}
                                draggable={!isUsed}
                                onDragStart={(e) => handleDragStart(e, heading)}
                                onClick={() => {
                                    if (!isUsed) {
                                        setSelectedHeading(isSelected ? null : heading);
                                    }
                                }}
                                className={`flex items-center gap-2 px-3.5 py-2 rounded-md font-medium text-sm border shadow-xs transition-all ${
                                    isUsed
                                        ? 'bg-gray-200 dark:bg-gray-700/50 text-gray-400 dark:text-gray-500 border-gray-300 dark:border-gray-700 line-through cursor-not-allowed opacity-60'
                                        : isSelected
                                            ? 'bg-blue-600 text-white border-blue-700 ring-2 ring-blue-400 cursor-pointer shadow-md'
                                            : 'bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 border-gray-300 dark:border-gray-600 hover:border-black dark:hover:border-white hover:shadow-sm cursor-grab active:cursor-grabbing'
                                }`}
                            >
                                {!isUsed && <GripVertical className="w-4 h-4 text-gray-400" />}
                                <span>{heading}</span>
                            </div>
                        );
                    })}
                </div>
            </div>

            {/* Questions Drop Slots */}
            <div className="space-y-4">
                {section.questions.map((q: Question, qIdx: number) => {
                    const currentAnswer = answers[q.id] || '';
                    const qNumber = order + qIdx;

                    const isFlagged = flaggedIds?.has(q.id) ?? false;

                    return (
                        <div
                            id={`question-${q.id}`}
                            key={q.id}
                            className="p-3.5 border border-gray-200 dark:border-gray-700/80 bg-white dark:bg-gray-900 rounded-md shadow-2xs flex flex-col sm:flex-row sm:items-center justify-between gap-3"
                        >
                            <div className="flex items-start sm:items-center gap-2.5 flex-1 min-w-0">
                                <span
                                    onClick={() => toggleFlag?.(q.id)}
                                    className={`flex items-center justify-center min-w-[24px] h-6 px-1.5 border ${
                                        isFlagged
                                            ? 'border-orange-500 bg-orange-50 text-orange-600 font-bold'
                                            : 'border-[#2563eb] bg-white dark:bg-gray-800 text-[#2563eb] font-bold'
                                    } text-xs rounded-[2px] ${toggleFlag ? 'cursor-pointer' : ''} shadow-2xs select-none relative shrink-0`}
                                >
                                    {qNumber}
                                    {isFlagged && (
                                        <span className="absolute -top-1.5 -right-1.5 w-3 h-3 bg-orange-500 rounded-full flex items-center justify-center text-[7px] text-white">★</span>
                                    )}
                                </span>
                                <span className="font-semibold text-sm text-gray-800 dark:text-gray-200 leading-snug">
                                    {q.textarea || `Section / Paragraph ${qNumber}`}
                                </span>
                            </div>

                            {/* Drop Slot */}
                            <div
                                onDragOver={handleDragOver}
                                onDrop={(e) => handleDrop(e, q.id)}
                                onClick={() => handleSlotClick(q.id)}
                                className={`min-h-[44px] sm:w-[320px] md:w-[380px] p-2 border-2 border-dashed rounded-md flex items-center justify-between transition-colors ${
                                    currentAnswer
                                        ? 'border-blue-500 bg-blue-50/50 dark:bg-blue-950/20'
                                        : selectedHeading
                                            ? 'border-blue-400 bg-blue-50/20 animate-pulse cursor-pointer'
                                            : 'border-gray-300 dark:border-gray-600 bg-gray-50/50 dark:bg-gray-800/40'
                                }`}
                            >
                                {currentAnswer ? (
                                    <div className="flex items-center justify-between w-full font-semibold text-sm text-blue-900 dark:text-blue-200 px-2 py-1 bg-white dark:bg-gray-800 rounded border border-blue-300 dark:border-blue-700 shadow-2xs">
                                        <span className="truncate max-w-[280px]">{currentAnswer}</span>
                                        <button
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                handleClearSlot(q.id);
                                            }}
                                            className="ml-2 text-red-500 hover:text-red-700 p-0.5 rounded transition-colors"
                                            title="Clear answer"
                                        >
                                            <X className="w-4 h-4" />
                                        </button>
                                    </div>
                                ) : (
                                    <span className="text-xs font-medium text-gray-400 dark:text-gray-500 italic px-2">
                                        {selectedHeading ? 'Click here to place heading' : 'Drop heading here'}
                                    </span>
                                )}
                            </div>
                        </div>
                    );
                })}
            </div>
        </div>
    );
}
