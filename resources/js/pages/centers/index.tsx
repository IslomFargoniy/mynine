import { EmptyState, fmtDateTime, inputClass, PageHeader, Panel } from '@/components/exam-admin/shared';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { IconAction } from '@/components/ui/icon-action';
import { Label } from '@/components/ui/label';
import { MoreActions } from '@/components/ui/more-actions';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow, TruncatedText } from '@/components/ui/table';
import AppLayout from '@/layouts/app-layout';
import { cn } from '@/lib/utils';
import { type BreadcrumbItem, type CenterSummary } from '@/types';
import { Head, router, useForm, usePage } from '@inertiajs/react';
import { ArrowRightLeft, Building2, CheckCircle2, History, Lock, Pencil, Plus, UserRoundCog } from 'lucide-react';
import { FormEventHandler, useState } from 'react';
import { useTranslation } from 'react-i18next';

interface CenterRow extends CenterSummary {
    admin: { id: number | null; name: string | null; email: string | null; phone: string | null; telegram: boolean; google: boolean };
    counts: { mocks: number; candidates: number; attempts: number; devices: number; staff: number };
}

interface AuditRow {
    id: number;
    center_id: number | null;
    action: string;
    old_email: string | null;
    new_email: string | null;
    actor: string | null;
    created_at: string | null;
}

interface PageProps {
    centers: CenterRow[];
    activeCenterId: number | null;
    audit: AuditRow[];
    [key: string]: unknown;
}

function Field({ id, label, error, children }: { id: string; label: string; error?: string; children: React.ReactNode }) {
    return (
        <div className="space-y-1">
            <Label htmlFor={id} className="text-xs font-semibold">
                {label}
            </Label>
            {children}
            <InputError message={error} className="text-xs" />
        </div>
    );
}

/** Create a center (= its Admin user) or edit one. */
function CenterFormDialog({ center, onClose }: { center: CenterRow | null; onClose: () => void }) {
    const { t } = useTranslation();
    const editing = center !== null;
    const { data, setData, post, patch, processing, errors } = useForm({
        name: center?.name ?? '',
        code: center?.code ?? '',
        admin_name: center?.admin.name ?? '',
        email: '',
        password: '',
        contract_until: center?.contract_until ?? '',
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        const options = { preserveScroll: true, onSuccess: onClose };
        if (editing) {
            patch(route('centers.update', center.id), options);
        } else {
            post(route('centers.store'), options);
        }
    };

    return (
        <Dialog open onOpenChange={(open) => !open && onClose()}>
            <DialogContent className="sm:max-w-lg">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2">
                        <Building2 className="text-brand h-5 w-5" />
                        {editing ? t('centers.form.edit_title', { name: center.name }) : t('centers.form.create_title')}
                    </DialogTitle>
                    <DialogDescription className="text-xs">{t('centers.form.description')}</DialogDescription>
                </DialogHeader>
                <form id="center-form" onSubmit={submit} className="grid gap-3 sm:grid-cols-2" autoComplete="off">
                    <Field id="center-name" label={t('centers.form.name')} error={errors.name}>
                        <input id="center-name" className={inputClass} value={data.name} onChange={(e) => setData('name', e.target.value)} />
                    </Field>
                    <Field id="center-code" label={t('centers.form.code')} error={errors.code}>
                        <input
                            id="center-code"
                            className={cn(inputClass, 'font-mono uppercase')}
                            maxLength={12}
                            value={data.code}
                            onChange={(e) => setData('code', e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, ''))}
                        />
                    </Field>
                    <Field id="center-admin-name" label={t('centers.form.admin_name')} error={errors.admin_name}>
                        <input id="center-admin-name" className={inputClass} value={data.admin_name} onChange={(e) => setData('admin_name', e.target.value)} />
                    </Field>
                    <Field id="center-contract" label={t('centers.form.contract_until')} error={errors.contract_until}>
                        <input
                            id="center-contract"
                            type="date"
                            className={inputClass}
                            value={data.contract_until}
                            onChange={(e) => setData('contract_until', e.target.value)}
                        />
                    </Field>
                    {!editing && (
                        <>
                            <Field id="center-email" label={t('centers.form.email')} error={errors.email}>
                                <input id="center-email" type="email" className={inputClass} value={data.email} onChange={(e) => setData('email', e.target.value)} />
                            </Field>
                            <Field id="center-password" label={t('centers.form.password')} error={errors.password}>
                                <input
                                    id="center-password"
                                    type="password"
                                    autoComplete="new-password"
                                    className={inputClass}
                                    value={data.password}
                                    onChange={(e) => setData('password', e.target.value)}
                                />
                            </Field>
                            <p className="text-muted-foreground text-[11px] sm:col-span-2">{t('centers.form.password_hint')}</p>
                        </>
                    )}
                    <p className="text-muted-foreground text-[11px] sm:col-span-2">{t('centers.form.code_hint')}</p>
                </form>
                <DialogFooter>
                    <Button variant="outline" onClick={onClose} className="rounded-full">
                        {t('exam_admin.common.cancel')}
                    </Button>
                    <Button type="submit" form="center-form" disabled={processing} className="rounded-full">
                        <CheckCircle2 className="h-4 w-4" />
                        {t('exam_admin.common.save')}
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}

/** Hand the center's Admin account to another person (new email; old logins and sessions end). */
function ReplaceAdminDialog({ center, onClose }: { center: CenterRow; onClose: () => void }) {
    const { t } = useTranslation();
    const { data, setData, post, processing, errors } = useForm({ email: '', name: '' });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        if (!confirm(t('centers.replace.confirm', { name: center.name, email: data.email }))) return;
        post(route('centers.replace-admin', center.id), { preserveScroll: true, onSuccess: onClose });
    };

    return (
        <Dialog open onOpenChange={(open) => !open && onClose()}>
            <DialogContent className="sm:max-w-md">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2">
                        <UserRoundCog className="text-brand h-5 w-5" />
                        {t('centers.replace.title', { name: center.name })}
                    </DialogTitle>
                    <DialogDescription className="text-xs">{t('centers.replace.description', { email: center.admin.email ?? '—' })}</DialogDescription>
                </DialogHeader>
                <form id="replace-form" onSubmit={submit} className="space-y-3" autoComplete="off">
                    <Field id="replace-email" label={t('centers.replace.email')} error={errors.email}>
                        <input id="replace-email" type="email" className={inputClass} value={data.email} onChange={(e) => setData('email', e.target.value)} />
                    </Field>
                    <Field id="replace-name" label={t('centers.replace.name')} error={errors.name}>
                        <input id="replace-name" className={inputClass} value={data.name} onChange={(e) => setData('name', e.target.value)} />
                    </Field>
                    <ul className="text-muted-foreground list-disc space-y-0.5 pl-4 text-[11px]">
                        <li>{t('centers.replace.effect_logins')}</li>
                        <li>{t('centers.replace.effect_sessions')}</li>
                        <li>{t('centers.replace.effect_data')}</li>
                        <li>{t('centers.replace.effect_existing')}</li>
                    </ul>
                </form>
                <DialogFooter>
                    <Button variant="outline" onClick={onClose} className="rounded-full">
                        {t('exam_admin.common.cancel')}
                    </Button>
                    <Button type="submit" form="replace-form" disabled={processing || data.email.trim() === ''} className="rounded-full">
                        {t('centers.replace.submit')}
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}

function StatusBadge({ center }: { center: CenterRow }) {
    const { t } = useTranslation();
    const expired = center.status === 'active' && center.suspended;

    return (
        <span
            className={cn(
                'inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-bold',
                center.suspended
                    ? 'bg-rose-500/12 text-rose-800 dark:bg-rose-400/15 dark:text-rose-200'
                    : 'bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200',
            )}
        >
            {center.suspended && <Lock className="h-3 w-3" />}
            {expired ? t('centers.status.expired') : t(`centers.status.${center.status}`)}
        </span>
    );
}

export default function CentersIndex() {
    const { centers, activeCenterId, audit } = usePage<PageProps>().props;
    const { t } = useTranslation();
    const [editing, setEditing] = useState<CenterRow | null | undefined>(undefined);
    const [replacing, setReplacing] = useState<CenterRow | null>(null);

    const breadcrumbs: BreadcrumbItem[] = [{ title: t('exam_admin.nav.centers'), href: route('centers.index') }];
    const nameOf = (id: number | null) => centers.find((c) => c.id === id)?.name ?? '—';

    const setStatus = (center: CenterRow, status: 'active' | 'suspended') => {
        const key = status === 'suspended' ? 'centers.suspend_confirm' : 'centers.activate_confirm';
        if (confirm(t(key, { name: center.name }))) {
            router.post(route('centers.status', center.id), { status }, { preserveScroll: true });
        }
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('exam_admin.nav.centers')} />
            <div className="mx-auto w-full max-w-7xl p-4 md:p-6 space-y-5">
                <PageHeader
                    icon={<Building2 className="h-5 w-5" />}
                    title={t('exam_admin.nav.centers')}
                    description={t('centers.description', { count: centers.length })}
                    actions={
                        <Button size="sm" onClick={() => setEditing(null)}>
                            <Plus className="h-4 w-4" />
                            {t('centers.create')}
                        </Button>
                    }
                />

                {centers.length === 0 ? (
                    <EmptyState>{t('centers.empty')}</EmptyState>
                ) : (
                    <Panel className="overflow-hidden p-0">
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead>{t('centers.columns.center')}</TableHead>
                                    <TableHead>{t('centers.columns.admin')}</TableHead>
                                    <TableHead>{t('exam_admin.common.status')}</TableHead>
                                    <TableHead className="hidden lg:table-cell">{t('centers.columns.counts')}</TableHead>
                                    <TableHead className="w-px">
                                        <span className="sr-only">{t('exam_admin.common.actions')}</span>
                                    </TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {centers.map((c) => {
                                    const active = c.id === activeCenterId;
                                    return (
                                        <TableRow key={c.id} className={cn(active && 'bg-indigo-500/8')}>
                                            <TableCell>
                                                <div className="flex items-center gap-2.5">
                                                    {c.logo_url ? (
                                                        <img src={c.logo_url} alt="" className="h-9 w-9 shrink-0 rounded-[12px] object-cover" />
                                                    ) : (
                                                        <span className="text-brand flex h-9 w-9 shrink-0 items-center justify-center rounded-[12px] bg-indigo-500/12">
                                                            <Building2 className="h-4 w-4" />
                                                        </span>
                                                    )}
                                                    <div className="min-w-0">
                                                        <TruncatedText className="text-foreground max-w-[14rem] font-bold">{c.name}</TruncatedText>
                                                        <div className="text-muted-foreground font-mono text-[11px]">
                                                            {c.code}
                                                            {active && <span className="text-brand ml-1.5 font-sans font-bold">· {t('centers.badge.active')}</span>}
                                                        </div>
                                                    </div>
                                                </div>
                                            </TableCell>
                                            <TableCell label={t('centers.columns.admin')} className="text-[11px]">
                                                <div className="text-foreground font-semibold">{c.admin.name ?? '—'}</div>
                                                <TruncatedText className="text-muted-foreground max-w-[14rem]">{c.admin.email ?? '—'}</TruncatedText>
                                                <div className="text-muted-foreground mt-0.5 flex gap-1.5">
                                                    {c.admin.google && <span>Google</span>}
                                                    {c.admin.telegram && <span>Telegram</span>}
                                                </div>
                                            </TableCell>
                                            <TableCell label={t('exam_admin.common.status')} className="text-[11px]">
                                                <StatusBadge center={c} />
                                                <div className="text-muted-foreground mt-1">
                                                    {c.contract_until ? t('centers.contract_until', { date: c.contract_until }) : t('centers.no_contract')}
                                                </div>
                                            </TableCell>
                                            <TableCell label={t('centers.columns.counts')} className="text-muted-foreground hidden text-[11px] lg:table-cell">
                                                {t('centers.counts', c.counts)}
                                            </TableCell>
                                            <TableCell className="max-md:border-divider max-md:border-t max-md:pt-2">
                                                <div className="flex items-center justify-end gap-0.5">
                                                    {!active && (
                                                        <IconAction label={t('centers.switch')} tone="brand" onClick={() => router.post(route('centers.switch', c.id))}>
                                                            <ArrowRightLeft />
                                                        </IconAction>
                                                    )}
                                                    <IconAction label={t('centers.edit')} onClick={() => setEditing(c)}>
                                                        <Pencil />
                                                    </IconAction>
                                                    <MoreActions
                                                        items={[
                                                            {
                                                                label: t('centers.replace.action'),
                                                                icon: <UserRoundCog className="h-4 w-4" />,
                                                                onSelect: () => setReplacing(c),
                                                                hidden: c.is_mynine,
                                                            },
                                                            {
                                                                label: t('centers.suspend'),
                                                                icon: <Lock className="h-4 w-4" />,
                                                                onSelect: () => setStatus(c, 'suspended'),
                                                                danger: true,
                                                                hidden: c.is_mynine || c.status === 'suspended',
                                                            },
                                                            {
                                                                label: t('centers.activate'),
                                                                icon: <CheckCircle2 className="h-4 w-4" />,
                                                                onSelect: () => setStatus(c, 'active'),
                                                                hidden: c.status !== 'suspended',
                                                            },
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

                {audit.length > 0 && (
                    <Panel>
                        <h2 className="text-foreground mb-3 flex items-center gap-2 text-sm font-bold">
                            <History className="text-brand h-4 w-4" />
                            {t('centers.audit.title')}
                        </h2>
                        <ul className="divide-divider divide-y text-[11px]">
                            {audit.map((row) => (
                                <li key={row.id} className="flex flex-wrap items-center gap-x-3 gap-y-0.5 py-1.5">
                                    <span className="text-muted-foreground tabular-nums">{fmtDateTime(row.created_at)}</span>
                                    <span className="text-foreground font-semibold">{t(`centers.audit.actions.${row.action}`, { defaultValue: row.action })}</span>
                                    <span>{nameOf(row.center_id)}</span>
                                    {(row.old_email || row.new_email) && (
                                        <span className="text-muted-foreground font-mono">
                                            {row.old_email ?? '—'} → {row.new_email ?? '—'}
                                        </span>
                                    )}
                                    {row.actor && <span className="text-muted-foreground">({row.actor})</span>}
                                </li>
                            ))}
                        </ul>
                    </Panel>
                )}
            </div>
            {editing !== undefined && <CenterFormDialog center={editing} onClose={() => setEditing(undefined)} />}
            {replacing && <ReplaceAdminDialog center={replacing} onClose={() => setReplacing(null)} />}
        </AppLayout>
    );
}
