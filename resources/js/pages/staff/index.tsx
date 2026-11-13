import { EmptyState, fmtDateTime, inputClass, PageHeader, Panel } from '@/components/exam-admin/shared';
import CenterTabs from '@/components/center/center-tabs';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { IconAction } from '@/components/ui/icon-action';
import { Label } from '@/components/ui/label';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow, TruncatedText } from '@/components/ui/table';
import AppLayout from '@/layouts/app-layout';
import { cn } from '@/lib/utils';
import { type BreadcrumbItem, type CenterSummary } from '@/types';
import { Head, router, useForm, usePage } from '@inertiajs/react';
import { Ban, CheckCircle2, Pencil, Plus, ShieldCheck, UserCog } from 'lucide-react';
import { FormEventHandler, useState } from 'react';
import { useTranslation } from 'react-i18next';

interface StaffRow {
    id: number;
    name: string;
    email: string | null;
    phone: string | null;
    telegram: boolean;
    suspended: boolean;
    suspended_at: string | null;
    created_at: string | null;
}

interface PageProps {
    staff: StaffRow[];
    center: CenterSummary | null;
    [key: string]: unknown;
}

/** Create or edit a Reception user of the center. */
function StaffDialog({ staff, onClose }: { staff: StaffRow | null; onClose: () => void }) {
    const { t } = useTranslation();
    const editing = staff !== null;
    const { data, setData, post, patch, processing, errors } = useForm({
        name: staff?.name ?? '',
        email: staff?.email ?? '',
        phone: staff?.phone ?? '',
        password: '',
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        const options = { preserveScroll: true, onSuccess: onClose };
        if (editing) {
            patch(route('staff.update', staff.id), options);
        } else {
            post(route('staff.store'), options);
        }
    };

    const field = (id: 'name' | 'email' | 'phone' | 'password', type = 'text') => (
        <div className="space-y-1">
            <Label htmlFor={`staff-${id}`} className="text-xs font-semibold">
                {t(`staff.form.${id}`)}
            </Label>
            <input
                id={`staff-${id}`}
                type={type}
                autoComplete={id === 'password' ? 'new-password' : 'off'}
                className={inputClass}
                value={data[id]}
                onChange={(e) => setData(id, e.target.value)}
            />
            <InputError message={errors[id]} className="text-xs" />
        </div>
    );

    return (
        <Dialog open onOpenChange={(open) => !open && onClose()}>
            <DialogContent className="sm:max-w-md">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2">
                        <UserCog className="text-brand h-5 w-5" />
                        {editing ? t('staff.form.edit_title', { name: staff.name }) : t('staff.form.create_title')}
                    </DialogTitle>
                    <DialogDescription className="text-xs">{t('staff.form.description')}</DialogDescription>
                </DialogHeader>
                <form id="staff-form" onSubmit={submit} className="space-y-3" autoComplete="off">
                    {field('name')}
                    {field('email', 'email')}
                    {field('phone')}
                    {field('password', 'password')}
                    <p className="text-muted-foreground text-[11px]">{editing ? t('staff.form.password_keep') : t('staff.form.login_hint')}</p>
                </form>
                <DialogFooter>
                    <Button variant="outline" onClick={onClose} className="rounded-full">
                        {t('exam_admin.common.cancel')}
                    </Button>
                    <Button type="submit" form="staff-form" disabled={processing} className="rounded-full">
                        <CheckCircle2 className="h-4 w-4" />
                        {t('exam_admin.common.save')}
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}

export default function StaffIndex() {
    const { staff, center } = usePage<PageProps>().props;
    const { t } = useTranslation();
    const [editing, setEditing] = useState<StaffRow | null | undefined>(undefined);

    const breadcrumbs: BreadcrumbItem[] = [{ title: t('exam_admin.nav.staff'), href: route('staff.index') }];

    const toggle = (row: StaffRow) => {
        if (row.suspended) {
            router.post(route('staff.activate', row.id), {}, { preserveScroll: true });
        } else if (confirm(t('staff.suspend_confirm', { name: row.name }))) {
            router.post(route('staff.suspend', row.id), {}, { preserveScroll: true });
        }
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('exam_admin.nav.staff')} />
            <div className="mx-auto w-full max-w-7xl p-4 md:p-6 space-y-5">
                <CenterTabs />
                <PageHeader
                    icon={<UserCog className="h-5 w-5" />}
                    title={t('exam_admin.nav.staff')}
                    description={t('staff.description', { center: center?.name ?? '' })}
                    actions={
                        <Button size="sm" onClick={() => setEditing(null)} disabled={center?.suspended}>
                            <Plus className="h-4 w-4" />
                            {t('staff.create')}
                        </Button>
                    }
                />

                {staff.length === 0 ? (
                    <EmptyState>{t('staff.empty')}</EmptyState>
                ) : (
                    <Panel className="overflow-hidden p-0">
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead>{t('staff.columns.name')}</TableHead>
                                    <TableHead>{t('staff.columns.login')}</TableHead>
                                    <TableHead>{t('exam_admin.common.status')}</TableHead>
                                    <TableHead className="w-px">
                                        <span className="sr-only">{t('exam_admin.common.actions')}</span>
                                    </TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {staff.map((row) => (
                                    <TableRow key={row.id} className={cn(row.suspended && 'bg-rose-500/8')}>
                                        <TableCell>
                                            <TruncatedText className="text-foreground max-w-[16rem] font-bold">{row.name}</TruncatedText>
                                            <div className="text-muted-foreground text-[10px]">{fmtDateTime(row.created_at, 'dd.MM.yyyy')}</div>
                                        </TableCell>
                                        <TableCell label={t('staff.columns.login')} className="text-[11px]">
                                            <TruncatedText className="max-w-[16rem]">{row.email ?? '—'}</TruncatedText>
                                            <div className="text-muted-foreground">{row.phone ?? ''}</div>
                                            {row.telegram && <div className="text-muted-foreground">Telegram</div>}
                                        </TableCell>
                                        <TableCell label={t('exam_admin.common.status')}>
                                            <span
                                                className={cn(
                                                    'rounded-full px-2 py-0.5 text-[10px] font-bold',
                                                    row.suspended
                                                        ? 'bg-rose-500/12 text-rose-800 dark:bg-rose-400/15 dark:text-rose-200'
                                                        : 'bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200',
                                                )}
                                            >
                                                {row.suspended ? t('staff.suspended') : t('staff.active')}
                                            </span>
                                        </TableCell>
                                        <TableCell className="max-md:border-divider max-md:border-t max-md:pt-2">
                                            <div className="flex items-center justify-end gap-0.5">
                                                <IconAction label={t('staff.edit')} onClick={() => setEditing(row)}>
                                                    <Pencil />
                                                </IconAction>
                                                <IconAction
                                                    label={row.suspended ? t('staff.activate') : t('staff.suspend')}
                                                    tone={row.suspended ? 'success' : 'danger'}
                                                    onClick={() => toggle(row)}
                                                >
                                                    {row.suspended ? <ShieldCheck /> : <Ban />}
                                                </IconAction>
                                            </div>
                                        </TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    </Panel>
                )}
            </div>
            {editing !== undefined && <StaffDialog staff={editing} onClose={() => setEditing(undefined)} />}
        </AppLayout>
    );
}
