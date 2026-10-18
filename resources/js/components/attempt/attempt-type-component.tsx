import React, { useEffect, useState, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { AttemptPart, AttemptType } from '@/types';
import { CheckCircle, Minus } from 'lucide-react';
import AIEvaluationCard from '@/components/attempt/ai-evaluation-card';

const AttemptTypeComponent = ({ attempt_type }: { attempt_type: AttemptType }) => {
    const { t } = useTranslation();
    const [attemptParts, setAttemptParts] = useState<AttemptPart[]>([]);

    const getAttemptParts = () => {
        fetch(
            route('attempt-part.index', {
                attempt_id: attempt_type.attempt_id,
                type_id: attempt_type.type_id
            })
        )
            .then((res) => res.json())
            .then((res) => {
                setAttemptParts(res.data ?? res);
            })
            .catch((err) => console.error('getAttemptParts error:', err));
    };

    useEffect(() => {
        getAttemptParts();
    }, []);

    const totalScore = useMemo(() => {
        return attemptParts.reduce((partAcc, part) => {
            return partAcc + (part.part?.sections?.reduce((sectionAcc, section) => {
                return sectionAcc + (section.questions?.reduce((qAcc, question) => {
                    return qAcc + (question.attempt_answer?.score ?? 0);
                }, 0));
            }, 0) ?? 0);
        }, 0);
    }, [attemptParts]);

    const checkAnswerCorrect = (correctAnswer?: string | null, studentAnswer?: string | null): boolean => {
        if (!correctAnswer || !studentAnswer) return false;
        const student = studentAnswer.trim().toLowerCase();
        if (!student) return false;

        const delimiters = ['/', ';', '|'];
        let normalized = [correctAnswer];
        delimiters.forEach(d => {
            const temp: string[] = [];
            normalized.forEach(val => {
                if (val.includes(d)) {
                    temp.push(...val.split(d));
                } else {
                    temp.push(val);
                }
            });
            normalized = temp;
        });

        const expanded: string[] = [];
        normalized.forEach(val => {
            const clean = val.trim().toLowerCase();
            if (!clean) return;
            expanded.push(clean);
            if (clean.includes(',')) {
                const noComma = clean.replace(/,/g, '');
                if (!expanded.includes(noComma)) expanded.push(noComma);
            }
        });

        const studentNoComma = student.replace(/,/g, '');
        return expanded.includes(student) || expanded.includes(studentNoComma);
    };

    // ✅ Compute total score safely
    const sum_is_correct = useMemo(() => {
        let total = 0;

        attemptParts.forEach((attemptPart) => {
            attemptPart.part?.sections.forEach((section) => {
                section.questions.forEach((question) => {
                    if (question.options.length === 0) {
                        // Multi-answer, case-insensitive and comma-resilient comparison
                        if (checkAnswerCorrect(question.answer_text, question.attempt_answer?.answer_text)) {
                            total += 1;
                        }
                    } else {
                        question.attempt_answer?.attempt_answer_options?.forEach((opt) => {
                            if (opt.option.is_correct == 1) {
                                total += 1;
                            }
                        });
                    }
                });
            });
        });

        return total;
    }, [attemptParts]);

    // ✅ Question Types Performance Analytics
    const questionTypeStats = useMemo(() => {
        const stats: Record<string, { total: number; correct: number; name: string }> = {};

        attemptParts.forEach((attemptPart) => {
            attemptPart.part?.sections?.forEach((section) => {
                const typeKey = section.question_type?.name || section.question_type?.type || 'Standard Questions';
                if (!stats[typeKey]) {
                    stats[typeKey] = { total: 0, correct: 0, name: typeKey };
                }

                section.questions?.forEach((question) => {
                    const count = Number(question.is_correct_count) || 1;
                    stats[typeKey].total += count;

                    if (question.options.length === 0) {
                        if (checkAnswerCorrect(question.answer_text, question.attempt_answer?.answer_text)) {
                            stats[typeKey].correct += count;
                        }
                    } else {
                        const correctOpts = question.attempt_answer?.attempt_answer_options?.filter(
                            (opt) => opt.option?.is_correct === 1
                        ).length || 0;
                        stats[typeKey].correct += correctOpts;
                    }
                });
            });
        });

        return Object.values(stats).filter((s) => s.total > 0);
    }, [attemptParts]);

    return (
        <div className="space-y-6">
            {/* Question Types Accuracy Analytics (For Reading / Listening) */}
            {attempt_type.type?.name !== 'Writing' && attempt_type.type?.name !== 'Speaking' && questionTypeStats.length > 0 && (
                <div className="p-4 bg-gray-50 dark:bg-gray-800/60 rounded-xl border border-gray-200 dark:border-gray-700">
                    <h4 className="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-3">
                        {t('question_types_analytics') || 'Savol turlari boʻyicha aniqlik darajasi'}
                    </h4>
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                        {questionTypeStats.map((stat, i) => {
                            const pct = Math.round((stat.correct / stat.total) * 100);
                            const isHigh = pct >= 75;
                            const isMed = pct >= 50 && pct < 75;

                            return (
                                <div
                                    key={i}
                                    className="p-3 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg space-y-1.5 shadow-2xs"
                                >
                                    <div className="flex items-center justify-between text-xs font-medium">
                                        <span className="font-bold text-gray-800 dark:text-gray-200 truncate pr-2" title={stat.name}>
                                            {stat.name}
                                        </span>
                                        <span className="font-mono font-bold text-gray-900 dark:text-white shrink-0">
                                            {stat.correct} / {stat.total} ({pct}%)
                                        </span>
                                    </div>
                                    <div className="w-full bg-gray-100 dark:bg-gray-700 h-1.5 rounded-full overflow-hidden">
                                        <div
                                            className={`h-full rounded-full transition-all duration-300 ${
                                                isHigh ? 'bg-emerald-500' : isMed ? 'bg-amber-500' : 'bg-rose-500'
                                            }`}
                                            style={{ width: `${pct}%` }}
                                        />
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                </div>
            )}

            <div className="overflow-x-auto">
                <table className="border-collapse w-full text-sm text-left text-gray-800 dark:text-gray-100">
                    <thead className="bg-gray-100 dark:bg-gray-700">
                    <tr>
                        <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">
                            {t('n')}
                        </td>

                        {/* ✅ Conditional extra columns */}
                        {attempt_type.type?.name === 'Writing' && (
                            <>
                                <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">
                                    {t('question')}
                                </td>
                            </>
                        )}

                        <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">
                            {t('answer')}
                        </td>

                        {/* ✅ Conditional extra columns */}
                        {attempt_type.type?.name !== 'Writing' && (
                            <>
                                <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">
                                    {t('correct')} <span> : </span>
                                    {attempt_type.type?.name === 'Writing' ?
                                        totalScore
                                        :
                                        sum_is_correct
                                    }
                                </td>

                                <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">
                                    {t('correct_answer')}
                                </td>
                            </>
                        )}

                        {/* ✅ Conditional extra columns */}
                        {attempt_type.type?.name === 'Writing' && (
                            <>
                                <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">
                                    {t('review_note_ai')}
                                </td>
                                <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">
                                    {t('score')} <span> : </span>
                                    {attempt_type.type?.name === 'Writing' ?
                                        totalScore
                                        :
                                        sum_is_correct
                                    }
                                </td>
                            </>
                        )}
                    </tr>
                    </thead>

                    <tbody className="bg-white dark:bg-gray-800">
                    {attemptParts.map((attemptPart) => {
                            let order = Number(attemptPart.part?.order);

                            return (
                                attemptPart.part?.sections.map((section) =>
                                    section.questions.map((question, qIndex) => {
                                            const globalIndex = order += Number(question.is_correct_count ?? 1);

                                            return (
                                                <tr
                                                    key={`${question.id}-${qIndex}`}
                                                    className="hover:bg-gray-50 dark:hover:bg-gray-700"
                                                >
                                                    <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">
                                                        {(() => {
                                                            const count = question.is_correct_count ?? 1;
                                                            return count > 1
                                                                ? Array.from({ length: count }, (_, i) => globalIndex - count + 1 + i).join('-')
                                                                : globalIndex;
                                                        })()}
                                                    </td>

                                                    {attempt_type.type?.name === 'Writing' && (
                                                        <>
                                                            <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">
                                                                {question.textarea}
                                                            </td>
                                                        </>
                                                    )}

                                                    <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">
                                                        {question.attempt_answer?.answer_text && (
                                                            <div
                                                                className={'whitespace-pre-wrap'}>{question.attempt_answer.answer_text}</div>
                                                        )}
                                                        {question.attempt_answer?.attempt_answer_options?.map(
                                                            (opt, idx) => (
                                                                <div key={idx} className="ml-4">
                                                                    - {opt.option?.textarea}
                                                                </div>
                                                            )
                                                        )}
                                                    </td>


                                                    {/* ✅ Conditional extra columns */}
                                                    {attempt_type.type?.name !== 'Writing' && (
                                                        <>
                                                            <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">
                                                                {question.options.length === 0 ? (
                                                                    checkAnswerCorrect(question.answer_text, question.attempt_answer?.answer_text) ? (
                                                                        <CheckCircle className="text-green-600" />
                                                                    ) : (
                                                                        <Minus className="text-red-600" />
                                                                    )
                                                                ) : (
                                                                    question.attempt_answer?.attempt_answer_options?.map((opt, idx) => (
                                                                        <div key={idx}>
                                                                            {opt.option.is_correct === 1 ? (
                                                                                <CheckCircle
                                                                                    className="text-green-600" />
                                                                            ) : (
                                                                                <Minus className="text-red-600" />
                                                                            )}
                                                                        </div>
                                                                    ))
                                                                )}
                                                            </td>

                                                            <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">
                                                                {question.options.length == 0 ? (
                                                                    <div>{question.answer_text}</div>
                                                                ) : (
                                                                    question.options
                                                                        .filter(item => item.is_correct === 1)
                                                                        .map((opt, idx) => (
                                                                            <div key={idx}>
                                                                                {opt.textarea}
                                                                            </div>
                                                                        ))
                                                                )}
                                                            </td>
                                                        </>
                                                    )}


                                                    {/* ✅ Conditional extra columns */}
                                                    {attempt_type.type?.name === 'Writing' && (
                                                        <>
                                                            <td className="border border-gray-300 dark:border-gray-600 p-2">
                                                                <AIEvaluationCard
                                                                    rawNote={question?.attempt_answer?.review_note_ai}
                                                                    score={question?.attempt_answer?.score}
                                                                    essayText={question?.attempt_answer?.answer_text}
                                                                    answerId={question?.attempt_answer?.id}
                                                                />
                                                            </td>
                                                            <td className="border border-gray-300 dark:border-gray-600 px-4 py-2 font-bold text-center">
                                                                {question?.attempt_answer?.score ?? '-'}
                                                            </td>
                                                        </>
                                                    )}


                                                </tr>
                                            );
                                        }
                                    )
                                )
                            );

                        }
                    )}

                    {/* ✅ total score row */}
                    <tr className="bg-gray-100 dark:bg-gray-700 font-semibold">
                        <td
                            className="border border-gray-300 dark:border-gray-600 px-4 py-2"
                            colSpan={attempt_type.type?.name === 'Writing' ? 4 : 2}
                        >
                            {t('total_score')}
                        </td>
                        {attempt_type.type?.name === 'Writing' ?
                            <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">
                                {totalScore}
                            </td>
                            :
                            <>
                                <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">
                                    {sum_is_correct}
                                </td>

                                <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">
                                    {t('correct_answer')}
                                </td>
                            </>
                        }
                    </tr>
                    </tbody>
                </table>
            </div>
        </div>
    )
        ;
};

export default AttemptTypeComponent;
