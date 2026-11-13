import { Breadcrumbs } from '@/components/breadcrumbs';
import { SidebarTrigger } from '@/components/ui/sidebar';
import { type BreadcrumbItem as BreadcrumbItemType } from '@/types';
import LanguageBar from '@/components/language';
import CenterSwitcher from '@/components/center/center-switcher';
import AppearanceToggleDropdown from '@/components/appearance-dropdown';

/** Floating pill top bar (liquid glass): sidebar toggle + breadcrumbs, language and theme. */
export function AppSidebarHeader({ breadcrumbs = [] }: { breadcrumbs?: BreadcrumbItemType[] }) {
    return (
        <div className="sticky top-3 z-40 mx-3 mt-3 mb-4 md:mx-0 md:mt-0">
            <header className="glass-pill flex h-14 items-center justify-between gap-3 pr-2 pl-3 md:pl-4">
                <div className="flex min-w-0 items-center gap-2">
                    <SidebarTrigger className="-ml-0.5 size-9 rounded-full" />
                    <div className="min-w-0 truncate">
                        <Breadcrumbs breadcrumbs={breadcrumbs} />
                    </div>
                </div>
                <div className="flex shrink-0 items-center gap-2">
                    <CenterSwitcher />
                    <LanguageBar />
                    <AppearanceToggleDropdown />
                </div>
            </header>
        </div>
    );
}
