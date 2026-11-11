import { CenterPasswordChip, CenterPasswordDialog, type CenterPasswordStatus } from '@/components/exam-admin/center-password-dialog';
import { EmptyState, fmtDateTime, inputClass, OnlineDot, PageHeader, Panel, PcNumber, useAutoRefresh } from '@/components/exam-admin/shared';
import { Button } from '@/components/ui/button';
import { IconAction } from '@/components/ui/icon-action';
import { MoreActions } from '@/components/ui/more-actions';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow, TruncatedText } from '@/components/ui/table';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import AppLayout from '@/layouts/app-layout';
import { cn } from '@/lib/utils';
import { type BreadcrumbItem } from '@/types';
import { Head, router, usePage } from '@inertiajs/react';
import { Ban, CheckCircle2, Download, KeyRound, Monitor, Pencil, ShieldCheck, Trash2 } from 'lucide-react';
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
    centerPassword: CenterPasswordStatus | null;
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
    const { devices, latestVersion, nextNumber, installer, centerPassword } = usePage<PageProps>().props;
    const { t } = useTranslation();
    const [approving, setApproving] = useState<DeviceRow | null>(null);
    // /desktop/settings redirects here with ?settings=1: open the center password dialog.
    const [passwordOpen, setPasswordOpen] = useState(() => typeof window !== 'undefined' && new URLSearchParams(window.location.search).get('settings') === '1');

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
                        <>
                            {centerPassword && (
                                <Button size="sm" variant="outline" onClick={() => setPasswordOpen(true)}>
                                    <KeyRound className="h-4 w-4" />
                                    {t('exam_admin.settings.exit_password')}
                                </Button>
                            )}
                            {installer?.available ? (
                                <Button asChild size="sm">
                                    <a href={installer.url} download>
                                        <Download className="h-4 w-4" />
                                        {t('exam_admin.devices.download_installer', { version: installer.version })}
                                        {installer.size > 0 && <span className="opacity-70">({(installer.size / 1048576).toFixed(1)} MB)</span>}
                                    </a>
                                </Button>
                            ) : (
                                <span className="text-xs text-muted-foreground">{t('exam_admin.devices.installer_missing')}</span>
                            )}
                        </>
                    }
                />

                <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
                    {centerPassword && <CenterPasswordChip status={centerPassword} onClick={() => setPasswordOpen(true)} />}
                    {installer?.available && installer.sha256 && (
                        <p className="min-w-0 font-mono text-[10px] break-all text-muted-foreground">SHA-256: {installer.sha256}</p>
                    )}
                </div>

                {pending.length > 0 && (
                    <div className="rounded-[18px] border border-amber-500/25 bg-amber-500/15 p-3 text-xs font-semibold text-amber-800 dark:text-amber-200">
                        {t('exam_admin.devices.pending', { count: pending.length })}
                    </div>
                )}

                {devices.length === 0 ? (
                    <EmptyState>{t('exam_admin.devices.empty')}</EmptyState>
                ) : (
                    <Panel className="overflow-hidden p-0">
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead className="w-16">№</TableHead>
                                    <TableHead>{t('exam_admin.devices.pc')}</TableHead>
                                    <TableHead>{t('exam_admin.common.status')}</TableHead>
                                    <TableHead className="hidden lg:table-cell">
                                        {t('exam_admin.devices.version')} / {t('exam_admin.devices.os_ip')}
                                    </TableHead>
                                    <TableHead>{t('exam_admin.devices.last_seen')}</TableHead>
                                    <TableHead className="w-px">
                                        <span className="sr-only">{t('exam_admin.common.actions')}</span>
                                    </TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {devices.map((d) => {
                                    const version = (
                                        <span className={cn('font-mono', d.outdated && 'font-bold text-amber-700 dark:text-amber-300')}>
                                            v{d.app_version ?? '—'}
                                        </span>
                                    );
                                    return (
                                        <TableRow key={d.id} className={cn(!d.is_approved && 'bg-amber-500/8', d.is_blocked && 'bg-rose-500/8')}>
                                            <TableCell label="№" className="align-top">
                                                <NumberCell device={d} />
                                            </TableCell>
                                            <TableCell>
                                                <TruncatedText className="max-w-[14rem] font-bold text-foreground">{d.name}</TruncatedText>
                                                <TruncatedText className="max-w-[12rem] font-mono text-[10px] text-muted-foreground">{d.machine_id}</TruncatedText>
                                                <div className="text-[10px] text-muted-foreground lg:hidden">
                                                    {version} · {d.os_version ?? '—'} · <span className="font-mono">{d.ip ?? '—'}</span>
                                                </div>
                                            </TableCell>
                                            <TableCell label={t('exam_admin.common.status')}>
                                                <div className="space-y-1">
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
                                                </div>
                                            </TableCell>
                                            <TableCell className="hidden text-[11px] text-muted-foreground lg:table-cell">
                                                <div className="text-foreground">{version}</div>
                                                <TruncatedText className="max-w-[10rem]">{d.os_version ?? '—'}</TruncatedText>
                                                <div className="font-mono">{d.ip ?? '—'}</div>
                                            </TableCell>
                                            <TableCell label={t('exam_admin.devices.last_seen')} className="text-[11px]">
                                                <div className="whitespace-nowrap tabular-nums">{fmtDateTime(d.last_seen_at, 'dd.MM HH:mm')}</div>
                                                {d.current_attempt && (
                                                    <div className="mt-0.5" title={t('exam_admin.devices.current_attempt')}>
                                                        <TruncatedText className="max-w-[12rem] font-semibold">{d.current_attempt.name}</TruncatedText>
                                                        <TruncatedText className="max-w-[12rem] text-muted-foreground">{d.current_attempt.mock}</TruncatedText>
                                                    </div>
                                                )}
                                            </TableCell>
                                            <TableCell className="max-md:border-t max-md:border-divider max-md:pt-2">
                                                <div className="flex items-center justify-end gap-0.5">
                                                    {!d.is_approved && (
                                                        <Button size="sm" onClick={() => setApproving(d)} className="h-7 rounded-full bg-emerald-600 px-3 text-[11px] text-white hover:bg-emerald-700">
                                                            <CheckCircle2 className="h-3.5 w-3.5" />
                                                            {t('exam_admin.devices.approve')}
                                                        </Button>
                                                    )}
                                                    {d.is_blocked ? (
                                                        <IconAction label={t('exam_admin.devices.unblock')} tone="success" onClick={() => post('desktop.devices.unblock', d)}>
                                                            <ShieldCheck />
                                                        </IconAction>
                                                    ) : (
                                                        <IconAction
                                                            label={t('exam_admin.devices.block')}
                                                            tone="danger"
                                                            onClick={() => confirm(t('exam_admin.devices.block_confirm', { name: d.name })) && post('desktop.devices.block', d)}
                                                        >
                                                            <Ban />
                                                        </IconAction>
                                                    )}
                                                    <MoreActions
                                                        items={[
                                                            { label: t('exam_admin.devices.rename'), icon: <Pencil className="h-4 w-4" />, onSelect: () => rename(d) },
                                                            { label: t('exam_admin.common.delete'), icon: <Trash2 className="h-4 w-4" />, onSelect: () => remove(d), danger: true },
                                                        ]}
                                                    />
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
            {approving && <ApproveDialog device={approving} suggested={nextNumber} onClose={() => setApproving(null)} />}
            {centerPassword && <CenterPasswordDialog status={centerPassword} open={passwordOpen} onOpenChange={setPasswordOpen} />}
        </AppLayout>
    );
}
