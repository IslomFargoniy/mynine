import { Head, Link, router, usePage } from '@inertiajs/react';
import { useTranslation } from 'react-i18next';



import AuthLayout from '@/layouts/auth-layout';
import LoginCard from '@/components/auth/login-card';
import {  User } from '@/types';
import { useEffect, useState } from 'react';
import SplashScreen from '@/components/splash-screen';

interface LoginProps {
    status?: string;
    canResetPassword: boolean;
}

export default function Login({ status, canResetPassword }: LoginProps) {
    const {  auth } = usePage<{
        auth: User
    }>().props;

    const [isAutoLoggingIn, setIsAutoLoggingIn] = useState(() => {
        return !!window.Telegram?.WebApp?.initDataUnsafe?.user && !auth?.user;
    });

    const { t } = useTranslation();

    useEffect(() => {
        const tg = window.Telegram?.WebApp;
        tg?.ready();
        tg?.expand();

        const user = tg?.initDataUnsafe?.user;

        // ✅ Prevent multiple login attempts if user already logged in
        if (!auth?.user && user) {
            setIsAutoLoggingIn(true);
            fetch('/webapp-login', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || ''
                },
                body: JSON.stringify({
                    initData: tg?.initData,
                    ...user
                })
            })
                .then(res => res.json())
                .then(data => {
                    if (data.success && data.redirect) {
                        router.visit(data.redirect);
                    } else {
                        setIsAutoLoggingIn(false);
                    }
                })
                .catch(err => {
                    console.error('Telegram WebApp login error:', err);
                    setIsAutoLoggingIn(false);
                });
        } else {
            setIsAutoLoggingIn(false);
        }
    }, [auth?.user]);

    if (isAutoLoggingIn) {
        return <SplashScreen />;
    }

    return (
        <AuthLayout title={t('login.title')} description={t('login.description')}>
            <Head title={t('login.submit')} />

            <LoginCard />

            <div className="mt-4 flex flex-col items-center gap-4">
                {canResetPassword && (
                    <Link
                        href={route('password.request')}
                        className="text-sm font-bold text-gray-500 hover:text-primary transition-colors duration-300 underline-offset-4 hover:underline"
                        tabIndex={5}
                    >
                        {t('login.forgot')}
                    </Link>
                )}

                {status && (
                    <div className="rounded-xl bg-green-500/10 px-4 py-2 border border-green-500/20 text-center text-sm font-bold text-green-600">
                        {t('login.status_success')}
                    </div>
                )}
            </div>
        </AuthLayout>
    );
}
