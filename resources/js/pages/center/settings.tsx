import { CenterPasswordChip, CenterPasswordDialog, type CenterPasswordStatus } from '@/components/exam-admin/center-password-dialog';
import { DesktopBackgroundDialog, type DesktopBackground } from '@/components/exam-admin/desktop-background-dialog';
import { inputClass, PageHeader, Panel } from '@/components/exam-admin/shared';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import AppLayout from '@/layouts/app-layout';
import { cn } from '@/lib/utils';
import { type BreadcrumbItem, type CenterSummary, type SharedData } from '@/types';
import { Head, router, useForm, usePage } from '@inertiajs/react';
import { Building2, ImageIcon, KeyRound, Lock, Settings2, Trash2, Upload } from 'lucide-react';
import { FormEventHandler, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';

interface PageProps {
    center: CenterSummary;
    centerPassword: CenterPasswordStatus;
    background: DesktopBackground | null;
    [key: string]: unknown;
}

export default function CenterSettings() {
    const { center, centerPassword, background, auth } = usePage<PageProps & SharedData>().props;
    const superAdmin = auth.access?.superAdmin ?? false;
    const { t } = useTranslation();
    const [passwordOpen, setPasswordOpen] = useState(false);
    const [backgroundOpen, setBackgroundOpen] = useState(false);
    const { data, setData, post, processing, errors } = useForm<{ name: string; logo: File | null; code?: string; contract_until?: string }>({
        name: center.name,
        logo: null,
        ...(superAdmin ? { code: center.code, contract_until: center.contract_until ?? '' } : {}),
    });
    const [preview, setPreview] = useState<string | null>(null);

    useEffect(() => {
        if (!data.logo) {
            setPreview(null);
            return;
        }
        const url = URL.createObjectURL(data.logo);
        setPreview(url);
        return () => URL.revokeObjectURL(url);
    }, [data.logo]);

    const breadcrumbs: BreadcrumbItem[] = [{ title: t('exam_admin.nav.center_settings'), href: route('center.settings') }];

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        post(route('center.settings.update'), { forceFormData: true, preserveScroll: true, onSuccess: () => setData('logo', null) });
    };

    const removeLogo = () => {
        if (confirm(t('center_settings.logo_remove_confirm'))) {
            router.delete(route('center.logo.destroy'), { preserveScroll: true });
        }
    };

    const logo = preview ?? center.logo_url;

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('exam_admin.nav.center_settings')} />
            <div className="mx-auto max-w-4xl space-y-5 p-4 md:p-6">
                <PageHeader
                    icon={<Settings2 className="h-5 w-5" />}
                    title={t('exam_admin.nav.center_settings')}
                    description={t('center_settings.description')}
                />

                {center.suspended && (
                    <div className="flex items-center gap-2 rounded-[18px] border border-rose-500/25 bg-rose-500/12 p-3 text-xs font-semibold text-rose-800 dark:text-rose-200">
                        <Lock className="h-4 w-4 shrink-0" />
                        {t('center_settings.suspended')}
                    </div>
                )}

                <Panel>
                    <form onSubmit={submit} className="grid gap-5 sm:grid-cols-[auto_1fr]">
                        <div className="flex flex-col items-center gap-2">
                            <div className="glass-subtle flex h-28 w-28 items-center justify-center overflow-hidden rounded-[22px]">
                                {logo ? (
                                    <img src={logo} alt="" className="h-full w-full object-cover" />
                                ) : (
                                    <Building2 className="text-brand h-10 w-10" />
                                )}
                            </div>
                            <label className="text-brand inline-flex cursor-pointer items-center gap-1 text-[11px] font-bold">
                                <Upload className="h-3.5 w-3.5" />
                                {t('center_settings.logo_upload')}
                                <input
                                    type="file"
                                    accept="image/png,image/jpeg,image/webp"
                                    className="sr-only"
                                    onChange={(e) => setData('logo', e.target.files?.[0] ?? null)}
                                />
                            </label>
                            {center.logo_url && !preview && (
                                <button
                                    type="button"
                                    onClick={removeLogo}
                                    className="inline-flex items-center gap-1 text-[11px] font-semibold text-rose-700 dark:text-rose-300"
                                >
                                    <Trash2 className="h-3.5 w-3.5" />
                                    {t('center_settings.logo_remove')}
                                </button>
                            )}
                            <InputError message={errors.logo} className="text-xs" />
                        </div>

                        <div className="space-y-4">
                            <div className="space-y-1">
                                <Label htmlFor="center-name" className="text-xs font-semibold">
                                    {t('center_settings.name')}
                                </Label>
                                <input id="center-name" className={inputClass} value={data.name} onChange={(e) => setData('name', e.target.value)} />
                                <InputError message={errors.name} className="text-xs" />
                            </div>
                            <div className="grid gap-4 sm:grid-cols-2">
                                <div className="space-y-1">
                                    <Label htmlFor="center-code" className="text-xs font-semibold">
                                        {t('center_settings.code')}
                                    </Label>
                                    {superAdmin && !center.is_mynine ? (
                                        <input
                                            id="center-code"
                                            className={cn(inputClass, 'font-mono font-bold tracking-widest uppercase')}
                                            value={data.code ?? ''}
                                            maxLength={12}
                                            onChange={(e) => setData('code', e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, ''))}
                                        />
                                    ) : (
                                        <div className={cn(inputClass, 'flex items-center font-mono font-bold tracking-widest opacity-80')}>
                                            {center.code}
                                        </div>
                                    )}
                                    <p className="text-muted-foreground text-[11px]">
                                        {superAdmin && center.is_mynine ? t('center_settings.code_mynine_fixed') : t('center_settings.code_hint')}
                                    </p>
                                    <InputError message={errors.code} className="text-xs" />
                                </div>
                                <div className="space-y-1">
                                    <Label htmlFor="center-contract" className="text-xs font-semibold">
                                        {t('center_settings.contract')}
                                    </Label>
                                    {superAdmin ? (
                                        <input
                                            id="center-contract"
                                            type="date"
                                            className={inputClass}
                                            value={data.contract_until ?? ''}
                                            onChange={(e) => setData('contract_until', e.target.value)}
                                        />
                                    ) : (
                                        <div className={cn(inputClass, 'flex items-center opacity-80')}>
                                            {center.contract_until ?? t('centers.no_contract')}
                                        </div>
                                    )}
                                    {superAdmin && <p className="text-muted-foreground text-[11px]">{t('center_settings.contract_hint')}</p>}
                                    <InputError message={errors.contract_until} className="text-xs" />
                                </div>
                            </div>
                            <div className="flex justify-end">
                                <Button type="submit" disabled={processing || center.suspended} className="rounded-full text-xs font-bold">
                                    {t('exam_admin.common.save')}
                                </Button>
                            </div>
                        </div>
                    </form>
                </Panel>

                <Panel className="space-y-3">
                    <h2 className="text-foreground text-sm font-bold">{t('center_settings.desktop_title')}</h2>
                    <p className="text-muted-foreground text-xs">{t('center_settings.desktop_hint', { code: center.code })}</p>
                    <div className="flex flex-wrap items-center gap-2">
                        <CenterPasswordChip status={centerPassword} onClick={() => setPasswordOpen(true)} />
                        <Button size="sm" variant="outline" onClick={() => setPasswordOpen(true)}>
                            <KeyRound className="h-4 w-4" />
                            {t('exam_admin.settings.exit_password')}
                        </Button>
                        <Button size="sm" variant="outline" onClick={() => setBackgroundOpen(true)}>
                            <ImageIcon className="h-4 w-4" />
                            {t('exam_admin.background.title')}
                        </Button>
                    </div>
                </Panel>
            </div>
            <CenterPasswordDialog status={centerPassword} open={passwordOpen} onOpenChange={setPasswordOpen} />
            <DesktopBackgroundDialog background={background} open={backgroundOpen} onOpenChange={setBackgroundOpen} />
        </AppLayout>
    );
}
