import { useTranslation } from 'react-i18next';
import AppLogo from '@/components/app-logo';
import LanguageBar from '@/components/language';
import AppearanceToggleDropdown from '@/components/appearance-dropdown';
import { GlassBackdrop } from '@/components/glass-backdrop';
import { Link } from '@inertiajs/react';
import { type PropsWithChildren } from 'react';

interface AuthLayoutProps {
    name?: string;
    title?: string;
    description?: string;
}

export default function AuthSimpleLayout({ children, title, description }: PropsWithChildren<AuthLayoutProps>) {
    const { t } = useTranslation();
    return (
        <div className="relative min-h-svh flex flex-col items-center justify-center p-6 md:p-10 overflow-hidden">
            <GlassBackdrop />

            <div className="absolute top-6 right-6 z-50 hidden sm:flex items-center gap-2">
                <LanguageBar />
                <AppearanceToggleDropdown />
            </div>

            <div className="relative z-10 w-full max-w-md">
                <div className="flex flex-col gap-10">
                    <div className="flex flex-col items-center gap-6">
                        <Link href={route('home')} className="flex flex-col items-center gap-2 transform transition-transform hover:scale-105 active:scale-95">
                            <AppLogo />
                            <span className="sr-only">{title}</span>
                        </Link>

                        <div className="space-y-2 text-center">
                            <h1 className="text-3xl font-extrabold tracking-tight text-foreground">{title}</h1>
                            <p className="text-muted-foreground text-sm font-medium">{description}</p>
                        </div>
                    </div>
                    {children}
                </div>
            </div>
            
            {/* Footer rights in auth layout */}
            <div className="relative z-10 mt-12 flex flex-col items-center gap-6 text-center">
                <div className="sm:hidden">
                    <LanguageBar placement="top" />
                </div>
                <p className="text-muted-foreground text-[11px] uppercase tracking-widest font-bold">
                    {t('auth_pages.copyright', { year: new Date().getFullYear() })}
                </p>
            </div>
        </div>
    );
}
