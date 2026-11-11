import AIEvaluationCard from '@/components/attempt/ai-evaluation-card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { cn } from '@/lib/utils';
import { AttemptPart, AttemptType, Question } from '@/types';
import { Check, Minus, X } from 'lucide-react';
import { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';

/** Answer keys may hold alternatives ("colour/color", "a; b") and numbers with commas ("1,000"). */
export function checkAnswerCorrect(correctAnswer?: string | null, studentAnswer?: string | null): boolean {
    if (!correctAnswer || !studentAnswer) return false;
    const student = studentAnswer.trim().toLowerCase();
    if (!student) return false;

    const expanded: string[] = [];
    correctAnswer
        .split(/[/;|]/)
        .map((value) => value.trim().toLowerCase())
        .filter(Boolean)
        .forEach((clean) => {
            expanded.push(clean);
            if (clean.includes(',')) expanded.push(clean.replace(/,/g, ''));
        });

    return expanded.includes(student) || expanded.includes(student.replace(/,/g, ''));
}

type Verdict = 'correct' | 'wrong' | 'partial' | 'blank';

interface AnswerRow {
    key: string;
    number: string;
    answer: string[];
    correct: string[];
    verdict: Verdict;
    /** Points earned / available (multi-answer questions count more than once). */
    earned: number;
    available: number;
    typeName: string;
}

function evaluate(question: Question): Pick<AnswerRow, 'answer' | 'correct' | 'verdict' | 'earned' | 'available'> {
    const available = Number(question.is_correct_count) || 1;

    if (question.options.length === 0) {
        const given = question.attempt_answer?.answer_text?.trim() ?? '';
        const ok = checkAnswerCorrect(question.answer_text, given);
        return {
            answer: given ? [given] : [],
            correct: question.answer_text ? [question.answer_text] : [],
            verdict: !given ? 'blank' : ok ? 'correct' : 'wrong',
            earned: ok ? available : 0,
            available,
        };
    }

    const chosen = question.attempt_answer?.attempt_answer_options ?? [];
    const earned = Math.min(available, chosen.filter((opt) => Number(opt.option?.is_correct) === 1).length);
    return {
        answer: chosen.map((opt) => opt.option?.textarea ?? ''),
        correct: question.options.filter((opt) => Number(opt.is_correct) === 1).map((opt) => opt.textarea),
        verdict: chosen.length === 0 ? 'blank' : earned >= available ? 'correct' : earned > 0 ? 'partial' : 'wrong',
        earned,
        available,
    };
}

function useAttemptParts(attemptType: AttemptType) {
    const [parts, setParts] = useState<AttemptPart[] | null>(null);

    useEffect(() => {
        let cancelled = false;
        fetch(route('attempt-part.index', { attempt_id: attemptType.attempt_id, type_id: attemptType.type_id }), {
            headers: { Accept: 'application/json' },
        })
            .then((res) => res.json())
            .then((res) => !cancelled && setParts(res.data ?? res))
            .catch(() => !cancelled && setParts([]));
        return () => {
            cancelled = true;
        };
    }, [attemptType.attempt_id, attemptType.type_id]);

    return parts;
}

const VerdictIcon = ({ verdict, earned, available }: { verdict: Verdict; earned: number; available: number }) => {
    const { t } = useTranslation();
    if (verdict === 'correct') return <Check className="mx-auto h-4 w-4 text-emerald-600 dark:text-emerald-300" aria-label={t('attempt_result.correct')} />;
    if (verdict === 'blank') return <Minus className="mx-auto h-4 w-4 text-muted-foreground" aria-label={t('attempt_result.no_answer')} />;
    if (verdict === 'partial')
        return (
            <span className="font-mono text-[10px] font-bold text-amber-700 dark:text-amber-300" title={t('attempt_result.partial')}>
                {earned}/{available}
            </span>
        );
    return <X className="mx-auto h-4 w-4 text-rose-600 dark:text-rose-300" aria-label={t('attempt_result.wrong')} />;
};

/**
 * Listening / Reading breakdown: accuracy by question type and a compact answers table
 * (№, answer, ✓/✗/—, correct answer — emphasised only when the answer was not right).
 */
function ObjectiveBreakdown({ parts }: { parts: AttemptPart[] }) {
    const { t } = useTranslation();

    const rows = useMemo(() => {
        const list: AnswerRow[] = [];
        parts.forEach((attemptPart) => {
            let order = Number(attemptPart.part?.order) || 0;
            attemptPart.part?.sections?.forEach((section) => {
                const typeName = section.question_type?.name || section.question_type?.type || t('attempt_result.other_questions');
                section.questions?.forEach((question, index) => {
                    const count = Number(question.is_correct_count) || 1;
                    order += count;
                    const number = count > 1 ? `${order - count + 1}–${order}` : String(order);
                    list.push({ key: `${question.id}-${index}`, number, typeName, ...evaluate(question) });
                });
            });
        });
        return list;
    }, [parts, t]);

    const stats = useMemo(() => {
        const map = new Map<string, { name: string; correct: number; total: number }>();
        rows.forEach((row) => {
            const stat = map.get(row.typeName) ?? { name: row.typeName, correct: 0, total: 0 };
            stat.correct += row.earned;
            stat.total += row.available;
            map.set(row.typeName, stat);
        });
        return [...map.values()].filter((s) => s.total > 0);
    }, [rows]);

    if (rows.length === 0) return <p className="py-6 text-center text-xs text-muted-foreground">{t('attempt_result.no_answers')}</p>;

    return (
        <div className="space-y-4">
            {stats.length > 0 && (
                <div className="glass-subtle rounded-[18px] p-3">
                    <h4 className="mb-2 text-[10px] font-bold tracking-wider text-muted-foreground uppercase">{t('question_types_analytics')}</h4>
                    <ul className="space-y-2">
                        {stats.map((stat) => {
                            const pct = Math.round((stat.correct / stat.total) * 100);
                            return (
                                <li key={stat.name} className="space-y-1">
                                    <div className="flex items-center justify-between gap-2 text-xs">
                                        <span className="min-w-0 truncate font-semibold text-foreground" title={stat.name}>
                                            {stat.name}
                                        </span>
                                        <span className="shrink-0 font-mono font-bold text-foreground tabular-nums">
                                            {stat.correct}/{stat.total} <span className="text-muted-foreground">({pct}%)</span>
                                        </span>
                                    </div>
                                    <div className="h-1.5 w-full overflow-hidden rounded-full bg-muted">
                                        <div
                                            className={cn('h-full rounded-full', pct >= 75 ? 'bg-emerald-500' : pct >= 50 ? 'bg-amber-500' : 'bg-rose-500')}
                                            style={{ width: `${pct}%` }}
                                        />
                                    </div>
                                </li>
                            );
                        })}
                    </ul>
                </div>
            )}

            <div className="overflow-hidden rounded-[18px] border border-glass-edge">
                <Table stacked={false} className="table-fixed">
                    <TableHeader>
                        <TableRow>
                            <TableHead className="w-12 text-right">№</TableHead>
                            <TableHead>{t('answer')}</TableHead>
                            <TableHead className="w-10 text-center">
                                <span className="sr-only">{t('attempt_result.result')}</span>✓
                            </TableHead>
                            <TableHead>{t('correct_answer')}</TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {rows.map((row) => {
                            const right = row.verdict === 'correct';
                            return (
                                <TableRow key={row.key} className={cn(row.verdict === 'wrong' && 'bg-rose-500/5', row.verdict === 'partial' && 'bg-amber-500/5')}>
                                    <TableCell className="py-1.5 text-right font-mono text-muted-foreground tabular-nums">{row.number}</TableCell>
                                    <TableCell className="py-1.5">
                                        {row.answer.length > 0 ? (
                                            row.answer.map((value, i) => (
                                                <div key={i} className={cn('break-words', right ? 'text-foreground' : 'text-foreground/80')}>
                                                    {value}
                                                </div>
                                            ))
                                        ) : (
                                            <span className="text-muted-foreground">—</span>
                                        )}
                                    </TableCell>
                                    <TableCell className="py-1.5 text-center">
                                        <VerdictIcon verdict={row.verdict} earned={row.earned} available={row.available} />
                                    </TableCell>
                                    <TableCell className="py-1.5">
                                        {row.correct.map((value, i) => (
                                            <div
                                                key={i}
                                                className={cn(
                                                    'break-words',
                                                    right ? 'text-muted-foreground' : 'font-bold text-emerald-700 dark:text-emerald-300',
                                                )}
                                            >
                                                {value}
                                            </div>
                                        ))}
                                    </TableCell>
                                </TableRow>
                            );
                        })}
                    </TableBody>
                </Table>
            </div>
        </div>
    );
}

/** Writing / Speaking: each task with the candidate's answer, the AI review and the score. */
function WrittenBreakdown({ parts, isWriting }: { parts: AttemptPart[]; isWriting: boolean }) {
    const { t } = useTranslation();

    const questions = parts.flatMap((attemptPart) => attemptPart.part?.sections?.flatMap((section) => section.questions ?? []) ?? []);
    const total = questions.reduce((sum, question) => sum + (Number(question.attempt_answer?.score) || 0), 0);

    if (questions.length === 0) return <p className="py-6 text-center text-xs text-muted-foreground">{t('attempt_result.no_answers')}</p>;

    return (
        <div className="space-y-4">
            {questions.map((question, index) => (
                <div key={question.id} className="glass-subtle space-y-3 rounded-[18px] p-4">
                    <div className="flex items-start justify-between gap-3">
                        <div className="min-w-0">
                            <span className="text-[10px] font-bold tracking-wider text-muted-foreground uppercase">
                                {t('attempt_result.task', { n: index + 1 })}
                            </span>
                            {question.textarea && <p className="mt-0.5 text-sm break-words text-foreground">{question.textarea}</p>}
                        </div>
                        <span className="shrink-0 rounded-full bg-indigo-500/12 px-2.5 py-0.5 font-mono text-xs font-bold text-brand">
                            {t('score')}: {question.attempt_answer?.score ?? '—'}
                        </span>
                    </div>
                    <div className="grid gap-3 lg:grid-cols-2">
                        <div className="min-w-0 rounded-[14px] border border-glass-edge bg-glass-subtle p-3 text-sm whitespace-pre-wrap text-foreground">
                            {question.attempt_answer?.answer_text || <span className="text-muted-foreground">{t('attempt_result.no_answer')}</span>}
                        </div>
                        {isWriting && (
                            <div className="min-w-0">
                                <AIEvaluationCard
                                    rawNote={question.attempt_answer?.review_note_ai}
                                    score={question.attempt_answer?.score}
                                    essayText={question.attempt_answer?.answer_text}
                                    answerId={question.attempt_answer?.id}
                                />
                            </div>
                        )}
                    </div>
                </div>
            ))}
            <div className="flex justify-end text-sm font-semibold">
                {t('total_score')}: <span className="ml-1 font-mono">{total}</span>
            </div>
        </div>
    );
}

const AttemptTypeComponent = ({ attempt_type }: { attempt_type: AttemptType }) => {
    const { t } = useTranslation();
    const parts = useAttemptParts(attempt_type);
    const name = attempt_type.type?.name;

    if (parts === null) {
        return (
            <div className="flex items-center justify-center gap-2 py-8 text-sm text-muted-foreground">
                <span className="inline-block h-4 w-4 animate-spin rounded-full border-2 border-primary border-t-transparent" />
                {t('loading')}
            </div>
        );
    }

    return name === 'Writing' || name === 'Speaking' ? <WrittenBreakdown parts={parts} isWriting={name === 'Writing'} /> : <ObjectiveBreakdown parts={parts} />;
};

export default AttemptTypeComponent;
