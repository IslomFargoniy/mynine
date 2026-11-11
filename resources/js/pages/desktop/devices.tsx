import { EmptyState, fmtDateTime, inputClass, OnlineDot, PageHeader, Panel, PcNumber, useAutoRefresh } from '@/components/exam-admin/shared';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import AppLayout from '@/layouts/app-layout';
import { cn } from '@/lib/utils';
import { type BreadcrumbItem } from '@/types';
import { Head, router, usePage } from '@inertiajs/react';
import { Ban, CheckCircle2, Download, Monitor, Pencil, ShieldCheck, Trash2 } from 'lucide-react';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';

interface DeviceRow {
    id: number;
    name: string;
    number: number | null;
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
    nextNumber: number | null;
    installer: { version: string; file: string; url: string; size: number; sha256: string; available: boolean } | null;
    [key: string]: unknown;
}

const MAX_NUMBER = 999;

const validNumber = (value: string) => /^\d+$/.test(value.trim()) && Number(value) >= 1 && Number(value) <= MAX_NUMBER;

/** Approve a pending PC and give it its exam-room number (prefilled with the next free one). */
function ApproveDialog({ device, suggested, onClose }: { device: DeviceRow; suggested: number | null; onClose: () => void }) {
    const { t } = useTranslation();
    const [number, setNumber] = useState(String(device.number ?? suggested ?? ''));
    const [error, setError] = useState<string | null>(null);
    const [processing, setProcessing] = useState(false);

    const submit = () => {
        if (!validNumber(number)) {
            setError(t('exam_admin.devices.number_invalid', { max: MAX_NUMBER }));
            return;
        }
        setProcessing(true);
        router.post(
            route('desktop.devices.approve', device.id),
            { number: Number(number) },
            {
                preserveScroll: true,
                onSuccess: onClose,
                onError: (errors) => setError(errors.number ?? Object.values(errors)[0] ?? null),
                onFinish: () => setProcessing(false),
            },
        );
    };

    return (
        <Dialog open onOpenChange={(open) => !open && onClose()}>
            <DialogContent className="sm:max-w-sm">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2">
                        <CheckCircle2 className="text-brand h-5 w-5" />
                        {t('exam_admin.devices.approve_title', { name: device.name })}
                    </DialogTitle>
                    <DialogDescription className="font-mono text-xs break-all">{device.machine_id}</DialogDescription>
                </DialogHeader>
                <form
                    className="space-y-2"
                    onSubmit={(e) => {
                        e.preventDefault();
                        submit();
                    }}
                >
                    <label className="text-foreground block text-xs font-semibold" htmlFor="device-number">
                        {t('exam_admin.devices.number_label')}
                    </label>
                    <input
                        id="device-number"
                        type="number"
                        min={1}
                        max={MAX_NUMBER}
                        autoFocus
                        className={cn(inputClass, 'h-11 text-center font-mono text-lg font-black')}
                        value={number}
                        onChange={(e) => {
                            setNumber(e.target.value);
                            setError(null);
                        }}
                    />
                    <p className="text-muted-foreground text-[11px]">{t('exam_admin.devices.number_hint')}</p>
                    {error && <p className="text-destructive text-xs font-semibold">{error}</p>}
                </form>
                <DialogFooter>
                    <Button variant="outline" onClick={onClose} className="rounded-full">
                        {t('exam_admin.common.cancel')}
                    </Button>
                    <Button disabled={processing || number.trim() === ''} onClick={submit} className="rounded-full">
                        <CheckCircle2 className="h-4 w-4" />
                        {t('exam_admin.devices.approve')}
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}

/** "№" cell: click to change the number in place (Enter saves, Esc cancels). */
function NumberCell({ device }: { device: DeviceRow }) {
    const { t } = useTranslation();
    const [editing, setEditing] = useState(false);
    const [value, setValue] = useState('');
    const [error, setError] = useState<string | null>(null);

    const start = () => {
        setValue(String(device.number ?? ''));
        setError(null);
        setEditing(true);
    };

    const save = () => {
        if (value.trim() === String(device.number ?? '')) {
            setEditing(false);
            return;
        }
        if (!validNumber(value)) {
            setError(t('exam_admin.devices.number_invalid', { max: MAX_NUMBER }));
            return;
        }
        router.patch(
            route('desktop.devices.update', device.id),
            { number: Number(value) },
            {
                preserveScroll: true,
                onSuccess: () => setEditing(false),
                onError: (errors) => setError(errors.number ?? Object.values(errors)[0] ?? null),
            },
        );
    };

    if (!editing) {
        return (
            <button
                type="button"
                onClick={start}
                title={t('exam_admin.devices.number_edit')}
                className="group focus-visible:ring-ring/40 inline-flex items-center gap-1 rounded-full focus-visible:ring-2 focus-visible:outline-none"
            >
                {device.number !== null ? (
                    <PcNumber number={device.number} className="text-sm" />
                ) : (
                    <span className="text-muted-foreground px-2">—</span>
                )}
                <Pencil className="text-muted-foreground h-3 w-3 opacity-0 transition-opacity group-hover:opacity-100" />
            </button>
        );
    }

    return (
        <div className="w-20">
            <input
                type="number"
                min={1}
                max={MAX_NUMBER}
                autoFocus
                aria-label={t('exam_admin.devices.number_label')}
                className={cn(inputClass, 'h-8 px-2 text-center font-mono font-bold')}
                value={value}
                onChange={(e) => {
                    setValue(e.target.value);
                    setError(null);
                }}
                onKeyDown={(e) => {
                    if (e.key === 'Enter') save();
                    if (e.key === 'Escape') setEditing(false);
                }}
                onBlur={() => !error && save()}
            />
            {error && <div className="text-destructive mt-1 text-[10px] leading-tight font-semibold">{error}</div>}
        </div>
    );
}

export default function DevicesIndex() {
    const { devices, latestVersion, nextNumber, installer } = usePage<PageProps>().props;
    const { t } = useTranslation();
    const [approving, setApproving] = useState<DeviceRow | null>(null);

    useAutoRefresh(['devices', 'nextNumber'], 15000);

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
                    <div className="rounded-[18px] border border-amber-500/25 bg-amber-500/15 p-3 text-xs font-semibold text-amber-800 dark:text-amber-200">
                        {t('exam_admin.devices.pending', { count: pending.length })}
                    </div>
                )}

                {devices.length === 0 ? (
                    <EmptyState>{t('exam_admin.devices.empty')}</EmptyState>
                ) : (
                    <Panel className="overflow-x-auto p-0">
                        <table className="w-full text-left text-xs">
                            <thead className="bg-muted text-[10px] font-bold text-muted-foreground uppercase tracking-wide">
                                <tr>
                                    <th className="w-20 px-3 py-2.5">№</th>
                                    <th className="px-3 py-2.5">{t('exam_admin.devices.pc')}</th>
                                    <th className="px-3 py-2.5">{t('exam_admin.common.status')}</th>
                                    <th className="px-3 py-2.5">{t('exam_admin.devices.version')}</th>
                                    <th className="px-3 py-2.5">{t('exam_admin.devices.os_ip')}</th>
                                    <th className="px-3 py-2.5">{t('exam_admin.devices.last_seen')}</th>
                                    <th className="px-3 py-2.5">{t('exam_admin.devices.current_attempt')}</th>
                                    <th className="px-3 py-2.5 text-right">{t('exam_admin.common.actions')}</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-divider">
                                {devices.map((d) => (
                                    <tr key={d.id} className={cn(!d.is_approved && 'bg-amber-500/8', d.is_blocked && 'bg-rose-500/8')}>
                                        <td className="px-3 py-2.5 align-top">
                                            <NumberCell device={d} />
                                        </td>
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
                                                    <span className="rounded-full bg-emerald-500/12 px-2 py-0.5 text-[10px] font-bold text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200">
                                                        {t('exam_admin.devices.approved')}
                                                    </span>
                                                ) : (
                                                    <span className="rounded-full bg-amber-500/15 px-2 py-0.5 text-[10px] font-bold text-amber-800 dark:bg-amber-400/15 dark:text-amber-200">
                                                        {t('exam_admin.devices.pending_badge')}
                                                    </span>
                                                )}
                                                {d.is_blocked && (
                                                    <span className="rounded-full bg-rose-500/12 px-2 py-0.5 text-[10px] font-bold text-rose-800 dark:bg-rose-400/15 dark:text-rose-200">
                                                        {t('exam_admin.devices.blocked')}
                                                    </span>
                                                )}
                                            </div>
                                        </td>
                                        <td className="px-3 py-2.5 font-mono">
                                            <span className={cn(d.outdated && 'font-bold text-amber-700 dark:text-amber-300')}>{d.app_version ?? '—'}</span>
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
                                                    <Button size="sm" onClick={() => setApproving(d)} className="h-7 rounded-full bg-emerald-600 px-3 text-[11px] text-white hover:bg-emerald-700">
                                                        <CheckCircle2 className="h-3.5 w-3.5" />
                                                        {t('exam_admin.devices.approve')}
                                                    </Button>
                                                )}
                                                {d.is_blocked ? (
                                                    <Button size="sm" variant="outline" onClick={() => post('desktop.devices.unblock', d)} className="h-7 rounded-full px-2 text-[11px]">
                                                        <ShieldCheck className="h-3.5 w-3.5" />
                                                        {t('exam_admin.devices.unblock')}
                                                    </Button>
                                                ) : (
                                                    <Button
                                                        size="sm"
                                                        variant="outline"
                                                        onClick={() => confirm(t('exam_admin.devices.block_confirm', { name: d.name })) && post('desktop.devices.block', d)}
                                                        className="h-7 rounded-full px-2 text-[11px] text-rose-700 dark:text-rose-300"
                                                    >
                                                        <Ban className="h-3.5 w-3.5" />
                                                        {t('exam_admin.devices.block')}
                                                    </Button>
                                                )}
                                                <Button size="sm" variant="outline" onClick={() => rename(d)} className="h-7 rounded-full px-2" title={t('exam_admin.devices.rename')}>
                                                    <Pencil className="h-3.5 w-3.5" />
                                                </Button>
                                                <Button size="sm" variant="outline" onClick={() => remove(d)} className="h-7 rounded-full px-2 text-rose-700 dark:text-rose-300" title={t('exam_admin.common.delete')}>
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
            {approving && <ApproveDialog device={approving} suggested={nextNumber} onClose={() => setApproving(null)} />}
        </AppLayout>
    );
}
