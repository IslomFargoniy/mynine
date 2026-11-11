// Components
import { Head, useForm } from '@inertiajs/react';
import { LoaderCircle } from 'lucide-react';
import { FormEventHandler } from 'react';

import InputError from '@/components/input-error';
import TextLink from '@/components/text-link';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import AuthLayout from '@/layouts/auth-layout';
import { useTranslation } from 'react-i18next';

export default function ForgotPassword({ status }: { status?: string }) {
    const { t } = useTranslation();
    const { data, setData, post, processing, errors } = useForm<Required<{ email: string }>>({
        email: '',
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        post(route('password.email'));
    };

    return (
        <AuthLayout title={t('auth_pages.forgot_title')} description={t('auth_pages.forgot_desc')}>
            <Head title={t('auth_pages.forgot_title')} />

            {status && <div className="mb-4 rounded-[18px] border border-emerald-500/25 bg-emerald-500/12 px-4 py-2 text-emerald-800 dark:text-emerald-200 text-center text-sm font-medium">{status}</div>}

            <div className="glass rounded-[28px] p-6 sm:p-8 space-y-6">
                <form onSubmit={submit}>
                    <div className="grid gap-2">
                        <Label htmlFor="email">{t('auth_pages.email_address')}</Label>
                        <Input
                            id="email"
                            type="email"
                            name="email"
                            autoComplete="off"
                            value={data.email}
                            autoFocus
                            onChange={(e) => setData('email', e.target.value)}
                            placeholder="email@example.com"
                        />

                        <InputError message={errors.email} />
                    </div>

                    <div className="my-6 flex items-center justify-start">
                        <Button className="w-full" disabled={processing}>
                            {processing && <LoaderCircle className="h-4 w-4 animate-spin" />}
                            {t('auth_pages.send_reset_link')}
                        </Button>
                    </div>
                </form>

                <div className="text-muted-foreground space-x-1 text-center text-sm">
                    <span>{t('auth_pages.return_to')}</span>
                    <TextLink href={route('login')}>{t('auth_pages.log_in')}</TextLink>
                </div>
            </div>
        </AuthLayout>
    );
}
