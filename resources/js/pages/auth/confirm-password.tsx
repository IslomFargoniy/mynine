// Components
import { Head, useForm } from '@inertiajs/react';
import { LoaderCircle } from 'lucide-react';
import { FormEventHandler } from 'react';

import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import AuthLayout from '@/layouts/auth-layout';
import { useTranslation } from 'react-i18next';

export default function ConfirmPassword() {
    const { t } = useTranslation();
    const { data, setData, post, processing, errors, reset } = useForm<Required<{ password: string }>>({
        password: '',
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        post(route('password.confirm'), {
            onFinish: () => reset('password'),
        });
    };

    return (
        <AuthLayout
            title={t('auth_pages.confirm_title')}
            description={t('auth_pages.confirm_desc')}
        >
            <Head title={t('auth_pages.confirm_password')} />

            <form onSubmit={submit} className="glass rounded-[28px] p-6 sm:p-8">
                <div className="space-y-6">
                    <div className="grid gap-2">
                        <Label htmlFor="password">{t('auth_pages.password')}</Label>
                        <Input
                            id="password"
                            type="password"
                            name="password"
                            placeholder={t('auth_pages.password')}
                            autoComplete="current-password"
                            value={data.password}
                            autoFocus
                            onChange={(e) => setData('password', e.target.value)}
                        />

                        <InputError message={errors.password} />
                    </div>

                    <div className="flex items-center">
                        <Button className="w-full" disabled={processing}>
                            {processing && <LoaderCircle className="h-4 w-4 animate-spin" />}
                            {t('auth_pages.confirm_password')}
                        </Button>
                    </div>
                </div>
            </form>
        </AuthLayout>
    );
}
