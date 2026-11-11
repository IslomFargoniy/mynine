import { SidebarGroup, SidebarGroupLabel, SidebarMenu, SidebarMenuButton, SidebarMenuItem } from '@/components/ui/sidebar';
import { type NavItem } from '@/types';
import { router, usePage } from '@inertiajs/react';
import { useEffect, useLayoutEffect, useRef } from 'react';
import { useTranslation } from 'react-i18next';

export function NavMain({ items = [], label }: { items: NavItem[]; label?: string }) {
    const { t } = useTranslation();
    const page = usePage();
    const activeRef = useRef<HTMLLIElement | null>(null);

    // Inertia re-mounts the sidebar on every visit, which resets its scroll to the top. Keep the
    // position the user left it at (saved per tab), and only scroll the active item into view when it
    // would otherwise be hidden — never jump the menu around on a normal click.
    useLayoutEffect(() => {
        const el = document.querySelector<HTMLElement>('[data-sidebar-scroll]');
        if (!el || el.dataset.restored) return;
        el.dataset.restored = '1';
        try {
            el.scrollTop = Number(sessionStorage.getItem('sidebar-scroll') ?? 0);
        } catch {
            /* storage unavailable */
        }
        const save = () => {
            try {
                sessionStorage.setItem('sidebar-scroll', String(el.scrollTop));
            } catch {
                /* storage unavailable */
            }
        };
        el.addEventListener('scroll', save, { passive: true });
    }, []);

    useEffect(() => {
        const item = activeRef.current;
        const el = document.querySelector<HTMLElement>('[data-sidebar-scroll]');
        if (!item || !el) return;
        const box = el.getBoundingClientRect();
        const r = item.getBoundingClientRect();
        if (r.top < box.top || r.bottom > box.bottom) {
            item.scrollIntoView({ block: 'nearest' });
        }
    }, [page.url]);

    return (
        <SidebarGroup className="px-3 py-0">
            <SidebarGroupLabel className="text-[11px] font-bold uppercase tracking-[0.08em] text-muted-foreground mb-0.5 h-7 px-3">
                {label ?? t('sidebar.platform')}
            </SidebarGroupLabel>
            <SidebarMenu className="gap-0.5">
                {items.map((item) => {
                    const path = page.url.split('?')[0];
                    const isActive = path === item.href || path.startsWith(item.href + '/') || (item.href === '/dashboard' && page.url === '/');

                    return (
                        <SidebarMenuItem key={item.title} ref={isActive ? activeRef : undefined}>
                            <SidebarMenuButton
                                isActive={isActive}
                                tooltip={{ children: item.title }}
                                onClick={() => router.visit(item.href)}
                                className={`
                                    group flex h-9 items-center gap-3 rounded-[12px] px-3 transition-colors duration-200
                                    ${isActive
                                        ? 'font-semibold'
                                        : 'text-foreground hover:bg-glass-subtle'
                                    }
                                `}
                            >
                                {item.icon && (
                                    <item.icon className={`
                                        size-4.5
                                        ${isActive ? 'text-glass-active' : 'text-muted-foreground group-hover:text-foreground'}
                                    `} />
                                )}
                                <span className="text-sm">{item.title}</span>
                            </SidebarMenuButton>
                        </SidebarMenuItem>
                    );
                })}
            </SidebarMenu>
        </SidebarGroup>
    );
}
