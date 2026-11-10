import { Link, useForm } from '@inertiajs/react';
import { LoaderCircle } from 'lucide-react';
import { FormEventHandler } from 'react';
import { useTranslation } from 'react-i18next';
import { Icon } from '@iconify/react';

import InputError from '@/components/input-error';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import SocialSignIn from '@/components/auth/SocialSignIn';

type RegisterForm = {
    name: string;
    phone: string;
    email: string;
    password: string;
    password_confirmation: string;
};

export default function RegisterCard() {
    const { data, setData, post, processing, errors, reset } = useForm<Required<RegisterForm>>({
        name: '',
        phone: '',
        email: '',
        password: '',
        password_confirmation: ''
    });

    const { t } = useTranslation();

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        post(route('register'), {
            onFinish: () => reset('password', 'password_confirmation')
        });
    };

    return (
        <div className="relative w-full overflow-hidden glass-strong rounded-[28px] p-5 sm:p-6">
            <SocialSignIn />

            <form className="mt-5 flex flex-col gap-4" onSubmit={submit}>
                <div className="grid gap-3">
                    <div className="grid gap-2">
                        <Label htmlFor="name" className="text-xs font-black uppercase tracking-widest text-muted-foreground ml-1">
                            {t('register.name')}
                        </Label>
                        <Input
                            id="name"
                            type="text"
                            required
                            autoFocus
                            tabIndex={1}
                            autoComplete="name"
                            value={data.name}
                            onChange={(e) => setData('name', e.target.value)}
                            disabled={processing}
                            placeholder={t('register.name_placeholder')}
                            className="h-12 rounded-xl border border-input bg-glass-subtle focus-visible:ring-2 focus-visible:ring-ring/40 transition-all font-medium"
                        />
                        <InputError message={errors.name} />
                    </div>

                    <div className="grid gap-2">
                        <Label htmlFor="phone" className="text-xs font-black uppercase tracking-widest text-muted-foreground ml-1">
                            {t('phone')}
                        </Label>
                        <Input
                            id="phone"
                            type="number"
                            required
                            tabIndex={2}
                            autoComplete="phone"
                            value={data.phone}
                            onChange={(e) => setData('phone', e.target.value)}
                            disabled={processing}
                            placeholder={t('phone')}
                            className="h-12 rounded-xl border border-input bg-glass-subtle focus-visible:ring-2 focus-visible:ring-ring/40 transition-all font-medium"
                        />
                        <InputError message={errors.phone} />
                    </div>

                    <div className="grid gap-2">
                        <Label htmlFor="email" className="text-xs font-black uppercase tracking-widest text-muted-foreground ml-1">
                            {t('register.email')}
                        </Label>
                        <Input
                            id="email"
                            type="email"
                            tabIndex={3}
                            autoComplete="email"
                            value={data.email}
                            onChange={(e) => setData('email', e.target.value)}
                            disabled={processing}
                            placeholder={t('register.email_placeholder')}
                            className="h-12 rounded-xl border border-input bg-glass-subtle focus-visible:ring-2 focus-visible:ring-ring/40 transition-all font-medium"
                        />
                        <InputError message={errors.email} />
                    </div>

                    <div className="grid gap-2">
                        <Label htmlFor="password" className="text-xs font-black uppercase tracking-widest text-muted-foreground ml-1">
                            {t('register.password')}
                        </Label>
                        <Input
                            id="password"
                            type="password"
                            required
                            tabIndex={4}
                            autoComplete="new-password"
                            value={data.password}
                            onChange={(e) => setData('password', e.target.value)}
                            disabled={processing}
                            placeholder={t('register.password_placeholder')}
                            className="h-12 rounded-xl border border-input bg-glass-subtle focus-visible:ring-2 focus-visible:ring-ring/40 transition-all font-medium"
                        />
                        <InputError message={errors.password} />
                    </div>

                    <div className="grid gap-2">
                        <Label htmlFor="password_confirmation" className="text-xs font-black uppercase tracking-widest text-muted-foreground ml-1">
                            {t('register.password_confirmation')}
                        </Label>
                        <Input
                            id="password_confirmation"
                            type="password"
                            required
                            tabIndex={5}
                            autoComplete="new-password"
                            value={data.password_confirmation}
                            onChange={(e) => setData('password_confirmation', e.target.value)}
                            disabled={processing}
                            placeholder={t('register.password_confirmation_placeholder')}
                            className="h-12 rounded-xl border border-input bg-glass-subtle focus-visible:ring-2 focus-visible:ring-ring/40 transition-all font-medium"
                        />
                        <InputError message={errors.password_confirmation} />
                    </div>

                    <button
                        type="submit"
                        className="btn-glass-primary relative mt-4 h-12 w-full overflow-hidden rounded-full font-black tracking-tight transition-all hover:brightness-110 active:scale-[0.98] disabled:opacity-50"
                        tabIndex={6}
                        disabled={processing}
                    >
                        <div className="relative flex items-center justify-center gap-2">
                            {processing ? (
                                <LoaderCircle className="h-5 w-5 animate-spin" />
                            ) : (
                                <>
                                    <span>{t('register.submit')}</span>
                                    <Icon icon="solar:user-plus-bold-duotone" className="text-xl" />
                                </>
                            )}
                        </div>
                    </button>
                </div>

                <div className="text-center text-sm font-semibold">
                    <span className="text-muted-foreground">{t('register.no_account')} </span>
                    <Link href={route('login')} className="text-brand font-bold hover:underline transition-all underline-offset-4">
                        {t('register.login')}
                    </Link>
                </div>
            </form>
        </div>
    );
}
