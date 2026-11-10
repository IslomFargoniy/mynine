import { cn } from '@/lib/utils';
import { router } from '@inertiajs/react';
import { format } from 'date-fns';
import { type ReactNode, useEffect, useRef } from 'react';
import { useTranslation } from 'react-i18next';

export const MODULE_TYPES = ['Listening', 'Reading', 'Writing'] as const;

export const moduleColor: Record<string, string> = {
    Listening: 'bg-sky-50 text-sky-700 border-sky-200 dark:bg-sky-950/40 dark:text-sky-300 dark:border-sky-800/50',
    Reading: 'bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950/40 dark:text-emerald-300 dark:border-emerald-800/50',
    Writing: 'bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950/40 dark:text-amber-300 dark:border-amber-800/50',
    Speaking: 'bg-violet-50 text-violet-700 border-violet-200 dark:bg-violet-950/40 dark:text-violet-300 dark:border-violet-800/50',
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
                'inline-flex items-center gap-1 rounded-lg border px-2 py-0.5 text-[10px] font-bold',
                moduleColor[type ?? ''] ?? 'border-gray-200 bg-gray-50 text-gray-600 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300',
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
                {icon && <div className="rounded-xl bg-indigo-50 p-2.5 text-indigo-600 dark:bg-indigo-950/40 dark:text-indigo-400">{icon}</div>}
                <div>
                    <h1 className="text-xl font-black text-gray-900 dark:text-white">{title}</h1>
                    {description && <p className="mt-0.5 text-xs text-gray-500 dark:text-gray-400">{description}</p>}
                </div>
            </div>
            {actions && <div className="flex flex-wrap items-center gap-2">{actions}</div>}
        </div>
    );
}

export function Panel({ className, children }: { className?: string; children: ReactNode }) {
    return <div className={cn('rounded-2xl border border-gray-200 bg-white p-4 shadow-xs dark:border-gray-800 dark:bg-gray-900', className)}>{children}</div>;
}

export function EmptyState({ children }: { children: ReactNode }) {
    return (
        <div className="rounded-xl border border-dashed border-gray-200 py-10 text-center text-xs text-gray-400 dark:border-gray-800">{children}</div>
    );
}

const statusTone: Record<string, string> = {
    not_arrived: 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-300',
    checked_in: 'bg-blue-50 text-blue-700 dark:bg-blue-950/40 dark:text-blue-300',
    in_exam: 'bg-indigo-50 text-indigo-700 dark:bg-indigo-950/40 dark:text-indigo-300',
    written_done: 'bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300',
    speaking_waiting: 'bg-violet-50 text-violet-700 dark:bg-violet-950/40 dark:text-violet-300',
    result_ready: 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300',
    delivered: 'bg-teal-600 text-white dark:bg-teal-700',
};

export function CandidateStatusBadge({ status, module }: { status: string; module?: string | null }) {
    const { t } = useTranslation();
    return (
        <span className={cn('inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[10px] font-bold whitespace-nowrap', statusTone[status] ?? statusTone.not_arrived)}>
            {t(`exam_admin.status.${status}`)}
            {status === 'in_exam' && module ? ` · ${module}` : ''}
        </span>
    );
}

export function OnlineDot({ online, label }: { online: boolean; label?: string }) {
    return (
        <span className="inline-flex items-center gap-1.5 text-[11px] font-semibold">
            <span className={cn('h-2 w-2 rounded-full', online ? 'animate-pulse bg-emerald-500' : 'bg-gray-300 dark:bg-gray-600')} />
            {label}
        </span>
    );
}

export const selectClass =
    'h-9 rounded-xl border border-gray-200 bg-white px-3 text-xs font-semibold text-gray-800 focus:ring-2 focus:ring-indigo-500/20 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-100';

export const inputClass =
    'h-9 w-full rounded-xl border border-gray-200 bg-white px-3 text-xs font-medium text-gray-900 focus:ring-2 focus:ring-indigo-500/20 dark:border-gray-700 dark:bg-gray-900 dark:text-white';
