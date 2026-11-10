import { Link, useForm } from '@inertiajs/react';
import { LoaderCircle } from 'lucide-react';
import { FormEventHandler } from 'react';
import { useTranslation } from 'react-i18next';
import { Icon } from '@iconify/react';

import InputError from '@/components/input-error';
import { Checkbox } from '@/components/ui/checkbox';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import SocialSignIn from '@/components/auth/SocialSignIn';

type LoginForm = {
    email_or_phone: string;
    password: string;
    remember: boolean;
};

export default function LoginCard() {
    const { data, setData, post, processing, errors, reset } = useForm<Required<LoginForm>>({
        email_or_phone: '',
        password: '',
        remember: false
    });

    const { t } = useTranslation();

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        post(route('login'), {
            onFinish: () => reset('password')
        });
    };

    return (
        <div className="group relative w-full overflow-hidden rounded-[2.5rem] bg-white/70 dark:bg-gray-900/70 backdrop-blur-xl p-5 sm:p-6 shadow-2xl transition-all duration-500 hover:shadow-primary/10 border border-white/20 dark:border-white/5">
            <SocialSignIn />

            <form className="mt-5 flex flex-col gap-4" onSubmit={submit}>
                <div className="grid gap-3">
                    <div className="grid gap-2">
                        <Label htmlFor="email_or_phone" className="text-xs font-black uppercase tracking-widest text-muted-foreground ml-1">
                            {t('login.email_or_phone')}
                        </Label>
                        <Input
                            id="email_or_phone"
                            type="text"
                            required
                            autoFocus
                            tabIndex={1}
                            autoComplete="email_or_phone"
                            value={data.email_or_phone}
                            onChange={(e) => setData('email_or_phone', e.target.value)}
                            placeholder={t('login.email_placeholder')}
                            className="h-12 rounded-2xl border-border bg-white/50 dark:bg-gray-800/50 focus:ring-2 focus:ring-primary/20 transition-all font-medium"
                        />
                        <InputError message={errors.email_or_phone} />
                    </div>

                    <div className="grid gap-2">
                        <Label htmlFor="password" className="text-xs font-black uppercase tracking-widest text-muted-foreground ml-1">
                            {t('login.password') || 'Password'}
                        </Label>
                        <Input
                            id="password"
                            type="password"
                            required
                            tabIndex={2}
                            autoComplete="current-password"
                            value={data.password}
                            onChange={(e) => setData('password', e.target.value)}
                            placeholder={t('login.password_placeholder')}
                            className="h-12 rounded-2xl border-border bg-white/50 dark:bg-gray-800/50 focus:ring-2 focus:ring-primary/20 transition-all font-medium"
                        />
                        <InputError message={errors.password} />
                    </div>

                    <div className="flex items-center justify-between px-1">
                        <div className="flex items-center space-x-3">
                            <Checkbox
                                id="remember"
                                name="remember"
                                checked={data.remember}
                                onCheckedChange={(checked) => setData('remember', checked as boolean)}
                                tabIndex={3}
                                className="rounded-md border-gray-300 dark:border-gray-600"
                            />
                            <Label htmlFor="remember" className="text-sm font-bold text-muted-foreground cursor-pointer">{t('login.remember')}</Label>
                        </div>
                    </div>

                    <button
                        type="submit"
                        className="group/btn relative mt-4 h-12 w-full overflow-hidden rounded-2xl bg-primary font-black tracking-tight text-white shadow-lg shadow-primary/20 transition-all hover:scale-[1.02] active:scale-[0.98] disabled:opacity-50"
                        tabIndex={4}
                        disabled={processing}
                    >
                        <div className="absolute inset-0 bg-gradient-to-r from-blue-600 to-purple-600 opacity-0 group-hover/btn:opacity-100 transition-opacity" />
                        <div className="relative flex items-center justify-center gap-2">
                            {processing ? (
                                <LoaderCircle className="h-5 w-5 animate-spin" />
                            ) : (
                                <>
                                    <span>{t('login.submit')}</span>
                                    <Icon icon="solar:login-bold-duotone" className="text-xl" />
                                </>
                            )}
                        </div>
                    </button>
                </div>

                <div className="text-center text-sm font-semibold">
                    <span className="text-muted-foreground">{t('login.no_account')} </span>
                    <Link href={route('register')} className="text-primary hover:underline transition-all underline-offset-4">
                        {t('login.signup')}
                    </Link>
                </div>
            </form>
        </div>
    );
}
