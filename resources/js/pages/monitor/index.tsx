import { EmptyState, fmtDateTime, fmtSeconds, ModuleBadge, OnlineDot, PageHeader, Panel, PcNumber, postJson, selectClass, useAutoRefresh } from '@/components/exam-admin/shared';
import { Button } from '@/components/ui/button';
import AppLayout from '@/layouts/app-layout';
import { cn } from '@/lib/utils';
import { type BreadcrumbItem } from '@/types';
import { Head, router, usePage } from '@inertiajs/react';
import { Activity, ChevronDown, ChevronUp, Clock, MonitorOff, Pause, Play, Plus, Send, ShieldAlert, Unlock } from 'lucide-react';
import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { toast } from 'sonner';

interface Violation {
    id: number;
    type: string;
    occurred_at: string | null;
    detail: Record<string, unknown> | null;
}

interface MonitorAttempt {
    id: number;
    name: string;
    code: string | null;
    device: string | null;
    device_number: number | null;
    module: string | null;
    modules_done: string[];
    time_left: number | null;
    online: boolean;
    last_heartbeat_at: string | null;
    paused: boolean;
    finished: boolean;
    unlock_requested: boolean;
    violations_count: number;
    violation_counts: Record<string, number>;
    violations: Violation[];
}

interface PageProps {
    mocks: { id: number; name: string; started_at: string; status: string; attempts_count: number }[];
    mock: { id: number; name: string } | null;
    attempts: MonitorAttempt[];
    serverTime: string;
    canControl: boolean;
    [key: string]: unknown;
}

/** Readable violation detail ("chrome.exe — closed", "2 monitors") instead of raw JSON. */
function violationDetail(detail: Record<string, unknown>, t: (key: string, options?: Record<string, unknown>) => string): string {
    const parts: string[] = [];
    if (typeof detail.process === 'string') parts.push(detail.process);
    if (typeof detail.terminated === 'boolean') parts.push(detail.terminated ? t('exam_admin.violation_detail.closed') : t('exam_admin.violation_detail.not_closed'));
    if (typeof detail.count === 'number') parts.push(t('exam_admin.violation_detail.monitors', { count: detail.count }));
    const rest = Object.entries(detail).filter(([k]) => !['process', 'terminated', 'count'].includes(k));
    if (rest.length > 0) parts.push(rest.map(([k, v]) => `${k}: ${String(v)}`).join(', '));
    return parts.join(' — ');
}

export default function MonitorIndex() {
    const { mocks, mock, attempts, canControl } = usePage<PageProps>().props;
    const { t } = useTranslation();
    const [expanded, setExpanded] = useState<number | null>(null);
    const [busy, setBusy] = useState<number | null>(null);
    const [tick, setTick] = useState(0);

    useAutoRefresh(['attempts', 'serverTime'], 5000, !!mock);

    // Local countdown between refreshes.
    useEffect(() => {
        setTick(0);
        const id = window.setInterval(() => setTick((x) => x + 1), 1000);
        return () => window.clearInterval(id);
    }, [attempts]);

    const breadcrumbs: BreadcrumbItem[] = [{ title: t('exam_admin.nav.monitor'), href: route('monitor.index') }];

    const act = async (attempt: MonitorAttempt, action: string, body: Record<string, unknown> = {}, confirmText?: string) => {
        if (confirmText && !confirm(confirmText)) return;
        setBusy(attempt.id);
        const res = await postJson<{ message?: string }>(route(`monitor.${action}`, attempt.id), body);
        setBusy(null);
        if (res.ok) toast.success(res.data.message ?? t('exam_admin.common.done'));
        else toast.error(res.data.message ?? t('exam_admin.common.error'));
        router.reload({ only: ['attempts'] });
    };

    const active = attempts.filter((a) => !a.finished);
    const online = active.filter((a) => a.online).length;

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('exam_admin.nav.monitor')} />
            <div className="mx-auto w-full max-w-7xl p-4 md:p-6 space-y-5">
                <PageHeader
                    icon={<Activity className="h-5 w-5" />}
                    title={t('exam_admin.nav.monitor')}
                    description={mock ? `${mock.name} · ${t('exam_admin.monitor.summary', { active: active.length, online, total: attempts.length })}` : undefined}
                    actions={
                        <select
                            className={`${selectClass} w-full sm:w-72`}
                            value={mock?.id ?? ''}
                            onChange={(e) => router.get(route('monitor.index'), { mock_id: e.target.value || undefined }, { preserveState: false })}
                        >
                            {mocks.length === 0 && <option value="">{t('exam_admin.monitor.no_mocks')}</option>}
                            {mocks.map((m) => (
                                <option key={m.id} value={m.id}>
                                    {m.name} · {fmtDateTime(m.started_at, 'dd.MM HH:mm')} ({m.attempts_count})
                                </option>
                            ))}
                        </select>
                    }
                />

                {!mock ? (
                    <EmptyState>{t('exam_admin.monitor.no_mocks_hint')}</EmptyState>
                ) : attempts.length === 0 ? (
                    <EmptyState>{t('exam_admin.monitor.empty_hint')}</EmptyState>
                ) : (
                    <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
                        {attempts.map((a) => {
                            const left = a.time_left === null ? null : a.paused ? a.time_left : Math.max(0, a.time_left - tick);
                            return (
                                <Panel
                                    key={a.id}
                                    className={cn(
                                        'space-y-3',
                                        a.paused && 'border-amber-500/40',
                                        !a.finished && !a.online && 'border-rose-500/30',
                                        a.finished && 'opacity-70',
                                    )}
                                >
                                    <div className="flex items-start justify-between gap-2">
                                        <div className="flex items-start gap-2">
                                            <PcNumber number={a.device_number} className="mt-0.5" />
                                            <div>
                                                <div className="font-bold text-foreground">{a.name}</div>
                                                <div className="font-mono text-[11px] text-brand">{a.code ?? `#${a.id}`}</div>
                                            </div>
                                        </div>
                                        <div className="text-right">
                                            {a.finished ? (
                                                <span className="rounded-full bg-muted px-2 py-0.5 text-[10px] font-bold text-foreground">
                                                    {t('exam_admin.monitor.finished')}
                                                </span>
                                            ) : (
                                                <OnlineDot online={a.online} label={a.online ? t('exam_admin.monitor.online') : t('exam_admin.monitor.offline')} />
                                            )}
                                            <div className="mt-0.5 text-[10px] text-muted-foreground">{a.device ?? t('exam_admin.monitor.web')}</div>
                                        </div>
                                    </div>

                                    <div className="flex flex-wrap items-center gap-2">
                                        {a.module ? <ModuleBadge type={a.module} /> : null}
                                        {a.modules_done.map((m) => (
                                            <span key={m} className="text-[10px] font-semibold text-muted-foreground line-through">
                                                {m}
                                            </span>
                                        ))}
                                        {a.paused && (
                                            <span className="rounded-full bg-amber-500/15 px-2 py-0.5 text-[10px] font-bold text-amber-800 dark:bg-amber-400/15 dark:text-amber-200">
                                                {t('exam_admin.monitor.paused')}
                                            </span>
                                        )}
                                        {a.unlock_requested && <span className="text-[10px] font-bold text-brand">{t('exam_admin.monitor.unlock_sent')}</span>}
                                        {left !== null && !a.finished && (
                                            <span className={cn('ml-auto flex items-center gap-1 font-mono text-sm font-black', left < 300 ? 'text-rose-700 dark:text-rose-300' : 'text-foreground')}>
                                                <Clock className="h-3.5 w-3.5" />
                                                {fmtSeconds(left)}
                                            </span>
                                        )}
                                    </div>

                                    <button
                                        type="button"
                                        onClick={() => setExpanded(expanded === a.id ? null : a.id)}
                                        className={cn(
                                            'flex w-full items-center justify-between rounded-[14px] px-3 py-2 text-left text-[11px] font-bold',
                                            a.violations_count > 0
                                                ? 'bg-rose-500/12 text-rose-800 dark:bg-rose-400/15 dark:text-rose-200'
                                                : 'bg-muted text-muted-foreground',
                                        )}
                                    >
                                        <span className="flex items-center gap-1.5">
                                            <ShieldAlert className="h-3.5 w-3.5" />
                                            {t('exam_admin.monitor.violations', { count: a.violations_count })}
                                            {Object.entries(a.violation_counts).map(([type, n]) => (
                                                <span key={type} className="font-normal opacity-80">
                                                    · {t(`exam_admin.violation.${type}`, { defaultValue: type })} {n}
                                                </span>
                                            ))}
                                        </span>
                                        {a.violations_count > 0 && (expanded === a.id ? <ChevronUp className="h-3.5 w-3.5" /> : <ChevronDown className="h-3.5 w-3.5" />)}
                                    </button>

                                    {expanded === a.id && a.violations.length > 0 && (
                                        <ul className="max-h-48 space-y-1 overflow-y-auto text-[11px]">
                                            {a.violations.map((v) => (
                                                <li key={v.id} className="flex gap-2 border-b border-divider pb-1">
                                                    <span className="font-mono text-muted-foreground">{fmtDateTime(v.occurred_at, 'HH:mm:ss')}</span>
                                                    <span className="font-semibold">{t(`exam_admin.violation.${v.type}`, { defaultValue: v.type })}</span>
                                                    {v.detail && <span className="truncate text-muted-foreground">{violationDetail(v.detail, t)}</span>}
                                                </li>
                                            ))}
                                        </ul>
                                    )}

                                    <div className="flex flex-wrap gap-1.5 border-t border-divider pt-3">
                                        {canControl && !a.finished && (
                                            <>
                                                {a.paused ? (
                                                    <Button size="sm" variant="outline" disabled={busy === a.id} onClick={() => act(a, 'resume')} className="h-7 rounded-full px-2 text-[11px]">
                                                        <Play className="h-3.5 w-3.5 text-emerald-700 dark:text-emerald-300" />
                                                        {t('exam_admin.monitor.resume')}
                                                    </Button>
                                                ) : (
                                                    <Button size="sm" variant="outline" disabled={busy === a.id} onClick={() => act(a, 'pause')} className="h-7 rounded-full px-2 text-[11px]">
                                                        <Pause className="h-3.5 w-3.5 text-amber-700 dark:text-amber-300" />
                                                        {t('exam_admin.monitor.pause')}
                                                    </Button>
                                                )}
                                                <Button
                                                    size="sm"
                                                    variant="outline"
                                                    disabled={busy === a.id}
                                                    className="h-7 rounded-full px-2 text-[11px]"
                                                    onClick={() => {
                                                        const minutes = Number(prompt(t('exam_admin.monitor.extra_time_prompt'), '5'));
                                                        if (minutes > 0) act(a, 'extra-time', { minutes });
                                                    }}
                                                >
                                                    <Plus className="h-3.5 w-3.5" />
                                                    {t('exam_admin.monitor.extra_time')}
                                                </Button>
                                                <Button
                                                    size="sm"
                                                    variant="outline"
                                                    disabled={busy === a.id}
                                                    className="h-7 rounded-full border-rose-500/30 px-2 text-[11px] text-rose-700 dark:text-rose-300"
                                                    onClick={() => act(a, 'force-submit', {}, t('exam_admin.monitor.force_submit_confirm', { name: a.name }))}
                                                >
                                                    <Send className="h-3.5 w-3.5" />
                                                    {t('exam_admin.monitor.force_submit')}
                                                </Button>
                                            </>
                                        )}
                                        {a.device && (
                                            <Button
                                                size="sm"
                                                variant="outline"
                                                disabled={busy === a.id}
                                                className="h-7 rounded-full px-2 text-[11px]"
                                                onClick={() => act(a, 'unlock', {}, t('exam_admin.monitor.unlock_confirm', { name: a.name }))}
                                            >
                                                <Unlock className="h-3.5 w-3.5 text-brand" />
                                                {t('exam_admin.monitor.unlock')}
                                            </Button>
                                        )}
                                        {a.device && !a.finished && (
                                            <Button
                                                size="sm"
                                                variant="outline"
                                                disabled={busy === a.id}
                                                className="h-7 rounded-full px-2 text-[11px]"
                                                title={t('exam_admin.monitor.release_device_hint')}
                                                onClick={() => act(a, 'release-device', {}, t('exam_admin.monitor.release_device_confirm', { name: a.name }))}
                                            >
                                                <MonitorOff className="h-3.5 w-3.5 text-amber-600 dark:text-amber-300" />
                                                {t('exam_admin.monitor.release_device')}
                                            </Button>
                                        )}
                                    </div>
                                </Panel>
                            );
                        })}
                    </div>
                )}
            </div>
        </AppLayout>
    );
}
