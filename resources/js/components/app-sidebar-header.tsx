import { Breadcrumbs } from '@/components/breadcrumbs';
import { SidebarTrigger } from '@/components/ui/sidebar';
import { type BreadcrumbItem as BreadcrumbItemType } from '@/types';
import LanguageBar from '@/components/language';
import AppearanceToggleDropdown from '@/components/appearance-dropdown';

export function AppSidebarHeader({ breadcrumbs = [] }: { breadcrumbs?: BreadcrumbItemType[] }) {
    return (
        <div className="fixed top-0 z-50 block w-full dark:bg-black bg-white">
            <header className="flex justify-between items-center h-14 px-6 border-b-2 border-border">
                <div className="flex items-center gap-2">
                    <SidebarTrigger className="-ml-1" />
                    <Breadcrumbs breadcrumbs={breadcrumbs} />
                </div>
                <div className="flex-1"></div>
                <div className="fixed top-2.5 right-4 z-[60] flex items-center gap-2">
                    {/* 1st: Language Switcher Dropdown */}
                    <LanguageBar />
                    
                    {/* 2nd: Mode Button (Dark/Light theme toggle) */}
                    <AppearanceToggleDropdown />
                </div>
            </header>
        </div>
    );
}
