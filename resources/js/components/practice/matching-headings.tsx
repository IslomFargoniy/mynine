import { Question, Section } from '@/types';
import { buildRange } from '@/utils/rangeHelpers';
import { headingPick, usePickedHeading, writeHeadingDrag } from '@/utils/passageSlots';

interface MatchingHeadingsProps {
    section: Section;
    attemptId: number;
    order: number;
    answers: Record<number, string>; // questionId -> answerText
    onAnswerChange: (questionId: number, value: string) => void;
    flaggedIds?: Set<number>;
    toggleFlag?: (questionId: number) => void;
    /** Questions answered by dragging a heading into the passage (`{14}` boxes): no select for them. */
    passageQuestionIds?: Set<number>;
}

/**
 * Matching (headings / information A–H): IELTS-style select per question. Headings with their own text are
 * listed above; a bare letter range is not (the letters are in the select). The answer is the option text, as before.
 */
export default function MatchingHeadings({
    section,
    order,
    answers,
    onAnswerChange,
    flaggedIds,
    toggleFlag,
    passageQuestionIds,
}: MatchingHeadingsProps) {
    const picked = usePickedHeading();
    const textOptions: string[] =
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        section.options && section.options.length > 0 ? section.options.map((o: any) => o.textarea || o.option_text || String(o)) : [];
    const hasTexts = textOptions.length > 0;
    const headingOptions = hasTexts ? textOptions : buildRange(section.from_option, section.to_option);
    const inPassage = section.questions.filter((q: Question) => passageQuestionIds?.has(q.id));
    const dragMode = inPassage.length > 0;

    // A heading used in a passage box leaves the list (letters A–H may repeat, so they stay).
    const available = hasTexts
        ? (() => {
              const left = [...headingOptions];
              inPassage.forEach((q: Question) => {
                  const i = left.indexOf(answers[q.id] || '');
                  if (i >= 0) left.splice(i, 1);
              });
              return left;
          })()
        : headingOptions;

    return (
        <div className="my-4 space-y-6">
            {dragMode && (
                <div className="rounded-lg border-2 border-gray-300 bg-gray-50 p-4 shadow-xs dark:border-gray-700 dark:bg-gray-800/80">
                    <h4 className="mb-2.5 text-sm font-bold tracking-wider text-gray-800 uppercase dark:text-gray-200">
                        {hasTexts ? 'List of Headings' : 'Options'}
                    </h4>
                    <div className={hasTexts ? 'flex flex-col items-start gap-2' : 'flex flex-wrap gap-2'}>
                        {available.map((heading, idx) => (
                            <div
                                key={`${heading}-${idx}`}
                                draggable
                                data-testid="heading-chip"
                                onDragStart={(e) => writeHeadingDrag(e, { label: heading })}
                                onClick={() => headingPick.set(picked === heading ? null : heading)}
                                className={`max-w-full cursor-grab border px-3 py-1.5 text-sm leading-snug text-gray-900 shadow-2xs select-none active:cursor-grabbing dark:text-gray-100 ${
                                    picked === heading
                                        ? 'border-blue-600 bg-blue-50 dark:bg-blue-950/40'
                                        : 'border-gray-400 bg-white hover:border-black dark:border-gray-600 dark:bg-gray-900'
                                }`}
                            >
                                {heading}
                            </div>
                        ))}
                    </div>
                </div>
            )}

            {!dragMode && hasTexts && (
                <div className="rounded-lg border-2 border-gray-300 bg-gray-50 p-4 shadow-xs dark:border-gray-700 dark:bg-gray-800/80">
                    <h4 className="mb-2.5 text-sm font-bold tracking-wider text-gray-800 uppercase dark:text-gray-200">List of Headings</h4>
                    <ul className="space-y-1.5">
                        {headingOptions.map((heading, idx) => (
                            <li key={idx} className="text-sm leading-snug text-gray-900 dark:text-gray-100">
                                {heading}
                            </li>
                        ))}
                    </ul>
                </div>
            )}

            <div className="space-y-3">
                {section.questions.map((q: Question, qIdx: number) => {
                    if (passageQuestionIds?.has(q.id)) return null;
                    const currentAnswer = answers[q.id] || '';
                    const qNumber = order + qIdx;
                    const isFlagged = flaggedIds?.has(q.id) ?? false;
                    // An answer saved from an older list still shows.
                    const options = currentAnswer && !headingOptions.includes(currentAnswer) ? [...headingOptions, currentAnswer] : headingOptions;

                    return (
                        <div
                            id={`question-${q.id}`}
                            key={q.id}
                            className="flex flex-col justify-between gap-3 rounded-md border border-gray-200 bg-white px-3.5 py-2.5 shadow-2xs sm:flex-row sm:items-center dark:border-gray-700/80 dark:bg-gray-900"
                        >
                            <div className="flex min-w-0 flex-1 items-start gap-2.5 sm:items-center">
                                <span
                                    onClick={() => toggleFlag?.(q.id)}
                                    className={`flex h-6 min-w-[24px] items-center justify-center border px-1.5 ${
                                        isFlagged
                                            ? 'border-orange-500 bg-orange-50 font-bold text-orange-600'
                                            : 'border-black bg-white font-bold text-black dark:border-white dark:bg-gray-800 dark:text-white'
                                    } rounded-[2px] text-xs ${toggleFlag ? 'cursor-pointer' : ''} relative shrink-0 shadow-2xs select-none`}
                                >
                                    {qNumber}
                                    {isFlagged && (
                                        <span className="absolute -top-1.5 -right-1.5 flex h-3 w-3 items-center justify-center rounded-full bg-orange-500 text-[7px] text-white">
                                            ★
                                        </span>
                                    )}
                                </span>
                                <span className="text-sm leading-snug font-semibold text-gray-800 dark:text-gray-200">
                                    {q.textarea || `Section / Paragraph ${qNumber}`}
                                </span>
                            </div>

                            <select
                                value={currentAnswer}
                                onChange={(e) => onAnswerChange(q.id, e.target.value)}
                                aria-label={`Answer ${qNumber}`}
                                className={`h-[34px] cursor-pointer rounded-none border border-black bg-white px-2 text-sm font-semibold text-black outline-none focus:border-[#2563eb] focus:ring-1 focus:ring-[#2563eb] dark:border-white dark:bg-gray-900 dark:text-white ${
                                    hasTexts ? 'w-full sm:w-[380px]' : 'w-24'
                                }`}
                            >
                                <option value="">–</option>
                                {options.map((heading, idx) => (
                                    <option key={idx} value={heading}>
                                        {heading}
                                    </option>
                                ))}
                            </select>
                        </div>
                    );
                })}
            </div>
        </div>
    );
}
