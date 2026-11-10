import { NavFooter } from '@/components/nav-footer';
import { NavMain } from '@/components/nav-main';
import { NavUser } from '@/components/nav-user';
import {
    Sidebar,
    SidebarContent,
    SidebarFooter,
    SidebarHeader,
    SidebarMenu,
    SidebarMenuButton,
    SidebarMenuItem
} from '@/components/ui/sidebar';
import { Auth, type NavItem } from '@/types';
import { Link } from '@inertiajs/react';
import {
    Activity,
    BarChart3,
    ClipboardList,
    ConciergeBell,
    Folder,
    GithubIcon as Github,
    GraduationCap,
    LayoutDashboard,
    Library,
    Mic,
    Monitor,
    PenLine,
    Send,
    Settings,
    Users
} from 'lucide-react';
import AppLogo from './app-logo';
import { usePage } from '@inertiajs/react';
import { useMemo } from 'react';
import { useTranslation } from 'react-i18next';


export function AppSidebar() {

    const { t, i18n } = useTranslation();

    const footerNavItems: NavItem[] = [
        {
            title: t('sidebar.repository'),
            href: 'https://github.com/IslomFargoniy',
            icon: Github
        },
        {
            title: t('sidebar.telegram'),
            href: 'https://t.me/IslomFargniy',
            icon: Send
        }
    ];


    const { auth } = usePage().props as unknown as { auth?: Auth };

    const roles = auth?.user?.roles?.map((role) => role.name) ?? [];
    const isAdmin = roles.includes('Admin');
    const isReception = !isAdmin && roles.includes('Reception');

    const groups = useMemo((): { label?: string; items: NavItem[] }[] => {
        if (isReception) {
            return [
                {
                    items: [
                        { title: t('exam_admin.nav.reception'), href: '/reception', icon: ConciergeBell },
                        { title: t('exam_admin.nav.monitor'), href: '/monitor', icon: Activity },
                        { title: t('sidebar.all_tests'), href: '/all-test', icon: ClipboardList },
                    ],
                },
            ];
        }

        const platform: NavItem[] = [
            { title: t('sidebar.dashboard'), href: '/dashboard', icon: LayoutDashboard },
            ...(isAdmin
                ? [
                      { title: t('sidebar.user'), href: '/user', icon: Users },
                      { title: t('sidebar.folder'), href: '/folder', icon: Folder },
                  ]
                : []),
            { title: t('sidebar.all_tests'), href: '/all-test', icon: ClipboardList },
            { title: t('sidebar.my_result'), href: '/attempt', icon: BarChart3 },
        ];

        if (!isAdmin) {
            return [{ items: platform }];
        }

        return [
            { items: platform },
            {
                label: t('exam_admin.nav.group_mock'),
                items: [
                    { title: t('sidebar.mock'), href: '/mock', icon: GraduationCap },
                    { title: t('exam_admin.nav.mock_bank'), href: '/mock-bank', icon: Library },
                    { title: t('exam_admin.nav.reception'), href: '/reception', icon: ConciergeBell },
                    { title: t('exam_admin.nav.monitor'), href: '/monitor', icon: Activity },
                    { title: t('exam_admin.nav.speaking'), href: '/speaking', icon: Mic },
                    { title: t('exam_admin.nav.writing_review'), href: '/writing-review', icon: PenLine },
                ],
            },
            {
                label: t('exam_admin.nav.group_desktop'),
                items: [
                    { title: t('exam_admin.nav.devices'), href: '/desktop/devices', icon: Monitor },
                    { title: t('exam_admin.nav.settings'), href: '/desktop/settings', icon: Settings },
                ],
            },
        ];
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [isAdmin, isReception, i18n.language]);

    return (
        <Sidebar 
            collapsible="icon" 
            variant="inset"
        >
            <SidebarHeader className="py-4 px-4">
                <SidebarMenu>
                    <SidebarMenuItem>
                        <SidebarMenuButton size="lg" asChild className="hover:bg-transparent active:bg-transparent">
                            <Link href="/" prefetch className="flex items-center justify-center w-full">
                                <AppLogo />
                            </Link>
                        </SidebarMenuButton>
                    </SidebarMenuItem>
                </SidebarMenu>
            </SidebarHeader>

            <SidebarContent className="py-4 [scrollbar-gutter:stable] [scrollbar-width:thin] group-data-[collapsible=icon]:[scrollbar-gutter:auto]">
                {groups.map((group, index) => (
                    <NavMain key={group.label ?? index} items={group.items} label={group.label} />
                ))}
            </SidebarContent>

            <SidebarFooter className="shrink-0 px-3 pt-2 pb-3">
                <NavFooter items={footerNavItems} className="mb-1 py-0 opacity-70 hover:opacity-100 transition-opacity" />
                <NavUser />
            </SidebarFooter>
        </Sidebar>
    );
}
