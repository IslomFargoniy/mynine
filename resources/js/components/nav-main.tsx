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
            <SidebarGroupLabel className="text-[10px] font-bold uppercase tracking-[0.1em] text-muted-foreground mb-2 px-3">
                {label ?? t('sidebar.platform') ?? 'Platform'}
            </SidebarGroupLabel>
            <SidebarMenu className="gap-1.5">
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
                                    flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all duration-300 group
                                    ${isActive 
                                        ? 'bg-primary text-white shadow-lg shadow-primary/20 font-bold scale-[1.02] data-[active=true]:bg-primary data-[active=true]:text-white' 
                                        : 'text-muted-foreground hover:bg-gray-100 dark:hover:bg-gray-800 hover:scale-[1.01]'
                                    }
                                `}
                            >
                                {item.icon && (
                                    <item.icon className={`
                                        size-4.5 transition-transform duration-300 group-hover:scale-110
                                        ${isActive ? 'text-white! dark:text-white!' : 'text-muted-foreground group-hover:text-primary'}
                                    `} />
                                )}
                                <span className="text-[13px] tracking-tight">{item.title}</span>
                            </SidebarMenuButton>
                        </SidebarMenuItem>
                    );
                })}
            </SidebarMenu>
        </SidebarGroup>
    );
}
