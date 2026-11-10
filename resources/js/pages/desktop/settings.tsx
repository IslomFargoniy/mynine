import { fmtDateTime, inputClass, PageHeader, Panel } from '@/components/exam-admin/shared';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import AppLayout from '@/layouts/app-layout';
import { type BreadcrumbItem } from '@/types';
import { Head, useForm, usePage } from '@inertiajs/react';
import { KeyRound, Settings } from 'lucide-react';
import { FormEventHandler } from 'react';
import { useTranslation } from 'react-i18next';

interface PageProps {
    exitPasswordSet: boolean;
    exitPasswordUpdatedAt: string | null;
    [key: string]: unknown;
}

export default function DesktopSettings() {
    const { exitPasswordSet, exitPasswordUpdatedAt } = usePage<PageProps>().props;
    const { t } = useTranslation();
    const { data, setData, post, processing, errors, reset } = useForm({ password: '', password_confirmation: '' });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        post(route('desktop.settings.exit-password'), { preserveScroll: true, onSuccess: () => reset() });
    };

    const breadcrumbs: BreadcrumbItem[] = [{ title: t('exam_admin.nav.settings'), href: route('desktop.settings.index') }];

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('exam_admin.nav.settings')} />
            <div className="mx-auto max-w-2xl space-y-5 p-4 md:p-6">
                <PageHeader icon={<Settings className="h-5 w-5" />} title={t('exam_admin.nav.settings')} description={t('exam_admin.settings.description')} />

                <Panel>
                    <form onSubmit={submit} className="space-y-4">
                        <div className="flex items-center gap-2">
                            <KeyRound className="h-4 w-4 text-indigo-500" />
                            <h2 className="text-sm font-black">{t('exam_admin.settings.exit_password')}</h2>
                        </div>
                        <p className="text-xs text-gray-500">
                            {exitPasswordSet
                                ? t('exam_admin.settings.exit_password_set', { date: fmtDateTime(exitPasswordUpdatedAt) })
                                : t('exam_admin.settings.exit_password_missing')}
                        </p>
                        <div>
                            <Label htmlFor="password">{t('exam_admin.settings.new_password')}</Label>
                            <input
                                id="password"
                                type="password"
                                autoComplete="new-password"
                                className={inputClass}
                                value={data.password}
                                onChange={(e) => setData('password', e.target.value)}
                            />
                            <InputError message={errors.password} />
                        </div>
                        <div>
                            <Label htmlFor="password_confirmation">{t('exam_admin.settings.confirm_password')}</Label>
                            <input
                                id="password_confirmation"
                                type="password"
                                autoComplete="new-password"
                                className={inputClass}
                                value={data.password_confirmation}
                                onChange={(e) => setData('password_confirmation', e.target.value)}
                            />
                        </div>
                        <p className="text-[11px] text-gray-400">{t('exam_admin.settings.hint')}</p>
                        <Button type="submit" disabled={processing || data.password.length < 6} className="rounded-xl bg-indigo-600 text-xs font-bold text-white hover:bg-indigo-700">
                            {t('exam_admin.common.save')}
                        </Button>
                    </form>
                </Panel>
            </div>
        </AppLayout>
    );
}
