import { EmptyState, fmtDateTime, OnlineDot, PageHeader, Panel, useAutoRefresh } from '@/components/exam-admin/shared';
import { Button } from '@/components/ui/button';
import AppLayout from '@/layouts/app-layout';
import { cn } from '@/lib/utils';
import { type BreadcrumbItem } from '@/types';
import { Head, router, usePage } from '@inertiajs/react';
import { Ban, CheckCircle2, Download, Monitor, Pencil, ShieldCheck, Trash2 } from 'lucide-react';
import { useTranslation } from 'react-i18next';

interface DeviceRow {
    id: number;
    name: string;
    machine_id: string;
    is_approved: boolean;
    approved_at: string | null;
    is_blocked: boolean;
    app_version: string | null;
    outdated: boolean;
    os_version: string | null;
    ip: string | null;
    last_seen_at: string | null;
    online: boolean;
    current_attempt: { id: number; name: string; mock: string | null } | null;
    created_at: string | null;
}

interface PageProps {
    devices: DeviceRow[];
    latestVersion: string | null;
    installer: { version: string; file: string; url: string; size: number; sha256: string; available: boolean } | null;
    [key: string]: unknown;
}

export default function DevicesIndex() {
    const { devices, latestVersion, installer } = usePage<PageProps>().props;
    const { t } = useTranslation();

    useAutoRefresh(['devices'], 15000);

    const breadcrumbs: BreadcrumbItem[] = [{ title: t('exam_admin.nav.devices'), href: route('desktop.devices.index') }];
    const pending = devices.filter((d) => !d.is_approved);

    const post = (name: string, device: DeviceRow) => router.post(route(name, device.id), {}, { preserveScroll: true });

    const rename = (device: DeviceRow) => {
        const name = prompt(t('exam_admin.devices.rename_prompt'), device.name);
        if (name && name.trim() && name !== device.name) {
            router.patch(route('desktop.devices.update', device.id), { name: name.trim() }, { preserveScroll: true });
        }
    };

    const remove = (device: DeviceRow) => {
        if (confirm(t('exam_admin.devices.delete_confirm', { name: device.name }))) {
            router.delete(route('desktop.devices.destroy', device.id), { preserveScroll: true });
        }
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('exam_admin.nav.devices')} />
            <div className="mx-auto max-w-7xl space-y-5 p-4 md:p-6">
                <PageHeader
                    icon={<Monitor className="h-5 w-5" />}
                    title={t('exam_admin.nav.devices')}
                    description={t('exam_admin.devices.description', {
                        total: devices.length,
                        online: devices.filter((d) => d.online).length,
                        latest: latestVersion ?? '—',
                    })}
                    actions={
                        installer?.available ? (
                            <Button asChild size="sm">
                                <a href={installer.url} download>
                                    <Download className="h-4 w-4" />
                                    {t('exam_admin.devices.download_installer', { version: installer.version })}
                                    {installer.size > 0 && <span className="opacity-70">({(installer.size / 1048576).toFixed(1)} MB)</span>}
                                </a>
                            </Button>
                        ) : (
                            <span className="text-xs text-muted-foreground">{t('exam_admin.devices.installer_missing')}</span>
                        )
                    }
                />

                {installer?.available && installer.sha256 && (
                    <p className="font-mono text-[10px] break-all text-muted-foreground">SHA-256: {installer.sha256}</p>
                )}

                {pending.length > 0 && (
                    <div className="rounded-xl border border-amber-200 bg-amber-50 p-3 text-xs font-semibold text-amber-800 dark:border-amber-800/50 dark:bg-amber-950/30 dark:text-amber-300">
                        {t('exam_admin.devices.pending', { count: pending.length })}
                    </div>
                )}

                {devices.length === 0 ? (
                    <EmptyState>{t('exam_admin.devices.empty')}</EmptyState>
                ) : (
                    <Panel className="overflow-x-auto p-0">
                        <table className="w-full text-left text-xs">
                            <thead className="bg-muted text-[10px] font-bold text-muted-foreground uppercase">
                                <tr>
                                    <th className="px-3 py-2.5">{t('exam_admin.devices.pc')}</th>
                                    <th className="px-3 py-2.5">{t('exam_admin.common.status')}</th>
                                    <th className="px-3 py-2.5">{t('exam_admin.devices.version')}</th>
                                    <th className="px-3 py-2.5">{t('exam_admin.devices.os_ip')}</th>
                                    <th className="px-3 py-2.5">{t('exam_admin.devices.last_seen')}</th>
                                    <th className="px-3 py-2.5">{t('exam_admin.devices.current_attempt')}</th>
                                    <th className="px-3 py-2.5 text-right">{t('exam_admin.common.actions')}</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                                {devices.map((d) => (
                                    <tr key={d.id} className={cn(!d.is_approved && 'bg-amber-50/70 dark:bg-amber-950/20', d.is_blocked && 'bg-rose-50/60 dark:bg-rose-950/20')}>
                                        <td className="px-3 py-2.5">
                                            <div className="font-bold text-foreground">{d.name}</div>
                                            <div className="max-w-[180px] truncate font-mono text-[10px] text-muted-foreground" title={d.machine_id}>
                                                {d.machine_id}
                                            </div>
                                        </td>
                                        <td className="space-y-1 px-3 py-2.5">
                                            <OnlineDot online={d.online} label={d.online ? t('exam_admin.monitor.online') : t('exam_admin.monitor.offline')} />
                                            <div className="flex flex-wrap gap-1">
                                                {d.is_approved ? (
                                                    <span className="rounded-full bg-emerald-50 px-2 py-0.5 text-[10px] font-bold text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300">
                                                        {t('exam_admin.devices.approved')}
                                                    </span>
                                                ) : (
                                                    <span className="rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-bold text-amber-700 dark:bg-amber-900/50 dark:text-amber-300">
                                                        {t('exam_admin.devices.pending_badge')}
                                                    </span>
                                                )}
                                                {d.is_blocked && (
                                                    <span className="rounded-full bg-rose-100 px-2 py-0.5 text-[10px] font-bold text-rose-700 dark:bg-rose-900/50 dark:text-rose-300">
                                                        {t('exam_admin.devices.blocked')}
                                                    </span>
                                                )}
                                            </div>
                                        </td>
                                        <td className="px-3 py-2.5 font-mono">
                                            <span className={cn(d.outdated && 'font-bold text-amber-600 dark:text-amber-400')}>{d.app_version ?? '—'}</span>
                                        </td>
                                        <td className="px-3 py-2.5 text-[11px] text-muted-foreground">
                                            <div>{d.os_version ?? '—'}</div>
                                            <div className="font-mono">{d.ip ?? '—'}</div>
                                        </td>
                                        <td className="px-3 py-2.5 text-[11px]">{fmtDateTime(d.last_seen_at, 'dd.MM HH:mm:ss')}</td>
                                        <td className="px-3 py-2.5 text-[11px]">
                                            {d.current_attempt ? (
                                                <>
                                                    <div className="font-semibold">{d.current_attempt.name}</div>
                                                    <div className="text-muted-foreground">{d.current_attempt.mock}</div>
                                                </>
                                            ) : (
                                                '—'
                                            )}
                                        </td>
                                        <td className="px-3 py-2.5">
                                            <div className="flex justify-end gap-1">
                                                {!d.is_approved && (
                                                    <Button size="sm" onClick={() => post('desktop.devices.approve', d)} className="h-7 rounded-lg bg-emerald-600 px-2 text-[11px] text-white hover:bg-emerald-700">
                                                        <CheckCircle2 className="h-3.5 w-3.5" />
                                                        {t('exam_admin.devices.approve')}
                                                    </Button>
                                                )}
                                                {d.is_blocked ? (
                                                    <Button size="sm" variant="outline" onClick={() => post('desktop.devices.unblock', d)} className="h-7 rounded-lg px-2 text-[11px]">
                                                        <ShieldCheck className="h-3.5 w-3.5" />
                                                        {t('exam_admin.devices.unblock')}
                                                    </Button>
                                                ) : (
                                                    <Button
                                                        size="sm"
                                                        variant="outline"
                                                        onClick={() => confirm(t('exam_admin.devices.block_confirm', { name: d.name })) && post('desktop.devices.block', d)}
                                                        className="h-7 rounded-lg px-2 text-[11px] text-rose-600 dark:text-rose-400"
                                                    >
                                                        <Ban className="h-3.5 w-3.5" />
                                                        {t('exam_admin.devices.block')}
                                                    </Button>
                                                )}
                                                <Button size="sm" variant="outline" onClick={() => rename(d)} className="h-7 rounded-lg px-2" title={t('exam_admin.devices.rename')}>
                                                    <Pencil className="h-3.5 w-3.5" />
                                                </Button>
                                                <Button size="sm" variant="outline" onClick={() => remove(d)} className="h-7 rounded-lg px-2 text-rose-600 dark:text-rose-400" title={t('exam_admin.common.delete')}>
                                                    <Trash2 className="h-3.5 w-3.5" />
                                                </Button>
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
