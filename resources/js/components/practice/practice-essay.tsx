import PracticeQuestion from '@/components/practice/practice-question';
import { Attempt, Part } from '@/types';
import { cleanTinyMce } from '@/utils/util';
import React from 'react';

interface SectionUpdateProps {
    order: number;
    part: Part;
    attempt: Attempt;
    setSelectedPart: React.Dispatch<React.SetStateAction<Part | null>>;
    flaggedIds: Set<number>;
    toggleFlag: (id: number) => void;
}

export default function PracticeEssay({ order, part, attempt, setSelectedPart, flaggedIds, toggleFlag }: SectionUpdateProps) {
    let currentOrder = order ?? 0;
    // The task text is shown in the left pane: do not print it a second time above the essay box.
    // A task given only as a picture counts as text too (as on the desktop).
    const partHasText =
        (part.textarea ?? '').includes('<img') ||
        (part.textarea ?? '')
            .replace(/<[^>]*>/g, '')
            .replace(/&nbsp;/g, ' ')
            .trim() !== '';
    return (
        <div>
            {/* Active Section */}
            {part.sections.map((section) => (
                <div key={section.id} className="p-2">
                    {/* Instructions only when the left pane has nothing (otherwise the task is already there). */}
                    {!partHasText && section.textarea && (
                        <div className="mb-3 text-sm leading-relaxed" dangerouslySetInnerHTML={{ __html: cleanTinyMce(section.textarea) }} />
                    )}
                    {section.questions.map((question, qIndex) => {
                        const increment = question.is_correct_count ? Number(question.is_correct_count) : 1;
                        currentOrder += increment || 1;

                        return (
                            <PracticeQuestion
                                setSelectedPart={setSelectedPart}
                                key={qIndex}
                                order={currentOrder}
                                attempt={attempt}
                                section={section}
                                question={question}
                                index={qIndex}
                                isFlagged={flaggedIds.has(question.id)}
                                toggleFlag={() => toggleFlag(question.id)}
                                hideText={partHasText}
                            />
                        );
                    })}
                </div>
            ))}
        </div>
    );
}
