import { EmptyState, fmtBand, fmtDateTime, PageHeader, Panel, selectClass } from '@/components/exam-admin/shared';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow, TruncatedText } from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import AppLayout from '@/layouts/app-layout';
import { calculateOverallBand } from '@/lib/ielts-score-converter';
import { type BreadcrumbItem } from '@/types';
import { Head, router, usePage } from '@inertiajs/react';
import { format } from 'date-fns';
import { CalendarClock, CheckCircle2, Mic, Save, Wand2 } from 'lucide-react';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';

type CriterionKey = 'fluency' | 'lexical' | 'grammar' | 'pronunciation';

interface SpeakingCandidate {
    id: number;
    name: string;
    code: string;
    speaking_at: string | null;
    written_done: boolean;
    band: number | null;
    criteria: Record<CriterionKey, number | null>;
    note: string | null;
}

interface PageProps {
    mocks: { id: number; name: string; started_at: string }[];
    mock: { id: number; name: string; started_at: string; speaking_starts_at: string | null; speaking_slot_minutes: number } | null;
    candidates: SpeakingCandidate[];
    criteria: Record<CriterionKey, string>;
    [key: string]: unknown;
}

const BANDS = Array.from({ length: 19 }, (_, i) => i * 0.5);

function toLocalInput(value: string | null): string {
    return value ? format(new Date(value), "yyyy-MM-dd'T'HH:mm") : '';
}

function SlotEditor({ candidate }: { candidate: SpeakingCandidate }) {
    const { t } = useTranslation();
    const [value, setValue] = useState(toLocalInput(candidate.speaking_at));
    const dirty = value !== toLocalInput(candidate.speaking_at);

    return (
        <div className="flex items-center gap-1">
            <input
                type="datetime-local"
                className="h-8 rounded-full border border-input bg-glass-subtle px-3 text-xs text-foreground focus:border-ring focus:ring-2 focus:ring-ring/40"
                value={value}
                onChange={(e) => setValue(e.target.value)}
            />
            {dirty && (
                <Button
                    size="sm"
                    className="h-8 rounded-full px-3"
                    title={t('exam_admin.common.save')}
                    onClick={() =>
                        router.post(route('speaking.slot', candidate.id), { speaking_at: value ? value.replace('T', ' ') : null }, { preserveScroll: true })
                    }
                >
                    <Save className="h-3.5 w-3.5" />
                </Button>
            )}
        </div>
    );
}

function ScoreDialog({ candidate, criteria, onClose }: { candidate: SpeakingCandidate; criteria: PageProps['criteria']; onClose: () => void }) {
    const { t } = useTranslation();
    const [values, setValues] = useState<Record<CriterionKey, string>>({
        fluency: candidate.criteria.fluency?.toString() ?? '',
        lexical: candidate.criteria.lexical?.toString() ?? '',
        grammar: candidate.criteria.grammar?.toString() ?? '',
        pronunciation: candidate.criteria.pronunciation?.toString() ?? '',
    });
    const [note, setNote] = useState(candidate.note ?? '');
    const [processing, setProcessing] = useState(false);

    const filled = (Object.values(values) as string[]).every((v) => v !== '');
    const band = filled ? calculateOverallBand(Object.values(values).map(Number)) : null;

    const submit = () => {
        setProcessing(true);
        router.post(
            route('speaking.score', candidate.id),
            { ...Object.fromEntries(Object.entries(values).map(([k, v]) => [k, Number(v)])), note },
            { preserveScroll: true, onSuccess: onClose, onFinish: () => setProcessing(false) },
        );
    };

    return (
        <Dialog open onOpenChange={(open) => !open && onClose()}>
            <DialogContent className="sm:max-w-md">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2">
                        <Mic className="h-5 w-5 text-violet-700 dark:text-violet-300" />
                        {candidate.name}
                    </DialogTitle>
                    <DialogDescription className="font-mono text-xs">{candidate.code}</DialogDescription>
                </DialogHeader>
                <div className="space-y-3">
                    {(Object.keys(criteria) as CriterionKey[]).map((key) => (
                        <label key={key} className="flex items-center justify-between gap-3 text-sm">
                            <span className="font-semibold">{criteria[key]}</span>
                            <select className={`${selectClass} w-24`} value={values[key]} onChange={(e) => setValues((prev) => ({ ...prev, [key]: e.target.value }))}>
                                <option value="">—</option>
                                {BANDS.map((b) => (
                                    <option key={b} value={b}>
                                        {b.toFixed(1)}
                                    </option>
                                ))}
                            </select>
                        </label>
                    ))}
                    <textarea
                        rows={3}
                        className="w-full rounded-xl border border-input bg-glass-subtle p-2 text-xs text-foreground focus:border-ring focus:ring-2 focus:ring-ring/40"
                        placeholder={t('exam_admin.speaking.note')}
                        value={note}
                        onChange={(e) => setNote(e.target.value)}
                    />
                    <div className="flex items-center justify-between rounded-[18px] border border-violet-500/25 bg-violet-500/12 p-3 dark:bg-violet-400/15">
                        <span className="text-xs font-bold text-violet-700 uppercase dark:text-violet-300">{t('exam_admin.speaking.band')}</span>
                        <span className="text-2xl font-black text-violet-700 dark:text-violet-300">{fmtBand(band)}</span>
                    </div>
                </div>
                <DialogFooter>
                    <Button disabled={!filled || processing} onClick={submit} className="rounded-full">
                        {t('exam_admin.common.save')}
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}

export default function SpeakingIndex() {
    const { mocks, mock, candidates, criteria } = usePage<PageProps>().props;
    const { t } = useTranslation();
    const [order, setOrder] = useState<'finish' | 'name'>('finish');
    const [onlyUnassigned, setOnlyUnassigned] = useState(false);
    const [scoring, setScoring] = useState<SpeakingCandidate | null>(null);

    const breadcrumbs: BreadcrumbItem[] = [{ title: t('exam_admin.nav.speaking'), href: route('speaking.index') }];

    const autoAssign = () => {
        if (!mock) return;
        router.post(route('speaking.auto-assign', mock.id), { order, only_unassigned: onlyUnassigned ? 1 : 0 }, { preserveScroll: true });
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('exam_admin.nav.speaking')} />
            <div className="mx-auto max-w-6xl space-y-5 p-4 md:p-6">
                <PageHeader
                    icon={<Mic className="h-5 w-5" />}
                    title={t('exam_admin.nav.speaking')}
                    description={
                        mock
                            ? t('exam_admin.speaking.description', {
                                  start: mock.speaking_starts_at ? fmtDateTime(mock.speaking_starts_at) : t('exam_admin.speaking.now'),
                                  minutes: mock.speaking_slot_minutes,
                              })
                            : undefined
                    }
                    actions={
                        <select
                            className={`${selectClass} w-full sm:w-72`}
                            value={mock?.id ?? ''}
                            onChange={(e) => router.get(route('speaking.index'), { mock_id: e.target.value || undefined })}
                        >
                            {mocks.map((m) => (
                                <option key={m.id} value={m.id}>
                                    {m.name} · {fmtDateTime(m.started_at, 'dd.MM')}
                                </option>
                            ))}
                        </select>
                    }
                />

                {mock && (
                    <Panel className="flex flex-wrap items-center gap-3">
                        <CalendarClock className="h-4 w-4 text-brand" />
                        <span className="text-xs font-bold">{t('exam_admin.speaking.auto_assign')}</span>
                        <select className={selectClass} value={order} onChange={(e) => setOrder(e.target.value as 'finish' | 'name')}>
                            <option value="finish">{t('exam_admin.speaking.order_finish')}</option>
                            <option value="name">{t('exam_admin.speaking.order_name')}</option>
                        </select>
                        <label className="flex items-center gap-1.5 text-xs">
                            <input type="checkbox" className="accent-primary" checked={onlyUnassigned} onChange={(e) => setOnlyUnassigned(e.target.checked)} />
                            {t('exam_admin.speaking.only_unassigned')}
                        </label>
                        <Button size="sm" onClick={autoAssign} className="rounded-full text-xs">
                            <Wand2 className="h-3.5 w-3.5" />
                            {t('exam_admin.speaking.assign')}
                        </Button>
                        {!mock.speaking_starts_at && <span className="text-[11px] text-muted-foreground">{t('exam_admin.speaking.no_start')}</span>}
                    </Panel>
                )}

                {candidates.length === 0 ? (
                    <EmptyState>{t('exam_admin.reception.no_candidates')}</EmptyState>
                ) : (
                    <Panel className="overflow-hidden p-0">
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead>{t('exam_admin.speaking.slot')}</TableHead>
                                    <TableHead>{t('exam_admin.common.candidate')}</TableHead>
                                    <TableHead>{t('exam_admin.speaking.written')}</TableHead>
                                    <TableHead>{t('exam_admin.speaking.band')}</TableHead>
                                    <TableHead className="w-px">
                                        <span className="sr-only">{t('exam_admin.common.actions')}</span>
                                    </TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {candidates.map((c) => (
                                    <TableRow key={c.id}>
                                        <TableCell label={t('exam_admin.speaking.slot')}>
                                            <SlotEditor key={c.speaking_at ?? 'none'} candidate={c} />
                                        </TableCell>
                                        <TableCell className="max-md:order-first">
                                            <TruncatedText className="max-w-[16rem] font-bold">{c.name}</TruncatedText>
                                            <div className="font-mono text-[11px] text-brand">{c.code}</div>
                                        </TableCell>
                                        <TableCell label={t('exam_admin.speaking.written')}>
                                            {c.written_done ? (
                                                <CheckCircle2 className="h-4 w-4 text-emerald-500" aria-label={t('exam_admin.speaking.written')} />
                                            ) : (
                                                <span className="text-[11px] text-muted-foreground">{t('exam_admin.speaking.not_yet')}</span>
                                            )}
                                        </TableCell>
                                        <TableCell label={t('exam_admin.speaking.band')} className="text-lg font-black text-violet-700 dark:text-violet-300">
                                            {fmtBand(c.band)}
                                        </TableCell>
                                        <TableCell className="text-right">
                                            <Button size="sm" variant="outline" className="rounded-full text-xs whitespace-nowrap" onClick={() => setScoring(c)}>
                                                <Mic className="h-3.5 w-3.5 text-violet-700 dark:text-violet-300" />
                                                {c.band === null ? t('exam_admin.speaking.score') : t('exam_admin.speaking.rescore')}
                                            </Button>
                                        </TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    </Panel>
                )}
            </div>
            {scoring && <ScoreDialog candidate={scoring} criteria={criteria} onClose={() => setScoring(null)} />}
        </AppLayout>
    );
}
