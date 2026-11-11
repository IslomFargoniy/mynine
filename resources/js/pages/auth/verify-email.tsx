// Components
import { Head, useForm } from '@inertiajs/react';
import { LoaderCircle } from 'lucide-react';
import { FormEventHandler } from 'react';

import TextLink from '@/components/text-link';
import { Button } from '@/components/ui/button';
import AuthLayout from '@/layouts/auth-layout';
import { useTranslation } from 'react-i18next';

export default function VerifyEmail({ status }: { status?: string }) {
    const { t } = useTranslation();
    const { post, processing } = useForm({});

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        post(route('verification.send'));
    };

    return (
        <AuthLayout title={t('auth_pages.verify_title')} description={t('auth_pages.verify_desc')}>
            <Head title={t('auth_pages.verify_head')} />

            {status === 'verification-link-sent' && (
                <div className="mb-4 rounded-[18px] border border-emerald-500/25 bg-emerald-500/12 px-4 py-2 text-emerald-800 dark:text-emerald-200 text-center text-sm font-medium">
                    {t('auth_pages.verify_sent')}
                </div>
            )}

            <form onSubmit={submit} className="glass rounded-[28px] p-6 sm:p-8 space-y-6 text-center">
                <Button disabled={processing} variant="secondary">
                    {processing && <LoaderCircle className="h-4 w-4 animate-spin" />}
                    {t('auth_pages.resend')}
                </Button>

                <TextLink href={route('logout')} method="post" className="mx-auto block text-sm">
                    {t('auth_pages.log_out')}
                </TextLink>
            </form>
        </AuthLayout>
    );
}
