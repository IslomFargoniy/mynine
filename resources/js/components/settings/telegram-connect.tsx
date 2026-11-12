import HeadingSmall from '@/components/heading-small';
import { router } from '@inertiajs/react';
import { CheckCircle2, Send } from 'lucide-react';
import { useEffect, useRef } from 'react';
import { useTranslation } from 'react-i18next';

interface TelegramWidgetUser {
    id: number;
    first_name?: string;
    last_name?: string;
    username?: string;
    photo_url?: string;
    auth_date: number;
    hash: string;
}

declare global {
    interface Window {
        onTelegramConnect?: (user: TelegramWidgetUser) => void;
    }
}

/**
 * "Connect Telegram": the Telegram Login Widget signs the user's Telegram account; the server checks the
 * signature and links it to the current user (refused when it already belongs to another account).
 */
export function TelegramConnect({ connected, bot }: { connected: boolean; bot: string }) {
    const { t } = useTranslation();
    const container = useRef<HTMLDivElement>(null);

    useEffect(() => {
        if (connected || !container.current) return;
        const el = container.current;

        window.onTelegramConnect = (user) => {
            router.post(route('profile.telegram.connect'), { ...user }, { preserveScroll: true });
        };

        const script = document.createElement('script');
        script.src = 'https://telegram.org/js/telegram-widget.js?22';
        script.async = true;
        script.setAttribute('data-telegram-login', bot);
        script.setAttribute('data-size', 'medium');
        script.setAttribute('data-userpic', 'false');
        script.setAttribute('data-radius', '12');
        script.setAttribute('data-onauth', 'onTelegramConnect(user)');
        script.setAttribute('data-request-access', 'write');
        el.appendChild(script);

        return () => {
            el.innerHTML = '';
            delete window.onTelegramConnect;
        };
    }, [connected, bot]);

    return (
        <div className="space-y-3">
            <HeadingSmall title={t('profile_settings.telegram_title')} description={t('profile_settings.telegram_description')} />
            {connected ? (
                <p className="inline-flex items-center gap-1.5 rounded-full bg-emerald-500/12 px-3 py-1 text-xs font-semibold text-emerald-800 dark:text-emerald-200">
                    <CheckCircle2 className="h-4 w-4" />
                    {t('profile_settings.telegram_connected')}
                </p>
            ) : (
                <div className="flex items-center gap-2">
                    <Send className="text-brand h-4 w-4" />
                    <div ref={container} />
                </div>
            )}
        </div>
    );
}
