import { SidebarGroup, SidebarGroupLabel, SidebarMenu, SidebarMenuButton, SidebarMenuItem } from '@/components/ui/sidebar';
import { type NavItem } from '@/types';
import { router, usePage } from '@inertiajs/react';
import { useEffect, useRef } from 'react';
import { useTranslation } from 'react-i18next';

export function NavMain({ items = [], label }: { items: NavItem[]; label?: string }) {
    const { t } = useTranslation();
    const page = usePage();
    const activeRef = useRef<HTMLLIElement | null>(null);

    // The sidebar menu scrolls (SidebarContent is overflow-auto) and on short screens the last
    // groups sit below the fold behind the footer; bring the active item into view on navigation.
    useEffect(() => {
        activeRef.current?.scrollIntoView({ block: 'nearest' });
    }, [page.url]);

    return (
        <SidebarGroup className="px-3 py-0">
            <SidebarGroupLabel className="text-[11px] font-bold uppercase tracking-[0.08em] text-muted-foreground mb-1 px-3">
                {label ?? t('sidebar.platform') ?? 'Platform'}
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
                                    group flex h-[42px] items-center gap-3 rounded-[14px] px-3 transition-colors duration-200
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
