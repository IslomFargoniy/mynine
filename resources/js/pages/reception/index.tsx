import { CandidateStatusBadge, EmptyState, fmtDateTime, inputClass, OnlineDot, PageHeader, Panel, PcNumber, selectClass, useAutoRefresh } from '@/components/exam-admin/shared';
import MockStudentManager from '@/components/mock/mock-student-manager';
import { Button } from '@/components/ui/button';
import AppLayout from '@/layouts/app-layout';
import { type BreadcrumbItem } from '@/types';
import { Head, router, usePage } from '@inertiajs/react';
import { AlertTriangle, CheckCheck, ConciergeBell, FileText, LogIn, Mic, Printer, Search, Unlock } from 'lucide-react';
import { PrintCodesButton, printCodeTickets } from '@/components/mock/print-codes';
import { IconAction } from '@/components/ui/icon-action';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow, TruncatedText } from '@/components/ui/table';
import { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';

interface ReceptionMock {
    id: number;
    name: string;
    started_at: string;
    finished_at: string;
    status: string;
    require_desktop: boolean;
    students_count: number;
}

interface RepeatModule {
    type: string | null;
    test: string | null;
    date: string | null;
}

interface CandidateRow {
    id: number;
    mock_id: number;
    mock_name: string;
    name: string;
    code: string;
    phone: string | null;
    status: string;
    current_module: string | null;
    missing: string[];
    result_ready: boolean;
    checked_in_at: string | null;
    speaking_at: string | null;
    result_printed_at: string | null;
    result_delivered_at: string | null;
    delivered_by: string | null;
    attempt_id: number | null;
    device: { name: string; number: number | null; online: boolean } | null;
    repeats: RepeatModule[];
}

interface PageProps {
    date: string;
    mocks: ReceptionMock[];
    candidates: CandidateRow[];
    /** 'all' = every mock of the day; null with several mocks = none running or upcoming (server picks otherwise). */
    filters: { mock_id: number | 'all' | null; search: string };
    canDelete: boolean;
    [key: string]: unknown;
}

export default function ReceptionIndex() {
    const { date, mocks, candidates, filters, canDelete } = usePage<PageProps>().props;
    const { t } = useTranslation();
    const [search, setSearch] = useState(filters.search ?? '');
    const [selected, setSelected] = useState<number[]>([]);

    useAutoRefresh(['candidates', 'mocks'], 10000);

    const breadcrumbs: BreadcrumbItem[] = [{ title: t('exam_admin.nav.reception'), href: route('reception.index') }];

    const visit = (params: Record<string, string | number | undefined | null>) => {
        router.get(
            route('reception.index'),
            { date, mock_id: filters.mock_id ?? undefined, search: search || undefined, ...params },
            { preserveState: true, replace: true },
        );
    };

    const counts = useMemo(() => {
        const map: Record<string, number> = {};
        candidates.forEach((c) => (map[c.status] = (map[c.status] ?? 0) + 1));
        return map;
    }, [candidates]);

    const readySelected = candidates.filter((c) => selected.includes(c.id) && c.result_ready).map((c) => c.id);
    const targetMock = mocks.find((m) => m.id === filters.mock_id) ?? (mocks.length === 1 ? mocks[0] : null);

    const post = (name: string, id: number) => router.post(route(name, id), {}, { preserveScroll: true, preserveState: true });

    const printResults = (ids: number[]) => {
        window.open(route('reception.result-sheets', { ids: ids.join(',') }), '_blank');
        window.setTimeout(() => router.reload({ only: ['candidates'] }), 2500);
    };

    const toggle = (id: number) => setSelected((prev) => (prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]));

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('exam_admin.nav.reception')} />
            <div className="mx-auto max-w-7xl space-y-5 p-4 md:p-6">
                <PageHeader
                    icon={<ConciergeBell className="h-5 w-5" />}
                    title={t('exam_admin.nav.reception')}
                    description={t('exam_admin.reception.description')}
                    actions={
                        targetMock && (
                            <MockStudentManager
                                mockId={targetMock.id}
                                mockName={targetMock.name}
                                canDelete={canDelete}
                                triggerLabel={t('exam_admin.reception.add_candidates')}
                                students={candidates
                                    .filter((c) => c.mock_id === targetMock.id)
                                    .map((c) => ({ id: c.id, name: c.name, code: c.code, phone: c.phone, attended: !!c.checked_in_at }))}
                            />
                        )
                    }
                />

                <Panel className="flex flex-col gap-3 lg:flex-row lg:items-center">
                    <input type="date" className={`${inputClass} lg:w-44`} value={date} onChange={(e) => visit({ date: e.target.value, mock_id: undefined })} />
                    <select className={`${selectClass} lg:w-72`} value={filters.mock_id ?? 'all'} onChange={(e) => visit({ mock_id: e.target.value })}>
                        <option value="all">{t('exam_admin.reception.all_mocks', { count: mocks.length })}</option>
                        {mocks.map((m) => (
                            <option key={m.id} value={m.id}>
                                {m.name} · {fmtDateTime(m.started_at, 'HH:mm')} ({m.students_count})
                            </option>
                        ))}
                    </select>
                    <form
                        className="relative flex-1"
                        onSubmit={(e) => {
                            e.preventDefault();
                            visit({});
                        }}
                    >
                        <Search className="absolute top-1/2 left-3 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
                        <input className={`${inputClass} pl-8`} value={search} onChange={(e) => setSearch(e.target.value)} placeholder={t('exam_admin.reception.search')} />
                    </form>
                    {targetMock && (
                        <PrintCodesButton
                            mockId={targetMock.id}
                            ids={candidates.filter((c) => c.mock_id === targetMock.id && selected.includes(c.id)).map((c) => c.id)}
                        />
                    )}
                    <Button
                        variant="outline"
                        disabled={readySelected.length === 0}
                        onClick={() => printResults(readySelected)}
                        className="rounded-full text-xs font-bold"
                    >
                        <Printer className="h-4 w-4" />
                        {t('exam_admin.reception.print_selected', { count: readySelected.length })}
                    </Button>
                </Panel>

                <div className="flex flex-wrap gap-2">
                    {['not_arrived', 'checked_in', 'in_exam', 'written_done', 'speaking_waiting', 'result_ready', 'delivered'].map((status) => (
                        <span key={status} className="inline-flex items-center gap-1.5">
                            <CandidateStatusBadge status={status} />
                            <b className="text-xs text-foreground">{counts[status] ?? 0}</b>
                        </span>
                    ))}
                </div>

                {mocks.length === 0 ? (
                    <EmptyState>{t('exam_admin.reception.no_mocks_hint')}</EmptyState>
                ) : candidates.length === 0 ? (
                    <EmptyState>
                        {filters.search
                            ? t('exam_admin.reception.no_match', { search: filters.search })
                            : t('exam_admin.reception.no_candidates_hint')}
                    </EmptyState>
                ) : (
                    <Panel className="overflow-hidden p-0">
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead className="w-8">
                                        <input
                                            type="checkbox"
                                            className="accent-primary"
                                            aria-label={t('exam_admin.reception.select_all')}
                                            checked={selected.length > 0 && selected.length === candidates.length}
                                            onChange={(e) => setSelected(e.target.checked ? candidates.map((c) => c.id) : [])}
                                        />
                                    </TableHead>
                                    <TableHead>{t('exam_admin.common.candidate')}</TableHead>
                                    <TableHead>{t('exam_admin.common.code')}</TableHead>
                                    <TableHead>{t('exam_admin.common.status')}</TableHead>
                                    <TableHead className="hidden lg:table-cell">
                                        {t('exam_admin.reception.speaking')} / {t('exam_admin.reception.pc')}
                                    </TableHead>
                                    <TableHead className="w-px">
                                        <span className="sr-only">{t('exam_admin.common.actions')}</span>
                                    </TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {candidates.map((c) => {
                                    const speakingAndPc = (
                                        <>
                                            {c.speaking_at && (
                                                <span className="font-mono whitespace-nowrap" title={t('exam_admin.reception.speaking')}>
                                                    <Mic className="mr-0.5 inline h-3 w-3 text-muted-foreground" />
                                                    {fmtDateTime(c.speaking_at, 'HH:mm')}
                                                </span>
                                            )}
                                            {c.device && (
                                                <span className="inline-flex items-center gap-1.5" title={t('exam_admin.reception.pc')}>
                                                    <PcNumber number={c.device.number} />
                                                    <OnlineDot online={c.device.online} label={c.device.name} />
                                                </span>
                                            )}
                                        </>
                                    );

                                    return (
                                        <TableRow key={c.id} className="max-md:relative">
                                            <TableCell className="max-md:absolute max-md:mt-0.5">
                                                <input
                                                    type="checkbox"
                                                    className="accent-primary"
                                                    aria-label={c.name}
                                                    checked={selected.includes(c.id)}
                                                    onChange={() => toggle(c.id)}
                                                />
                                            </TableCell>
                                            <TableCell className="max-md:pl-6">
                                                <TruncatedText className="max-w-[14rem] font-bold text-foreground">{c.name}</TruncatedText>
                                                <div className="font-mono text-[11px] text-muted-foreground">{c.phone ?? '—'}</div>
                                                {(!filters.mock_id || filters.mock_id === 'all') && mocks.length > 1 && <TruncatedText className="max-w-[14rem] text-[10px] text-brand">{c.mock_name}</TruncatedText>}
                                                {c.repeats.length > 0 && (
                                                    <div
                                                        className="mt-0.5 flex items-center gap-1 text-[10px] font-bold text-amber-700 dark:text-amber-300"
                                                        title={c.repeats.map((r) => `${r.type} — ${r.test} (${r.date ?? ''})`).join('\n')}
                                                    >
                                                        <AlertTriangle className="h-3 w-3 shrink-0" />
                                                        {t('exam_admin.candidates.repeat')}: {c.repeats.map((r) => r.type).join(', ')}
                                                    </div>
                                                )}
                                                {(c.speaking_at || c.device) && <div className="mt-1 flex flex-wrap items-center gap-2 text-[11px] lg:hidden">{speakingAndPc}</div>}
                                            </TableCell>
                                            <TableCell label={t('exam_admin.common.code')} className="font-mono font-bold whitespace-nowrap text-brand">
                                                {c.code}
                                            </TableCell>
                                            <TableCell label={t('exam_admin.common.status')}>
                                                <CandidateStatusBadge status={c.status} module={c.current_module} />
                                                {c.status === 'delivered' && c.delivered_by && (
                                                    <div className="mt-0.5 text-[10px] text-muted-foreground">
                                                        {c.delivered_by} · {fmtDateTime(c.result_delivered_at, 'HH:mm')}
                                                    </div>
                                                )}
                                                {!c.result_ready && c.status !== 'not_arrived' && c.status !== 'checked_in' && c.missing.length > 0 && (
                                                    <div className="mt-0.5 text-[10px] text-muted-foreground">
                                                        {t('exam_admin.reception.waiting_for')}: {c.missing.map((m) => t(`exam_admin.reception.missing.${m}`)).join(', ')}
                                                    </div>
                                                )}
                                            </TableCell>
                                            <TableCell className="hidden text-[11px] lg:table-cell">
                                                <div className="flex flex-col items-start gap-1">{c.speaking_at || c.device ? speakingAndPc : '—'}</div>
                                            </TableCell>
                                            <TableCell className="max-md:border-t max-md:border-divider max-md:pt-2">
                                                <div className="flex items-center justify-end gap-0.5">
                                                    {!c.checked_in_at && (
                                                        <Button size="sm" onClick={() => post('reception.check-in', c.id)} className="h-7 rounded-full px-3 text-[11px]">
                                                            <LogIn className="h-3.5 w-3.5" />
                                                            {t('exam_admin.reception.check_in')}
                                                        </Button>
                                                    )}
                                                    {c.result_ready && !c.result_delivered_at && (
                                                        <Button
                                                            size="sm"
                                                            onClick={() => post('reception.deliver', c.id)}
                                                            className="h-7 rounded-full bg-emerald-600 px-3 text-[11px] text-white hover:bg-emerald-700"
                                                        >
                                                            <CheckCheck className="h-3.5 w-3.5" />
                                                            {t('exam_admin.reception.deliver')}
                                                        </Button>
                                                    )}
                                                    <IconAction label={t('exam_admin.candidates.print_ticket')} tone="brand" onClick={() => printCodeTickets(c.mock_id, [c.id])}>
                                                        <Printer />
                                                    </IconAction>
                                                    {c.result_ready && (
                                                        <IconAction
                                                            label={c.result_printed_at ? t('exam_admin.reception.reprint') : t('exam_admin.reception.print_result')}
                                                            tone="success"
                                                            onClick={() => printResults([c.id])}
                                                        >
                                                            <FileText />
                                                        </IconAction>
                                                    )}
                                                    {c.attempt_id && c.device && (
                                                        <IconAction
                                                            label={t('exam_admin.monitor.unlock')}
                                                            onClick={() => {
                                                                if (confirm(t('exam_admin.monitor.unlock_confirm', { name: c.name }))) post('monitor.unlock', c.attempt_id!);
                                                            }}
                                                        >
                                                            <Unlock />
                                                        </IconAction>
                                                    )}
                                                </div>
                                            </TableCell>
                                        </TableRow>
                                    );
                                })}
                            </TableBody>
                        </Table>
                    </Panel>
                )}
            </div>
        </AppLayout>
    );
}
