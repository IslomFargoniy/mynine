import { NavFooter } from '@/components/nav-footer';
import { CENTER_TAB_PATHS } from '@/components/center/center-tabs';
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
    Building2,
    ClipboardList,
    BookOpen,
    ConciergeBell,
    FileBarChart,
    GithubIcon as Github,
    GraduationCap,
    Headphones,
    LayoutDashboard,
    Library,
    Mic,
    Monitor,
    PenLine,
    Send,
    Settings2,
    Users
} from 'lucide-react';
import AppLogo from './app-logo';
import { CenterBadge } from './center-badge';
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

    const access = auth?.access;
    const isAdmin = !!access?.centerAdmin;
    const isReception = !!access?.reception;
    const isSuperAdmin = !!access?.superAdmin;
    const manageContent = !!access?.manageContent;

    const groups = useMemo((): { label?: string; items: NavItem[] }[] => {
        if (isReception) {
            return [
                {
                    items: [
                        { title: t('exam_admin.nav.reception'), href: '/reception', icon: ConciergeBell },
                        { title: t('exam_admin.nav.monitor'), href: '/monitor', icon: Activity },
                    ],
                },
            ];
        }

        const platform: NavItem[] = [
            { title: t('sidebar.dashboard'), href: '/dashboard', icon: LayoutDashboard },
            // The website's users (students) are the platform's: SuperAdmin only.
            ...(manageContent ? [{ title: t('sidebar.user'), href: '/user', icon: Users }] : []),
            // Practice tests are for students; center staff run mocks (the content owner keeps it to manage it).
            ...(!isAdmin || manageContent ? [{ title: t('sidebar.test_bank'), href: '/test-bank', icon: ClipboardList }] : []),
            { title: t('sidebar.my_result'), href: '/attempt', icon: BarChart3 },
        ];

        if (!isAdmin) {
            // Regular users: each module on its own (Test Bank keeps the whole test).
            return [
                { items: platform },
                {
                    label: t('practice_module.group'),
                    items: [
                        { title: t('practice_module.listening'), href: '/practice-module/listening', icon: Headphones },
                        { title: t('practice_module.reading'), href: '/practice-module/reading', icon: BookOpen },
                        { title: t('practice_module.writing'), href: '/practice-module/writing', icon: PenLine },
                    ],
                },
            ];
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
                ],
            },
            {
                label: t('exam_admin.nav.group_center'),
                items: [
                    // Settings, staff and usage are tabs of one page (CenterTabs).
                    { title: t('exam_admin.nav.group_center'), href: '/center/settings', icon: Settings2, activePaths: CENTER_TAB_PATHS },
                    ...(isSuperAdmin
                        ? [
                              { title: t('exam_admin.nav.centers'), href: '/centers', icon: Building2 },
                              { title: t('exam_admin.nav.reports'), href: '/reports', icon: FileBarChart },
                          ]
                        : []),
                ],
            },
        ];
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [isAdmin, isReception, isSuperAdmin, manageContent, i18n.language]);

    return (
        <Sidebar 
            collapsible="icon" 
            variant="inset"
        >
            <SidebarHeader className="py-3 px-4">
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

            {/* The logo already names the center (the SuperAdmin switches it in the header): the card only warns
                when the center is suspended. */}
            {auth?.center?.suspended && <CenterBadge center={auth.center} superAdmin={isSuperAdmin} />}

            <SidebarContent data-sidebar-scroll className="gap-3 py-2 [scrollbar-gutter:stable] [scrollbar-width:thin] group-data-[collapsible=icon]:[scrollbar-gutter:auto]">
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
