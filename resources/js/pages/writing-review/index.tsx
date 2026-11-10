import { EmptyState, fmtBand, fmtDateTime, PageHeader, Panel, selectClass } from '@/components/exam-admin/shared';
import { Button } from '@/components/ui/button';
import AppLayout from '@/layouts/app-layout';
import { calculateOverallBand } from '@/lib/ielts-score-converter';
import { cn } from '@/lib/utils';
import { type BreadcrumbItem } from '@/types';
import { Head, Link, router, usePage } from '@inertiajs/react';
import { BotMessageSquare, CheckCircle2, Loader2, PenLine, RefreshCw } from 'lucide-react';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';

interface Essay {
    id: number;
    task: number;
    prompt: string | null;
    text: string;
    words: number;
    score: number | null;
    feedback: string | null;
    ai_pending: boolean;
}

interface ReviewItem {
    id: number;
    attempt_id: number;
    candidate: string;
    code: string | null;
    mock: string | null;
    finished_at: string | null;
    ai_band: number;
    band: number | null;
    reviewed_at: string | null;
    reviewer: string | null;
    ai_pending: boolean;
    essays: Essay[];
}

interface PageProps {
    items: ReviewItem[];
    pagination: { current_page: number; last_page: number; total: number; links: { url: string | null; label: string; active: boolean }[] };
    pendingAi: number;
    mocks: { id: number; name: string }[];
    filters: { status: string; mock_id: number | null };
    [key: string]: unknown;
}

const BANDS = Array.from({ length: 19 }, (_, i) => i * 0.5);

function stripHtml(html: string | null): string {
    if (!html) return '';
    const div = document.createElement('div');
    div.innerHTML = html;
    return div.textContent ?? '';
}

function ReviewCard({ item }: { item: ReviewItem }) {
    const { t } = useTranslation();
    const [scores, setScores] = useState<Record<number, string>>(() =>
        Object.fromEntries(item.essays.map((e) => [e.id, e.score === null ? '' : String(e.score)])),
    );
    const [override, setOverride] = useState('');
    const [processing, setProcessing] = useState(false);
    const [openEssay, setOpenEssay] = useState<number | null>(item.essays[0]?.id ?? null);

    const taskBands = Object.values(scores).filter((v) => v !== '').map(Number);
    const computed = taskBands.length > 0 ? calculateOverallBand(taskBands.concat(Array(Math.max(0, item.essays.length - taskBands.length)).fill(0))) : item.ai_band;
    const finalBand = override !== '' ? Number(override) : computed;

    const confirm = () => {
        setProcessing(true);
        router.post(
            route('writing-review.confirm', item.id),
            {
                scores: Object.fromEntries(Object.entries(scores).filter(([, v]) => v !== '').map(([k, v]) => [k, Number(v)])),
                band: override !== '' ? Number(override) : null,
            },
            { preserveScroll: true, onFinish: () => setProcessing(false) },
        );
    };

    const rerun = (essayId: number) => router.post(route('attempt-answer.re-evaluate-ai', essayId), {}, { preserveScroll: true });

    return (
        <Panel className="space-y-4">
            <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                <div>
                    <div className="text-base font-black text-foreground">{item.candidate}</div>
                    <div className="text-[11px] text-muted-foreground">
                        <span className="font-mono text-indigo-600 dark:text-indigo-400">{item.code}</span> · {item.mock} · {fmtDateTime(item.finished_at)}
                    </div>
                </div>
                <div className="flex items-center gap-3">
                    <div className="text-right">
                        <div className="text-[10px] font-bold text-muted-foreground uppercase">{t('exam_admin.writing.ai_band')}</div>
                        <div className="text-xl font-black text-amber-600 dark:text-amber-400">{fmtBand(item.ai_band)}</div>
                    </div>
                    {item.reviewed_at && (
                        <div className="text-right">
                            <div className="text-[10px] font-bold text-muted-foreground uppercase">{t('exam_admin.writing.confirmed')}</div>
                            <div className="text-xl font-black text-emerald-600 dark:text-emerald-400">{fmtBand(item.band)}</div>
                            <div className="text-[10px] text-muted-foreground">
                                {item.reviewer} · {fmtDateTime(item.reviewed_at, 'dd.MM HH:mm')}
                            </div>
                        </div>
                    )}
                    <Link href={route('attempt.show', item.attempt_id)} className="text-[11px] font-bold text-indigo-600 hover:underline dark:text-indigo-400">
                        {t('exam_admin.writing.open_attempt')}
                    </Link>
                </div>
            </div>

            {item.essays.length === 0 && <p className="text-xs text-muted-foreground">{t('exam_admin.writing.no_essays')}</p>}

            <div className="space-y-2">
                {item.essays.map((essay) => (
                    <div key={essay.id} className="rounded-xl border border-border">
                        <div className="flex flex-wrap items-center justify-between gap-2 px-3 py-2">
                            <button type="button" className="text-left text-xs font-bold" onClick={() => setOpenEssay(openEssay === essay.id ? null : essay.id)}>
                                {t('exam_admin.writing.task', { n: essay.task })} · {t('exam_admin.writing.words', { count: essay.words })}
                            </button>
                            <div className="flex items-center gap-2">
                                {essay.ai_pending ? (
                                    <span className="flex items-center gap-1 text-[11px] font-semibold text-amber-600 dark:text-amber-400">
                                        <Loader2 className="h-3 w-3 animate-spin" /> {t('exam_admin.writing.ai_pending')}
                                    </span>
                                ) : (
                                    <span className="text-[11px] text-muted-foreground">
                                        AI: <b>{fmtBand(essay.score)}</b>
                                    </span>
                                )}
                                <select
                                    className={`${selectClass} h-8 w-20`}
                                    value={scores[essay.id] ?? ''}
                                    onChange={(e) => setScores((prev) => ({ ...prev, [essay.id]: e.target.value }))}
                                    title={t('exam_admin.writing.adjust_task')}
                                >
                                    <option value="">—</option>
                                    {BANDS.map((b) => (
                                        <option key={b} value={b}>
                                            {b.toFixed(1)}
                                        </option>
                                    ))}
                                </select>
                                <Button size="sm" variant="outline" className="h-8 rounded-lg px-2 text-[11px]" onClick={() => rerun(essay.id)} title={t('exam_admin.writing.rerun_ai')}>
                                    <RefreshCw className="h-3.5 w-3.5" />
                                </Button>
                            </div>
                        </div>
                        {openEssay === essay.id && (
                            <div className="grid gap-3 border-t border-border p-3 lg:grid-cols-2">
                                <div className="space-y-2">
                                    {essay.prompt && <div className="rounded-lg bg-muted p-2 text-[11px] text-foreground/80">{stripHtml(essay.prompt)}</div>}
                                    <div className="max-h-80 overflow-y-auto text-xs leading-relaxed whitespace-pre-wrap">{essay.text || '—'}</div>
                                </div>
                                <div className="max-h-96 overflow-y-auto rounded-lg bg-amber-50/50 p-3 text-[11px] leading-relaxed whitespace-pre-wrap dark:bg-amber-950/20">
                                    <div className="mb-1 flex items-center gap-1 font-bold text-amber-700 dark:text-amber-400">
                                        <BotMessageSquare className="h-3.5 w-3.5" /> {t('exam_admin.writing.ai_feedback')}
                                    </div>
                                    {essay.feedback ?? '—'}
                                </div>
                            </div>
                        )}
                    </div>
                ))}
            </div>

            <div className="flex flex-wrap items-center justify-end gap-3 border-t border-border pt-3">
                <label className="flex items-center gap-2 text-xs">
                    {t('exam_admin.writing.override')}
                    <select className={`${selectClass} h-8 w-20`} value={override} onChange={(e) => setOverride(e.target.value)}>
                        <option value="">—</option>
                        {BANDS.map((b) => (
                            <option key={b} value={b}>
                                {b.toFixed(1)}
                            </option>
                        ))}
                    </select>
                </label>
                <span className="text-xs">
                    {t('exam_admin.writing.final')}: <b className="text-base">{fmtBand(finalBand)}</b>
                </span>
                <Button disabled={processing || item.ai_pending && override === '' && taskBands.length < item.essays.length} onClick={confirm} className="rounded-xl bg-emerald-600 text-xs font-bold text-white hover:bg-emerald-700">
                    <CheckCircle2 className="h-4 w-4" />
                    {item.reviewed_at ? t('exam_admin.writing.reconfirm') : t('exam_admin.writing.confirm')}
                </Button>
            </div>
        </Panel>
    );
}

export default function WritingReviewIndex() {
    const { items, pagination, pendingAi, mocks, filters } = usePage<PageProps>().props;
    const { t } = useTranslation();

    const breadcrumbs: BreadcrumbItem[] = [{ title: t('exam_admin.nav.writing_review'), href: route('writing-review.index') }];
    const visit = (params: Record<string, string | number | undefined>) =>
        router.get(route('writing-review.index'), { status: filters.status, mock_id: filters.mock_id ?? undefined, ...params }, { preserveState: false });

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('exam_admin.nav.writing_review')} />
            <div className="mx-auto max-w-6xl space-y-5 p-4 md:p-6">
                <PageHeader
                    icon={<PenLine className="h-5 w-5" />}
                    title={t('exam_admin.nav.writing_review')}
                    description={t('exam_admin.writing.description', { count: pagination.total, pending: pendingAi })}
                    actions={
                        <>
                            <select className={selectClass} value={filters.mock_id ?? ''} onChange={(e) => visit({ mock_id: e.target.value || undefined })}>
                                <option value="">{t('exam_admin.common.all_mocks')}</option>
                                {mocks.map((m) => (
                                    <option key={m.id} value={m.id}>
                                        {m.name}
                                    </option>
                                ))}
                            </select>
                            {['pending', 'reviewed', 'all'].map((status) => (
                                <button
                                    key={status}
                                    type="button"
                                    onClick={() => visit({ status })}
                                    className={cn(
                                        'rounded-xl px-3 py-1.5 text-xs font-bold',
                                        filters.status === status ? 'bg-indigo-600 text-white' : 'bg-muted text-foreground/80',
                                    )}
                                >
                                    {t(`exam_admin.writing.filter.${status}`)}
                                </button>
                            ))}
                        </>
                    }
                />

                {pendingAi > 0 && (
                    <div className="flex items-center gap-2 rounded-xl border border-amber-200 bg-amber-50 p-3 text-xs text-amber-800 dark:border-amber-800/50 dark:bg-amber-950/30 dark:text-amber-300">
                        <Loader2 className="h-4 w-4 animate-spin" />
                        {t('exam_admin.writing.pending_ai', { count: pendingAi })}
                        <button type="button" className="ml-auto font-bold underline" onClick={() => router.reload()}>
                            {t('exam_admin.common.refresh')}
                        </button>
                    </div>
                )}

                {items.length === 0 ? (
                    <EmptyState>{t('exam_admin.writing.empty')}</EmptyState>
                ) : (
                    items.map((item) => <ReviewCard key={`${item.id}-${item.reviewed_at ?? ''}`} item={item} />)
                )}

                {pagination.last_page > 1 && (
                    <div className="flex flex-wrap justify-center gap-1">
                        {pagination.links.map((link, i) => (
                            <Link
                                key={i}
                                href={link.url ?? '#'}
                                preserveScroll
                                className={cn(
                                    'rounded-md px-3 py-1 text-xs',
                                    link.active ? 'bg-indigo-600 text-white' : link.url ? 'border border-border' : 'text-muted-foreground',
                                )}
                                dangerouslySetInnerHTML={{ __html: link.label }}
                            />
                        ))}
                    </div>
                )}
            </div>
        </AppLayout>
    );
}
