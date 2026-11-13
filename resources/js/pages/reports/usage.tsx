import { PageHeader, Panel } from '@/components/exam-admin/shared';
import CenterTabs from '@/components/center/center-tabs';
import {
    type BilledCandidate,
    candidateSheetRows,
    CandidatesTable,
    CountingRule,
    fmtInt,
    fmtTokens,
    fmtUsd,
    MonthPicker,
    type ReportRow,
} from '@/components/reports/report-parts';
import { Button } from '@/components/ui/button';
import AppLayout from '@/layouts/app-layout';
import { exportSheetsToExcel } from '@/lib/excel-export';
import { type BreadcrumbItem } from '@/types';
import { Head, usePage } from '@inertiajs/react';
import { FileSpreadsheet, Gauge } from 'lucide-react';
import { type ReactNode } from 'react';
import { useTranslation } from 'react-i18next';

interface PageProps {
    month: string;
    row: ReportRow | null;
    candidates: BilledCandidate[];
    [key: string]: unknown;
}

function Stat({ label, value, hint }: { label: string; value: ReactNode; hint?: ReactNode }) {
    return (
        <Panel>
            <div className="text-muted-foreground text-[11px] font-bold tracking-wide uppercase">{label}</div>
            <div className="text-foreground mt-1 text-2xl font-extrabold tabular-nums">{value}</div>
            {hint && <div className="text-muted-foreground mt-0.5 text-[11px] tabular-nums">{hint}</div>}
        </Panel>
    );
}

/** A center Admin's own monthly numbers: billed candidates, mocks held, AI usage. */
export default function ReportsUsage() {
    const { month, row, candidates } = usePage<PageProps>().props;
    const { t } = useTranslation();
    const breadcrumbs: BreadcrumbItem[] = [{ title: t('exam_admin.nav.usage'), href: route('usage.index') }];

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('exam_admin.nav.usage')} />
            <div className="mx-auto w-full max-w-5xl space-y-5 p-4 md:p-6">
                <CenterTabs />
                <PageHeader
                    icon={<Gauge className="h-5 w-5" />}
                    title={t('exam_admin.nav.usage')}
                    description={row ? t('reports.usage_description', { name: row.name }) : undefined}
                    actions={
                        <>
                            <MonthPicker month={month} routeName="usage.index" />
                            <Button
                                size="sm"
                                variant="outline"
                                disabled={candidates.length === 0}
                                onClick={() =>
                                    exportSheetsToExcel(
                                        [{ name: month, rows: candidateSheetRows(candidates, t) }],
                                        `Candidates_${row?.code ?? ''}_${month}`,
                                    )
                                }
                            >
                                <FileSpreadsheet className="h-4 w-4" />
                                {t('reports.export')}
                            </Button>
                        </>
                    }
                />

                {row && (
                    <div className="grid gap-3 sm:grid-cols-3">
                        <Stat label={t('reports.columns.candidates')} value={fmtInt(row.candidates)} />
                        <Stat label={t('reports.columns.mocks')} value={fmtInt(row.mocks)} />
                        <Stat
                            label={t('reports.columns.ai_total')}
                            value={fmtUsd(row.ai.total.cost)}
                            hint={t('reports.calls_tokens', { calls: fmtInt(row.ai.total.calls), tokens: fmtTokens(row.ai.total) })}
                        />
                    </div>
                )}

                <CountingRule />

                <Panel className="overflow-hidden p-0">
                    <CandidatesTable candidates={candidates} />
                </Panel>
            </div>
        </AppLayout>
    );
}
