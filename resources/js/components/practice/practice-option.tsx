import React from 'react';
import { Attempt, Option, Question, Section } from '@/types';

interface PracticeOptionProps {
    attempt: Attempt;
    section: Section;
    question: Question;
    option: Option;
    index: number;
    selectedOptionIds: number[];
    toggleOption: (optionId: number) => void;
    /** Checkbox ("Choose TWO") instead of a radio. */
    multi: boolean;
    /** The "Choose N" limit is reached: unticked options are dimmed and cannot be ticked. */
    limitReached: boolean;
}

export default function PracticeOption({
    question,
    option,
    index,
    selectedOptionIds,
    toggleOption,
    multi,
    limitReached
}: PracticeOptionProps) {

    const isChecked = selectedOptionIds.includes(option.id);
    const textLower = (option.textarea || '').toLowerCase().trim();
    const isStandardTFN = ['true', 'false', 'not given', 'yes', 'no'].includes(textLower);
    const blocked = multi && limitReached && !isChecked;

    return (
        <label className={`flex items-center gap-3 px-3 py-1.5 transition-colors rounded-[2px] select-none ${
            blocked
                ? 'cursor-default opacity-50 text-gray-900'
                : isChecked
                  ? 'cursor-pointer bg-[#e5e7eb] text-black font-semibold'
                  : 'cursor-pointer bg-transparent text-gray-900 hover:bg-gray-100/70'
        }`}>
            <input
                className="w-4 h-4 cursor-pointer accent-black focus:ring-0 border-gray-400"
                type={multi ? 'checkbox' : 'radio'}
                name={`question-${question.id}${multi ? '[]' : ''}`}
                value={option.id}
                checked={isChecked}
                disabled={blocked}
                onChange={() => toggleOption(option.id)}
            />

            <span className="flex-1 text-sm font-sans uppercase tracking-tight leading-relaxed">
                {!isStandardTFN && (
                    <span className="font-bold mr-1.5">{String.fromCharCode(65 + index)})</span>
                )}
                {option.textarea}
            </span>
        </label>
    );
}
