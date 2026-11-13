import { PageHeader, Panel } from '@/components/exam-admin/shared';
import {
    type AiPart,
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
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow, TruncatedText } from '@/components/ui/table';
import AppLayout from '@/layouts/app-layout';
import { exportSheetsToExcel } from '@/lib/excel-export';
import { cn } from '@/lib/utils';
import { type BreadcrumbItem } from '@/types';
import { Head, usePage } from '@inertiajs/react';
import { FileBarChart, FileSpreadsheet, Lock, Users } from 'lucide-react';
import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';

interface PageProps {
    month: string;
    rows: ReportRow[];
    practice: { ai: ReportRow['ai'] };
    totals: { candidates: number; mocks: number; ai: ReportRow['ai'] };
    [key: string]: unknown;
}

function AiCell({ part }: { part: AiPart }) {
    const { t } = useTranslation();
    if (part.calls === 0) return <span className="text-muted-foreground">—</span>;

    return (
        <div className="leading-tight">
            <div className="text-foreground font-semibold tabular-nums">{fmtUsd(part.cost)}</div>
            <div className="text-muted-foreground text-[10px] tabular-nums">
                {t('reports.calls_tokens', { calls: fmtInt(part.calls), tokens: fmtTokens(part) })}
            </div>
        </div>
    );
}

/** Billed candidates of one center (to check an invoice), with their own Excel export. */
function CandidatesDialog({ row, month, onClose }: { row: ReportRow; month: string; onClose: () => void }) {
    const { t } = useTranslation();
    const [candidates, setCandidates] = useState<BilledCandidate[] | null>(null);
    const [failed, setFailed] = useState(false);

    useEffect(() => {
        fetch(route('reports.candidates', { center: row.id, month }), { headers: { Accept: 'application/json' }, credentials: 'same-origin' })
            .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
            .then((json: { data: BilledCandidate[] }) => setCandidates(json.data))
            .catch(() => setFailed(true));
    }, [row.id, month]);

    return (
        <Dialog open onOpenChange={(open) => !open && onClose()}>
            <DialogContent className="max-h-[85vh] overflow-y-auto sm:max-w-3xl">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2">
                        <Users className="text-brand h-5 w-5" />
                        {t('reports.drill.title', { name: row.name, month })}
                    </DialogTitle>
                    <DialogDescription className="text-xs">{t('reports.drill.description', { count: row.candidates })}</DialogDescription>
                </DialogHeader>
                {failed ? (
                    <p className="text-sm text-rose-600">{t('reports.drill.failed')}</p>
                ) : candidates === null ? (
                    <p className="text-muted-foreground text-sm">{t('reports.loading')}</p>
                ) : (
                    <CandidatesTable candidates={candidates} />
                )}
                <DialogFooter>
                    <Button
                        variant="outline"
                        className="rounded-full"
                        disabled={!candidates || candidates.length === 0}
                        onClick={() =>
                            candidates &&
                            exportSheetsToExcel([{ name: row.code, rows: candidateSheetRows(candidates, t) }], `Candidates_${row.code}_${month}`)
                        }
                    >
                        <FileSpreadsheet className="h-4 w-4" />
                        {t('reports.export')}
                    </Button>
                    <Button onClick={onClose} className="rounded-full">
                        {t('reports.close')}
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}

export default function ReportsIndex() {
    const { month, rows, practice, totals } = usePage<PageProps>().props;
    const { t } = useTranslation();
    const [drill, setDrill] = useState<ReportRow | null>(null);

    const breadcrumbs: BreadcrumbItem[] = [{ title: t('exam_admin.nav.reports'), href: route('reports.index') }];

    const exportExcel = () => {
        const line = (name: string, code: string, status: string, candidates: number | null, mocks: number | null, ai: ReportRow['ai']) => ({
            [t('reports.columns.center')]: name,
            [t('reports.columns.code')]: code,
            [t('reports.columns.status')]: status,
            [t('reports.columns.candidates')]: candidates,
            [t('reports.columns.mocks')]: mocks,
            [`${t('reports.columns.writing_eval')} · ${t('reports.calls')}`]: ai.writing_eval.calls,
            [`${t('reports.columns.writing_eval')} · ${t('reports.tokens')}`]: ai.writing_eval.input_tokens + ai.writing_eval.output_tokens,
            [`${t('reports.columns.writing_eval')} · USD`]: ai.writing_eval.cost,
            [`${t('reports.columns.pdf_import')} · ${t('reports.calls')}`]: ai.pdf_import.calls,
            [`${t('reports.columns.pdf_import')} · ${t('reports.tokens')}`]: ai.pdf_import.input_tokens + ai.pdf_import.output_tokens,
            [`${t('reports.columns.pdf_import')} · USD`]: ai.pdf_import.cost,
            [`${t('reports.columns.other_ai')} · USD`]: ai.other.cost,
            [`${t('reports.columns.ai_total')} · ${t('reports.calls')}`]: ai.total.calls,
            [`${t('reports.columns.ai_total')} · ${t('reports.tokens')}`]: ai.total.input_tokens + ai.total.output_tokens,
            [`${t('reports.columns.ai_total')} · USD`]: ai.total.cost,
        });

        exportSheetsToExcel(
            [
                {
                    name: month,
                    rows: [
                        ...rows.map((r) =>
                            line(
                                r.name,
                                r.code,
                                r.suspended ? t('centers.status.suspended') : t('centers.status.active'),
                                r.candidates,
                                r.mocks,
                                r.ai,
                            ),
                        ),
                        line(t('reports.practice'), '—', '', null, null, practice.ai),
                        line(t('reports.totals'), '', '', totals.candidates, totals.mocks, totals.ai),
                    ],
                },
            ],
            `Mynine_report_${month}`,
        );
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('exam_admin.nav.reports')} />
            <div className="mx-auto w-full max-w-7xl p-4 md:p-6 space-y-5">
                <PageHeader
                    icon={<FileBarChart className="h-5 w-5" />}
                    title={t('exam_admin.nav.reports')}
                    description={t('reports.description')}
                    actions={
                        <>
                            <MonthPicker month={month} routeName="reports.index" />
                            <Button size="sm" variant="outline" onClick={exportExcel}>
                                <FileSpreadsheet className="h-4 w-4" />
                                {t('reports.export')}
                            </Button>
                        </>
                    }
                />

                <CountingRule />

                <Panel className="overflow-hidden p-0">
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>{t('reports.columns.center')}</TableHead>
                                <TableHead>{t('reports.columns.status')}</TableHead>
                                <TableHead className="text-right">{t('reports.columns.candidates')}</TableHead>
                                <TableHead className="text-right">{t('reports.columns.mocks')}</TableHead>
                                <TableHead>{t('reports.columns.writing_eval')}</TableHead>
                                <TableHead>{t('reports.columns.pdf_import')}</TableHead>
                                <TableHead>{t('reports.columns.ai_total')}</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {rows.map((r) => (
                                <TableRow key={r.id}>
                                    <TableCell>
                                        <TruncatedText className="text-foreground max-w-[14rem] font-bold">{r.name}</TruncatedText>
                                        <div className="text-muted-foreground font-mono text-[11px]">{r.code}</div>
                                    </TableCell>
                                    <TableCell label={t('reports.columns.status')} className="text-[11px]">
                                        <span
                                            className={cn(
                                                'inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-bold',
                                                r.suspended
                                                    ? 'bg-rose-500/12 text-rose-800 dark:bg-rose-400/15 dark:text-rose-200'
                                                    : 'bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200',
                                            )}
                                        >
                                            {r.suspended && <Lock className="h-3 w-3" />}
                                            {r.suspended ? t('centers.status.suspended') : t('centers.status.active')}
                                        </span>
                                    </TableCell>
                                    <TableCell label={t('reports.columns.candidates')} className="text-right">
                                        <button
                                            type="button"
                                            className="text-brand font-bold tabular-nums underline-offset-2 hover:underline"
                                            onClick={() => setDrill(r)}
                                            title={t('reports.drill.open')}
                                        >
                                            {fmtInt(r.candidates)}
                                        </button>
                                    </TableCell>
                                    <TableCell label={t('reports.columns.mocks')} className="text-right tabular-nums">
                                        {fmtInt(r.mocks)}
                                    </TableCell>
                                    <TableCell label={t('reports.columns.writing_eval')} className="text-xs">
                                        <AiCell part={r.ai.writing_eval} />
                                    </TableCell>
                                    <TableCell label={t('reports.columns.pdf_import')} className="text-xs">
                                        <AiCell part={r.ai.pdf_import} />
                                    </TableCell>
                                    <TableCell label={t('reports.columns.ai_total')} className="text-xs">
                                        <AiCell part={r.ai.total} />
                                    </TableCell>
                                </TableRow>
                            ))}
                            <TableRow>
                                <TableCell>
                                    <div className="text-foreground font-semibold">{t('reports.practice')}</div>
                                    <div className="text-muted-foreground text-[11px]">{t('reports.practice_hint')}</div>
                                </TableCell>
                                <TableCell label={t('reports.columns.status')} />
                                <TableCell label={t('reports.columns.candidates')} className="text-muted-foreground text-right">
                                    —
                                </TableCell>
                                <TableCell label={t('reports.columns.mocks')} className="text-muted-foreground text-right">
                                    —
                                </TableCell>
                                <TableCell label={t('reports.columns.writing_eval')} className="text-xs">
                                    <AiCell part={practice.ai.writing_eval} />
                                </TableCell>
                                <TableCell label={t('reports.columns.pdf_import')} className="text-xs">
                                    <AiCell part={practice.ai.pdf_import} />
                                </TableCell>
                                <TableCell label={t('reports.columns.ai_total')} className="text-xs">
                                    <AiCell part={practice.ai.total} />
                                </TableCell>
                            </TableRow>
                            <TableRow className="bg-indigo-500/8 font-bold">
                                <TableCell className="text-foreground font-extrabold">{t('reports.totals')}</TableCell>
                                <TableCell label={t('reports.columns.status')} />
                                <TableCell label={t('reports.columns.candidates')} className="text-right tabular-nums">
                                    {fmtInt(totals.candidates)}
                                </TableCell>
                                <TableCell label={t('reports.columns.mocks')} className="text-right tabular-nums">
                                    {fmtInt(totals.mocks)}
                                </TableCell>
                                <TableCell label={t('reports.columns.writing_eval')} className="text-xs">
                                    <AiCell part={totals.ai.writing_eval} />
                                </TableCell>
                                <TableCell label={t('reports.columns.pdf_import')} className="text-xs">
                                    <AiCell part={totals.ai.pdf_import} />
                                </TableCell>
                                <TableCell label={t('reports.columns.ai_total')} className="text-xs">
                                    <AiCell part={totals.ai.total} />
                                </TableCell>
                            </TableRow>
                        </TableBody>
                    </Table>
                </Panel>

                {totals.ai.unpriced_calls > 0 && (
                    <p className="text-muted-foreground text-xs">{t('reports.unpriced', { count: totals.ai.unpriced_calls })}</p>
                )}
            </div>
            {drill && <CandidatesDialog row={drill} month={month} onClose={() => setDrill(null)} />}
        </AppLayout>
    );
}
