import React, { useCallback, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Attempt, Part, Question, Section } from '@/types';
import PracticeOption from '@/components/practice/practice-option';

import { debounce } from 'lodash';

import { toast } from 'sonner';

import { syncQueue } from '@/services/sync-queue';

interface SectionUpdateProps {
    order: number;
    attempt: Attempt;
    question: Question;
    section: Section;
    index: number;
    setSelectedPart: React.Dispatch<React.SetStateAction<Part | null>>;
    isFlagged: boolean;
    toggleFlag: () => void;
    /** Writing: the task is already in the left pane, so the question text is not repeated here. */
    hideText?: boolean;
}


/** Same cap as the desktop (and the server): longer answers are cut. */
const MAX_ANSWER_CHARS = 20000;

export default function PracticeQuestion({
                                             order,
                                             attempt,
                                             question,
                                             section,
                                             setSelectedPart,
                                             isFlagged,
                                             toggleFlag,
                                             hideText = false
                                         }: SectionUpdateProps) {
    const { t } = useTranslation();

    const [answer_text, setAnswerText] = useState<string | undefined>(() => {
        const saved = localStorage.getItem(`unsaved-q-${attempt.id}-${question.id}`);
        return saved !== null ? saved : question.attempt_answer?.answer_text;
    });

    const [matchingAnswer, setMatchingAnswer] = useState<string>(() => {
        const saved = localStorage.getItem(`unsaved-q-${attempt.id}-${question.id}`);
        return saved !== null ? saved : (question.attempt_answer?.answer_text ?? '');
    });

    const gapInput = () => (
        <input
            type="text"
            className="ielts-gap-input"
            maxLength={MAX_ANSWER_CHARS}
            value={answer_text ?? (question.attempt_answer?.answer_text || '')}
            onChange={(e) => handleChange(question.id, e.target.value)}
            spellCheck={false}
            autoCorrect="off"
            autoCapitalize="off"
            autoComplete="off"
            data-gramm="false"
        />
    );

    const renderWithBlanks = (text: string) => {
        const parts = (text ?? '').split(/\{\}/g);
        // A gap-fill question without a {} marker still needs its gap: under the text (as on the desktop).
        if (section.question_type.type === 'fill_blank' && parts.length === 1) {
            return (
                <>
                    {text}
                    <div className="mt-2">{gapInput()}</div>
                </>
            );
        }
        return parts.map((part, i) => (
            <React.Fragment key={i}>
                {part}
                {i < parts.length - 1 && gapInput()}
            </React.Fragment>
        ));
    };

    // 🚀 Debounced save using syncQueue
    const debouncedSave = useCallback(
        debounce(async (qId: number, value: string) => {
            try {
                const res = await syncQueue.saveAnswer({
                    attemptId: attempt.id,
                    partId: section.part_id,
                    questionId: qId,
                    answerText: value,
                });

                if (res.error && !res.offline) {
                    throw new Error(res.error);
                }

                // 🟢 Update local UI state
                setSelectedPart((prev: Part | null) => {
                    if (!prev) return null;

                    const updatedSections = prev.sections.map((s) => {
                        if (s.id !== question.section_id) return s;

                        return {
                            ...s,
                            questions: s.questions.map((q) => {
                                if (q.id !== qId) return q;

                                if (value.trim() === '') {
                                    return { ...q, attempt_answer: undefined };
                                }

                                return {
                                    ...q,
                                    attempt_answer: {
                                        ...(q.attempt_answer ?? { id: Date.now(), question_id: qId }),
                                        answer_text: value,
                                        attempt_answer_options: q.attempt_answer?.attempt_answer_options ?? []
                                    } as any
                                };
                            })
                        };
                    });

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
        [attempt.id, section.part_id, question.section_id, setSelectedPart, t]
    );

    const handleChange = (qId: number, value: string) => {
        setAnswerText(value);
        localStorage.setItem(`unsaved-q-${attempt.id}-${qId}`, value);
        debouncedSave(qId, value);
    };

    const [selectedOptionIds, setSelectedOptionIds] = useState<number[]>(() => {
        const saved = localStorage.getItem(`unsaved-opt-${attempt.id}-${question.id}`);
        return saved !== null 
            ? JSON.parse(saved) 
            : (question.attempt_answer?.attempt_answer_options?.map((a) => a.option_id) ?? []);
    });

    // 🚀 Auto-sync from LocalStorage on mount
    React.useEffect(() => {
        const unsavedText = localStorage.getItem(`unsaved-q-${attempt.id}-${question.id}`);
        if (unsavedText !== null && unsavedText !== question.attempt_answer?.answer_text) {
            debouncedSave(question.id, unsavedText);
        }

        const unsavedOpt = localStorage.getItem(`unsaved-opt-${attempt.id}-${question.id}`);
        if (unsavedOpt !== null) {
            const parsed = JSON.parse(unsavedOpt);
            const backendOpts = question.attempt_answer?.attempt_answer_options?.map((a) => a.option_id) ?? [];
            const isSame = parsed.length === backendOpts.length && parsed.every((val: number) => backendOpts.includes(val));
            if (!isSame) {
                fetch(route('attempt-answer.store', {
                    part_id: section.part_id,
                    attempt_id: attempt.id
                }), {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement).content
                    },
                    body: JSON.stringify({
                        question_id: question.id,
                        options: parsed
                    })
                })
                .then(async (response) => {
                    const data = await response.json();
                    if (data.success) {
                        localStorage.removeItem(`unsaved-opt-${attempt.id}-${question.id}`);
                    }
                })
                .catch(() => {});
            }
        }
    }, [attempt.id, question.id]);

    // "Choose TWO" and the like: multi-select when the type says so or the section uses checkboxes (as on the desktop).
    const isMulti = section.question_type.type === 'multiple_response' || section.question_type.input_type === 'checkbox';
    const maxSelections = Number(question.is_correct_count) || Infinity;

    /** Option answers go through the same offline-safe queue as text answers. */
    const toggleOption = (optionId: number) => {
        let updated: number[];
        if (isMulti) {
            if (selectedOptionIds.includes(optionId)) {
                updated = selectedOptionIds.filter((id) => id !== optionId);
            } else {
                if (selectedOptionIds.length >= maxSelections) return;
                updated = [...selectedOptionIds, optionId];
            }
        } else {
            updated = [optionId];
        }

        setSelectedOptionIds(updated);
        localStorage.setItem(`unsaved-opt-${attempt.id}-${question.id}`, JSON.stringify(updated));

        syncQueue
            .saveAnswer({ attemptId: attempt.id, partId: section.part_id, questionId: question.id, options: updated })
            .then((res) => {
                if (res.error && !res.offline) throw new Error(res.error);
                if (!res.offline) localStorage.removeItem(`unsaved-opt-${attempt.id}-${question.id}`);

                setSelectedPart((prev: Part | null) => {
                    if (!prev) return null;
                    return {
                        ...prev,
                        sections: prev.sections.map((s) =>
                            s.id !== question.section_id
                                ? s
                                : {
                                      ...s,
                                      questions: s.questions.map((q) => {
                                          if (q.id !== question.id) return q;
                                          if (updated.length === 0) return { ...q, attempt_answer: undefined };
                                          return {
                                              ...q,
                                              attempt_answer: {
                                                  ...(q.attempt_answer ?? {
                                                      id: Date.now(),
                                                      question_id: q.id,
                                                      answer_text: null,
                                                      attempt_answer_options: [],
                                                  }),
                                                  attempt_answer_options: updated,
                                              } as unknown as Question['attempt_answer'],
                                          };
                                      }),
                                  },
                        ),
                    };
                });
            })
            .catch((error) => toast.error(error instanceof Error ? error.message : t('error_occurred')));
    };

    return (
        <div id={`question-${question.id}`} key={question.id} className={`mb-4 ${section.question_type.type === 'matching' ? 'py-1' : 'py-1.5'}`}>
            <div className="flex items-start gap-2.5">
                <span
                    onClick={toggleFlag}
                    className={`flex items-center justify-center min-w-[24px] h-6 px-1.5 border ${
                        isFlagged ? 'border-orange-500 bg-orange-50 text-orange-600 font-bold' : 'border-black bg-white text-black font-bold dark:border-white dark:bg-gray-800 dark:text-white'
                    } text-xs rounded-[2px] cursor-pointer shadow-2xs select-none relative mt-0.5`}
                    title={t('flag_for_review')}
                >
                    {(() => {
                        const count = Number(question.is_correct_count) || 1;
                        const numOrder = Number(order) || 1;
                        return count > 1
                            ? Array.from({ length: count }, (_, i) => numOrder - count + 1 + i).join('-')
                            : numOrder;
                    })()}
                    {isFlagged && (
                        <span className="absolute -top-1.5 -right-1.5 w-3 h-3 bg-orange-500 rounded-full flex items-center justify-center text-[7px] text-white">★</span>
                    )}
                </span>
                {!hideText && (
                    <div className="flex-1 font-normal text-sm leading-relaxed text-black font-sans">
                        {renderWithBlanks(question.textarea)}
                    </div>
                )}
            </div>



            {section.question_type.type === 'essay' && (() => {
                const wordsCount = matchingAnswer.trim() === '' ? 0 : matchingAnswer.trim().split(/\s+/).length;
                const targetWords = Number(order) === 1 || question.textarea?.toLowerCase().includes('task 1') ? 150 : 250;
                const progressPercent = Math.min(100, Math.round((wordsCount / targetWords) * 100));
                const isTargetMet = wordsCount >= targetWords;

                return (
                    <div className="relative mt-4 space-y-3">
                        {/* Word count only (as on the desktop): characters, paragraphs, reading time and "N words needed" were noise */}
                        <div className="p-3 bg-gray-50 dark:bg-gray-800/80 rounded-lg border border-gray-200 dark:border-gray-700 space-y-2">
                            <div className="flex flex-wrap items-center justify-between gap-2 text-xs">
                                <div className="flex items-center gap-2">
                                    <span className="font-bold text-gray-700 dark:text-gray-300 uppercase tracking-wide">
                                        {t('writing_progress') || 'Insho koʻrsatkichi'}:
                                    </span>
                                    <span className="font-mono font-extrabold text-sm text-gray-900 dark:text-white">
                                        {wordsCount} / {targetWords} {t('words') || 'soʻz'}
                                    </span>
                                </div>
                            </div>

                            {/* Progress bar track */}
                            <div className="w-full bg-gray-200 dark:bg-gray-700 h-2 rounded-full overflow-hidden">
                                <div
                                    className={`h-full transition-all duration-300 rounded-full ${
                                        isTargetMet ? 'bg-emerald-500' : progressPercent > 60 ? 'bg-blue-500' : 'bg-amber-500'
                                    }`}
                                    style={{ width: `${progressPercent}%` }}
                                />
                            </div>

                        </div>

                        <textarea
                            id="answer_text"
                            maxLength={MAX_ANSWER_CHARS}
                            value={matchingAnswer}
                            onChange={(e) => {
                                setMatchingAnswer(e.target.value);
                                localStorage.setItem(`unsaved-q-${attempt.id}-${question.id}`, e.target.value);
                                debouncedSave(question.id, e.target.value);
                            }}
                            spellCheck={false}
                            autoCorrect="off"
                            autoCapitalize="off"
                            autoComplete="off"
                            data-gramm="false"
                            data-gramm_editor="false"
                            data-enable-grammarly="false"
                            className="w-full min-h-[420px] rounded-lg border-2 border-gray-300 focus:border-indigo-600 dark:border-gray-600 dark:focus:border-indigo-400 bg-white dark:bg-gray-800 p-4 text-[16px] leading-[1.65] font-sans shadow-xs focus:outline-none resize-y text-gray-900 dark:text-gray-100 transition-colors"
                            placeholder={t('type_your_essay_here') || 'Inshongizni shu yerga yozing...'}
                        />
                    </div>
                );
            })()}

            {section.question_type.type !== 'fill_blank' &&
                section.question_type.type !== 'matching' &&
                section.question_type.type !== 'essay' &&
                section.question_type.type !== 'complete_section' && (
                    <div className="mt-3 space-y-2">
                        {question.options.map((option, oIndex) => (
                            <PracticeOption
                                attempt={attempt}
                                section={section}
                                question={question}
                                option={option}
                                index={oIndex}
                                selectedOptionIds={selectedOptionIds}
                                toggleOption={toggleOption}
                                multi={isMulti}
                                limitReached={selectedOptionIds.length >= maxSelections}
                                key={oIndex}
                            />
                        ))}
                    </div>
                )}
        </div>
    );
}
