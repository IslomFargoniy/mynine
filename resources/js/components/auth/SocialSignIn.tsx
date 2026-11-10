import React, { useEffect } from 'react';
import { Icon } from '@iconify/react';
import { useTranslation } from 'react-i18next';

const SocialSignIn = () => {
    const { t } = useTranslation();

    const signIn = (provider: string) => {
        if (provider === 'github') {
            window.location.href = route('github.redirect');
            return;
        }
        if (provider === 'google') {
            window.location.href = route('google.redirect');
            return;
        }
    };

    useEffect(() => {
        const script = document.createElement('script');
        script.src = 'https://telegram.org/js/telegram-widget.js?15';
        script.async = true;
        script.setAttribute('data-telegram-login', 'MynineUzBot');
        script.setAttribute('data-size', 'large');
        script.setAttribute('data-userpic', 'false');
        script.setAttribute('data-request-access', 'write');
        script.setAttribute('data-auth-url', 'https://mynine.uz/auth/telegram/callback');
        script.setAttribute('data-radius', '12');
        script.setAttribute('data-lang', 'en');
        script.id = 'telegram-widget';

        const container = document.getElementById('telegram-container');
        if (container) container.appendChild(script);

        return () => {
            if (container) container.innerHTML = '';
        };
    }, []);

    return (
        <div className="space-y-6">
            <div className="flex gap-4">
                <button
                    onClick={() => signIn('google')}
                    className="group relative flex w-full items-center justify-center gap-3 overflow-hidden rounded-2xl bg-card border border-border p-3.5 shadow-sm transition-all duration-300 hover:-translate-y-1 hover:shadow-xl active:scale-95"
                >
                    <div className="absolute inset-0 bg-gradient-to-tr from-blue-500/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                    <Icon icon="logos:google-icon" className="text-xl" />
                    <span className="text-sm font-bold text-foreground/80">Google</span>
                </button>

                <button
                    onClick={() => signIn('github')}
                    className="group relative flex w-full items-center justify-center gap-3 overflow-hidden rounded-2xl bg-card border border-border p-3.5 shadow-sm transition-all duration-300 hover:-translate-y-1 hover:shadow-xl active:scale-95"
                >
                    <div className="absolute inset-0 bg-gradient-to-tr from-gray-500/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                    <Icon icon="mdi:github" className="text-xl text-foreground" />
                    <span className="text-sm font-bold text-foreground/80">GitHub</span>
                </button>
            </div>

            <div className="relative flex items-center gap-4">
                <div className="h-px flex-1 bg-gray-100 dark:bg-white/5" />
                <span className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">{t('login.or') || 'OR'}</span>
                <div className="h-px flex-1 bg-gray-100 dark:bg-white/5" />
            </div>

            {/* Telegram widget container */}
            <div
                id="telegram-container"
                className="flex justify-center transition-all duration-300 hover:scale-[1.02] [&_iframe]:rounded-[12px] [&_iframe]:overflow-hidden [&_iframe]:bg-transparent"
            ></div>
        </div>
    );
};

export default SocialSignIn;
