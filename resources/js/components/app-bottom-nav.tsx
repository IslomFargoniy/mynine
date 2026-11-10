import { useHaptic } from '@/components/telegram-theme-provider';
import { router, usePage } from '@inertiajs/react';
import { FileText, History, Home, User } from 'lucide-react';
import { useTranslation } from 'react-i18next';

export function AppBottomNav() {
    const page = usePage();
    const { t } = useTranslation();
    const { impact } = useHaptic();

    const mainNavItems = [
        {
            title: t('sidebar.dashboard'),
            href: '/dashboard',
            icon: Home,
        },
        {
            title: t('sidebar.all_tests'),
            href: '/all-test',
            icon: FileText,
        },
        {
            title: t('sidebar.my_result'),
            href: '/attempt',
            icon: History,
        },
        {
            title: t('sidebar.profile'),
            href: '/settings/profile',
            icon: User,
        },
    ];

    return (
        <div className="fixed right-4 left-4 bottom-[calc(1.2rem+env(safe-area-inset-bottom))] z-50 md:hidden">
            <nav aria-label="Asosiy menyu" className="glass-pill flex items-center justify-around gap-1 bg-glass-strong p-1.5">
                {mainNavItems.map((item) => {
                    const isActive = page.url.startsWith(item.href);

                    return (
                        <button
                            key={item.href}
                            onClick={() => {
                                impact('light');
                                router.visit(item.href);
                            }}
                            aria-current={isActive ? 'page' : undefined}
                            className={`flex flex-1 flex-col items-center justify-center rounded-full border px-1 py-2 transition-colors duration-200 ${
                                isActive
                                    ? 'border-glass-edge bg-glass-thumb text-glass-active shadow-glass-pill'
                                    : 'border-transparent text-muted-foreground hover:text-foreground'
                            }`}
                        >
                            <item.icon size={isActive ? 20 : 22} strokeWidth={isActive ? 2.5 : 2} />
                            <span className="mt-1 text-[10px] leading-none font-bold tracking-tight">
                                {item.title}
                            </span>
                        </button>
                    );
                })}
            </nav>
        </div>
    );
}
