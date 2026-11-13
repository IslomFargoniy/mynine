import { Link, usePage } from '@inertiajs/react';
import { Gauge, Settings2, UserCog } from 'lucide-react';
import { useTranslation } from 'react-i18next';

/** The "Center" page: settings, staff and usage are tabs of one page (their own routes, so links still work). */
export const CENTER_TAB_PATHS = ['/center/settings', '/staff', '/usage'];

export default function CenterTabs() {
    const { t } = useTranslation();
    const path = usePage().url.split('?')[0];
    const tabs = [
        { href: '/center/settings', label: t('exam_admin.nav.center_settings'), icon: Settings2 },
        { href: '/staff', label: t('exam_admin.nav.staff'), icon: UserCog },
        { href: '/usage', label: t('exam_admin.nav.usage'), icon: Gauge },
    ];

    return (
        <nav role="tablist" className="glass-subtle inline-flex max-w-full gap-1 overflow-x-auto rounded-full p-1">
            {tabs.map(({ href, label, icon: Icon }) => {
                const active = path === href || path.startsWith(href + '/');
                return (
                    <Link
                        key={href}
                        href={href}
                        role="tab"
                        aria-selected={active}
                        preserveScroll
                        className={`inline-flex shrink-0 items-center gap-1.5 rounded-full px-4 py-2 text-xs font-bold transition-colors ${
                            active ? 'btn-glass-primary' : 'text-muted-foreground hover:bg-accent hover:text-foreground'
                        }`}
                    >
                        <Icon className="h-4 w-4" />
                        {label}
                    </Link>
                );
            })}
        </nav>
    );
}
