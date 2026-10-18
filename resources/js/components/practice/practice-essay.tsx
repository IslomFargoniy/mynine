import React, { } from 'react';
import { Attempt, Part } from '@/types';
import PracticeQuestion from '@/components/practice/practice-question';

interface SectionUpdateProps {
    order: number;
    part: Part;
    attempt: Attempt;
    setSelectedPart: React.Dispatch<React.SetStateAction<Part | null>>;
    isFlagged: boolean;
    toggleFlag: (id: number) => void;
}

export default function PracticeEssay({
                                           order,
                                           part,
                                           attempt,
                                           setSelectedPart,
                                           isFlagged,
                                           toggleFlag
                                       }: SectionUpdateProps) {

    let currentOrder = order ?? 0;
    return (
        <div>
            {/* Active Section */}
            {part.sections.map(
                (section) =>
                    (
                        <div key={section.id} className="p-2">
                            {section.questions.map((question, qIndex) => {
                                const increment = question.is_correct_count
                                    ? Number(question.is_correct_count)
                                    : 1;
                                currentOrder += (increment || 1);

                                return (
                                    <PracticeQuestion
                                        setSelectedPart={setSelectedPart}
                                        key={qIndex}
                                        order={currentOrder}
                                        attempt={attempt}
                                        section={section}
                                        question={question}
                                        index={qIndex}
                                        isFlagged={isFlagged}
                                        toggleFlag={() => toggleFlag(question.id)}
                                    />
                                );
                            })}
                        </div>
                    )
            )}
        </div>
    );
}
