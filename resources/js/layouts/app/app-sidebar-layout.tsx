import { AppContent } from '@/components/app-content';
import { AppShell } from '@/components/app-shell';
import { AppSidebar } from '@/components/app-sidebar';
import { AppSidebarHeader } from '@/components/app-sidebar-header';
import { type BreadcrumbItem } from '@/types';
import { type PropsWithChildren } from 'react';
import { AppBottomNav } from '@/components/app-bottom-nav';
import FlashMessages from '@/components/flash-messages';
import { GlassBackdrop } from '@/components/glass-backdrop';

export default function AppSidebarLayout({ children, breadcrumbs = [] }: PropsWithChildren<{
    breadcrumbs?: BreadcrumbItem[]
}>) {
    return (
        <AppShell variant="sidebar">
            <GlassBackdrop />
            <FlashMessages />
            <AppSidebar />
            <AppContent variant="sidebar" className="pb-28 md:pb-0 w-100">
                <AppSidebarHeader breadcrumbs={breadcrumbs} />

                {children}
            </AppContent>

            <AppBottomNav />

        </AppShell>
    );
}
