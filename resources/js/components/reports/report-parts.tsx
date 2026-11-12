import { EmptyState, fmtDateTime, inputClass, Panel } from '@/components/exam-admin/shared';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { cn } from '@/lib/utils';
import { router } from '@inertiajs/react';
import { Info } from 'lucide-react';
import { useTranslation } from 'react-i18next';

export interface AiPart {
    calls: number;
    input_tokens: number;
    output_tokens: number;
    cost: number;
}

export interface AiTotals {
    writing_eval: AiPart;
    pdf_import: AiPart;
    other: AiPart;
    total: AiPart;
    unpriced_calls: number;
}

export interface ReportRow {
    id: number;
    name: string;
    code: string;
    status: 'active' | 'suspended';
    suspended: boolean;
    is_mynine: boolean;
    candidates: number;
    mocks: number;
    ai: AiTotals;
}

export interface BilledCandidate {
    /** mock_students.id when recorded (the candidate may have been deleted since) */
    id: number | null;
    name: string;
    code: string;
    mock_id: number | null;
    mock: string;
    started_at: string;
}

export const fmtInt = (n: number) => Number(n || 0).toLocaleString('en-US');

export const fmtUsd = (n: number) => {
    const v = Number(n || 0);
    return `$${v.toFixed(v > 0 && v < 1 ? 4 : 2)}`;
};

export const fmtTokens = (part: AiPart) => fmtInt(part.input_tokens + part.output_tokens);

/** "YYYY-MM" month picker that reloads the page with ?month=. */
export function MonthPicker({ month, routeName }: { month: string; routeName: string }) {
    const { t } = useTranslation();
    return (
        <label className="flex items-center gap-2 text-xs font-semibold">
            <span className="text-muted-foreground">{t('reports.month')}</span>
            <input
                type="month"
                className={cn(inputClass, 'w-40')}
                value={month}
                onChange={(e) => e.target.value && router.get(route(routeName), { month: e.target.value }, { preserveScroll: true })}
            />
        </label>
    );
}

/** How the billed candidates are counted (shown on the Reports and Usage pages). */
export function CountingRule() {
    const { t } = useTranslation();
    return (
        <Panel className="flex gap-3 text-xs">
            <Info className="text-brand mt-0.5 h-4 w-4 shrink-0" />
            <div className="space-y-1">
                <p className="text-foreground font-bold">{t('reports.rule.title')}</p>
                <p className="text-muted-foreground">{t('reports.rule.body')}</p>
                <p className="text-muted-foreground">{t('reports.rule.ai')}</p>
            </div>
        </Panel>
    );
}

export function candidateSheetRows(candidates: BilledCandidate[], t: (key: string) => string) {
    return candidates.map((c, i) => ({
        '#': i + 1,
        [t('reports.columns.candidate')]: c.name,
        [t('reports.columns.code')]: c.code,
        [t('reports.columns.mock')]: c.mock,
        [t('reports.columns.date')]: c.started_at,
    }));
}

export function CandidatesTable({ candidates }: { candidates: BilledCandidate[] }) {
    const { t } = useTranslation();
    if (candidates.length === 0) {
        return <EmptyState>{t('reports.no_candidates')}</EmptyState>;
    }

    return (
        <Table>
            <TableHeader>
                <TableRow>
                    <TableHead className="w-10">#</TableHead>
                    <TableHead>{t('reports.columns.candidate')}</TableHead>
                    <TableHead>{t('reports.columns.code')}</TableHead>
                    <TableHead>{t('reports.columns.mock')}</TableHead>
                    <TableHead>{t('reports.columns.date')}</TableHead>
                </TableRow>
            </TableHeader>
            <TableBody>
                {candidates.map((c, i) => (
                    <TableRow key={`${c.id ?? c.code}-${i}`}>
                        <TableCell className="text-muted-foreground tabular-nums">{i + 1}</TableCell>
                        <TableCell className="text-foreground font-semibold">{c.name}</TableCell>
                        <TableCell label={t('reports.columns.code')} className="font-mono text-xs">
                            {c.code}
                        </TableCell>
                        <TableCell label={t('reports.columns.mock')} className="text-xs">
                            {c.mock}
                        </TableCell>
                        <TableCell label={t('reports.columns.date')} className="text-xs tabular-nums">
                            {fmtDateTime(c.started_at)}
                        </TableCell>
                    </TableRow>
                ))}
            </TableBody>
        </Table>
    );
}
