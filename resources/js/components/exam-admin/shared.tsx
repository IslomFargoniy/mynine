import { cn } from '@/lib/utils';
import { router } from '@inertiajs/react';
import { format } from 'date-fns';
import { type ReactNode, useEffect, useRef } from 'react';
import { useTranslation } from 'react-i18next';

export const MODULE_TYPES = ['Listening', 'Reading', 'Writing'] as const;

export const moduleColor: Record<string, string> = {
    Listening: 'bg-sky-500/12 text-sky-800 border-sky-500/25 dark:bg-sky-400/15 dark:text-sky-200 dark:border-sky-300/25',
    Reading: 'bg-emerald-500/12 text-emerald-800 border-emerald-500/25 dark:bg-emerald-400/15 dark:text-emerald-200 dark:border-emerald-300/25',
    Writing: 'bg-amber-500/15 text-amber-800 border-amber-500/25 dark:bg-amber-400/15 dark:text-amber-200 dark:border-amber-300/25',
    Speaking: 'bg-violet-500/12 text-violet-800 border-violet-500/25 dark:bg-violet-400/15 dark:text-violet-200 dark:border-violet-300/25',
};

export function fmtDateTime(value?: string | null, pattern = 'dd.MM.yyyy HH:mm'): string {
    if (!value) return '—';
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? '—' : format(date, pattern);
}

export function fmtBand(value?: number | null): string {
    return value === null || value === undefined ? '—' : Number(value).toFixed(1);
}

export function fmtSeconds(total?: number | null): string {
    if (total === null || total === undefined) return '—';
    const s = Math.max(0, Math.floor(total));
    const h = Math.floor(s / 3600);
    const m = Math.floor((s % 3600) / 60);
    const sec = s % 60;
    const mm = String(m).padStart(2, '0');
    const ss = String(sec).padStart(2, '0');
    return h > 0 ? `${h}:${mm}:${ss}` : `${mm}:${ss}`;
}

/**
 * Periodically reloads the given Inertia props (partial reload), pausing while the tab is hidden.
 */
export function useAutoRefresh(only: string[], intervalMs: number, enabled = true) {
    const onlyRef = useRef(only);
    onlyRef.current = only;

    useEffect(() => {
        if (!enabled) return;
        const id = window.setInterval(() => {
            if (document.visibilityState !== 'visible') return;
            router.reload({ only: onlyRef.current });
        }, intervalMs);
        return () => window.clearInterval(id);
    }, [intervalMs, enabled]);
}

/**
 * JSON request with the session cookie and CSRF token (for endpoints that answer JSON).
 */
export async function postJson<T = unknown>(url: string, body: Record<string, unknown> = {}): Promise<{ ok: boolean; status: number; data: T }> {
    const token = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? '';
    const response = await fetch(url, {
        method: 'POST',
        credentials: 'same-origin',
        headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': token,
            'X-Requested-With': 'XMLHttpRequest',
        },
        body: JSON.stringify(body),
    });
    const data = (await response.json().catch(() => ({}))) as T;
    return { ok: response.ok, status: response.status, data };
}

export function ModuleBadge({ type, className, children }: { type?: string | null; className?: string; children?: ReactNode }) {
    return (
        <span
            className={cn(
                'inline-flex items-center gap-1 rounded-full border px-2.5 py-0.5 text-[11px] font-bold',
                moduleColor[type ?? ''] ?? 'border-glass-edge bg-muted text-foreground',
                className,
            )}
        >
            {children ?? type}
        </span>
    );
}

export function PageHeader({ title, description, icon, actions }: { title: string; description?: string; icon?: ReactNode; actions?: ReactNode }) {
    return (
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex items-center gap-3">
                {icon && <div className="glass-subtle rounded-2xl p-2.5 text-brand">{icon}</div>}
                <div>
                    <h1 className="text-2xl font-extrabold tracking-tight text-foreground sm:text-[28px]">{title}</h1>
                    {description && <p className="mt-0.5 text-sm text-muted-foreground">{description}</p>}
                </div>
            </div>
            {actions && <div className="flex flex-wrap items-center gap-2">{actions}</div>}
        </div>
    );
}

export function Panel({ className, children }: { className?: string; children: ReactNode }) {
    // Data-heavy views (reception, monitor, speaking, writing review): near-opaque glass keeps text crisp.
    return <div className={cn('glass-strong rounded-[22px] p-4 sm:p-5', className)}>{children}</div>;
}

export function EmptyState({ children }: { children: ReactNode }) {
    return (
        <div className="rounded-[18px] border border-dashed border-glass-dash py-10 text-center text-sm text-muted-foreground">{children}</div>
    );
}

const statusTone: Record<string, string> = {
    not_arrived: 'bg-muted text-foreground border border-glass-edge',
    checked_in: 'bg-indigo-500/12 text-brand',
    in_exam: 'bg-indigo-500/12 text-brand',
    written_done: 'bg-amber-500/15 text-amber-800 dark:bg-amber-400/15 dark:text-amber-200',
    speaking_waiting: 'bg-violet-500/12 text-violet-800 dark:bg-violet-400/15 dark:text-violet-200',
    result_ready: 'bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200',
    delivered: 'bg-teal-700 text-white dark:bg-teal-600',
};

export function CandidateStatusBadge({ status, module }: { status: string; module?: string | null }) {
    const { t } = useTranslation();
    return (
        <span className={cn('inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[11px] font-bold whitespace-nowrap', statusTone[status] ?? statusTone.not_arrived)}>
            {t(`exam_admin.status.${status}`)}
            {status === 'in_exam' && module ? ` · ${module}` : ''}
        </span>
    );
}

export function OnlineDot({ online, label }: { online: boolean; label?: string }) {
    return (
        <span className="inline-flex items-center gap-1.5 text-[11px] font-semibold">
            <span className={cn('h-2 w-2 rounded-full', online ? 'animate-pulse bg-emerald-500' : 'bg-slate-400 dark:bg-slate-500')} />
            {label}
        </span>
    );
}

export const selectClass =
    'h-9 rounded-full border border-input bg-glass-subtle px-3.5 text-xs font-semibold text-foreground focus:border-ring focus:ring-2 focus:ring-ring/40';

export const inputClass =
    'h-9 w-full rounded-full border border-input bg-glass-subtle px-3.5 text-xs font-medium text-foreground focus:border-ring focus:ring-2 focus:ring-ring/40';

/** Exam-room number of a PC ("№7"); renders nothing without a number. */
export function PcNumber({ number, className }: { number?: number | null; className?: string }) {
    if (number === null || number === undefined) return null;

    return (
        <span
            className={cn(
                'glass-subtle inline-flex min-w-7 items-center justify-center rounded-full px-2 py-0.5 font-mono text-[11px] font-black text-brand tabular-nums',
                className,
            )}
        >
            №{number}
        </span>
    );
}
