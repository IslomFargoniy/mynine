import { CandidateStatusBadge, EmptyState, fmtDateTime, inputClass, OnlineDot, PageHeader, Panel, selectClass, useAutoRefresh } from '@/components/exam-admin/shared';
import MockStudentManager from '@/components/mock/mock-student-manager';
import { Button } from '@/components/ui/button';
import AppLayout from '@/layouts/app-layout';
import { type BreadcrumbItem } from '@/types';
import { Head, router, usePage } from '@inertiajs/react';
import { AlertTriangle, CheckCheck, ConciergeBell, FileText, LogIn, Printer, Search, Unlock } from 'lucide-react';
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
    device: { name: string; online: boolean } | null;
    repeats: RepeatModule[];
}

interface PageProps {
    date: string;
    mocks: ReceptionMock[];
    candidates: CandidateRow[];
    filters: { mock_id: number | null; search: string };
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
                    <select className={`${selectClass} lg:w-72`} value={filters.mock_id ?? ''} onChange={(e) => visit({ mock_id: e.target.value || undefined })}>
                        <option value="">{t('exam_admin.reception.all_mocks', { count: mocks.length })}</option>
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
                        <Search className="absolute top-1/2 left-3 h-3.5 w-3.5 -translate-y-1/2 text-gray-400" />
                        <input className={`${inputClass} pl-8`} value={search} onChange={(e) => setSearch(e.target.value)} placeholder={t('exam_admin.reception.search')} />
                    </form>
                    <Button
                        variant="outline"
                        disabled={readySelected.length === 0}
                        onClick={() => printResults(readySelected)}
                        className="rounded-xl text-xs font-bold"
                    >
                        <Printer className="h-4 w-4" />
                        {t('exam_admin.reception.print_selected', { count: readySelected.length })}
                    </Button>
                </Panel>

                <div className="flex flex-wrap gap-2">
                    {['not_arrived', 'checked_in', 'in_exam', 'written_done', 'speaking_waiting', 'result_ready', 'delivered'].map((status) => (
                        <span key={status} className="inline-flex items-center gap-1.5">
                            <CandidateStatusBadge status={status} />
                            <b className="text-xs text-gray-600 dark:text-gray-300">{counts[status] ?? 0}</b>
                        </span>
                    ))}
                </div>

                {mocks.length === 0 ? (
                    <EmptyState>{t('exam_admin.reception.no_mocks')}</EmptyState>
                ) : candidates.length === 0 ? (
                    <EmptyState>{t('exam_admin.reception.no_candidates')}</EmptyState>
                ) : (
                    <Panel className="overflow-x-auto p-0">
                        <table className="w-full text-left text-xs">
                            <thead className="bg-gray-50 text-[10px] font-bold text-gray-500 uppercase dark:bg-gray-800/60 dark:text-gray-400">
                                <tr>
                                    <th className="px-3 py-2.5">
                                        <input
                                            type="checkbox"
                                            className="accent-indigo-600"
                                            checked={selected.length > 0 && selected.length === candidates.length}
                                            onChange={(e) => setSelected(e.target.checked ? candidates.map((c) => c.id) : [])}
                                        />
                                    </th>
                                    <th className="px-3 py-2.5">{t('exam_admin.common.candidate')}</th>
                                    <th className="px-3 py-2.5">{t('exam_admin.common.code')}</th>
                                    <th className="px-3 py-2.5">{t('exam_admin.common.status')}</th>
                                    <th className="px-3 py-2.5">{t('exam_admin.reception.speaking')}</th>
                                    <th className="px-3 py-2.5">{t('exam_admin.reception.pc')}</th>
                                    <th className="px-3 py-2.5 text-right">{t('exam_admin.common.actions')}</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                                {candidates.map((c) => (
                                    <tr key={c.id} className="hover:bg-gray-50/60 dark:hover:bg-gray-800/30">
                                        <td className="px-3 py-2.5">
                                            <input type="checkbox" className="accent-indigo-600" checked={selected.includes(c.id)} onChange={() => toggle(c.id)} />
                                        </td>
                                        <td className="px-3 py-2.5">
                                            <div className="font-bold text-gray-900 dark:text-white">{c.name}</div>
                                            <div className="font-mono text-[11px] text-gray-500">{c.phone ?? '—'}</div>
                                            {!filters.mock_id && mocks.length > 1 && <div className="text-[10px] text-indigo-500">{c.mock_name}</div>}
                                            {c.repeats.length > 0 && (
                                                <div
                                                    className="mt-0.5 flex items-center gap-1 text-[10px] font-bold text-amber-600"
                                                    title={c.repeats.map((r) => `${r.type} — ${r.test} (${r.date ?? ''})`).join('\n')}
                                                >
                                                    <AlertTriangle className="h-3 w-3" />
                                                    {t('exam_admin.candidates.repeat')}: {c.repeats.map((r) => r.type).join(', ')}
                                                </div>
                                            )}
                                        </td>
                                        <td className="px-3 py-2.5 font-mono font-bold text-indigo-600 dark:text-indigo-400">{c.code}</td>
                                        <td className="px-3 py-2.5">
                                            <CandidateStatusBadge status={c.status} module={c.current_module} />
                                            {c.status === 'delivered' && c.delivered_by && (
                                                <div className="mt-0.5 text-[10px] text-gray-400">
                                                    {c.delivered_by} · {fmtDateTime(c.result_delivered_at, 'HH:mm')}
                                                </div>
                                            )}
                                            {!c.result_ready && c.status !== 'not_arrived' && c.status !== 'checked_in' && c.missing.length > 0 && (
                                                <div className="mt-0.5 text-[10px] text-gray-400">
                                                    {t('exam_admin.reception.waiting_for')}: {c.missing.map((m) => t(`exam_admin.reception.missing.${m}`)).join(', ')}
                                                </div>
                                            )}
                                        </td>
                                        <td className="px-3 py-2.5 font-mono">{fmtDateTime(c.speaking_at, 'HH:mm')}</td>
                                        <td className="px-3 py-2.5">{c.device ? <OnlineDot online={c.device.online} label={c.device.name} /> : '—'}</td>
                                        <td className="px-3 py-2.5">
                                            <div className="flex flex-wrap justify-end gap-1">
                                                {!c.checked_in_at && (
                                                    <Button size="sm" onClick={() => post('reception.check-in', c.id)} className="h-7 rounded-lg bg-blue-600 px-2 text-[11px] text-white hover:bg-blue-700">
                                                        <LogIn className="h-3.5 w-3.5" />
                                                        {t('exam_admin.reception.check_in')}
                                                    </Button>
                                                )}
                                                <Button
                                                    size="sm"
                                                    variant="outline"
                                                    className="h-7 rounded-lg px-2 text-[11px]"
                                                    title={t('exam_admin.candidates.print_card')}
                                                    onClick={() => window.open(route('mock.code-cards', { mock: c.mock_id, ids: String(c.id) }), '_blank')}
                                                >
                                                    <Printer className="h-3.5 w-3.5" />
                                                </Button>
                                                {c.result_ready && (
                                                    <Button size="sm" variant="outline" onClick={() => printResults([c.id])} className="h-7 rounded-lg px-2 text-[11px]">
                                                        <FileText className="h-3.5 w-3.5 text-emerald-600" />
                                                        {c.result_printed_at ? t('exam_admin.reception.reprint') : t('exam_admin.reception.print_result')}
                                                    </Button>
                                                )}
                                                {c.result_ready && !c.result_delivered_at && (
                                                    <Button
                                                        size="sm"
                                                        onClick={() => post('reception.deliver', c.id)}
                                                        className="h-7 rounded-lg bg-emerald-600 px-2 text-[11px] text-white hover:bg-emerald-700"
                                                    >
                                                        <CheckCheck className="h-3.5 w-3.5" />
                                                        {t('exam_admin.reception.deliver')}
                                                    </Button>
                                                )}
                                                {c.attempt_id && c.device && (
                                                    <Button
                                                        size="sm"
                                                        variant="outline"
                                                        className="h-7 rounded-lg px-2 text-[11px]"
                                                        title={t('exam_admin.monitor.unlock')}
                                                        onClick={() => {
                                                            if (confirm(t('exam_admin.monitor.unlock_confirm', { name: c.name }))) post('monitor.unlock', c.attempt_id!);
                                                        }}
                                                    >
                                                        <Unlock className="h-3.5 w-3.5" />
                                                    </Button>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </Panel>
                )}
            </div>
        </AppLayout>
    );
}
