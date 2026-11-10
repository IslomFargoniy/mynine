import AppLogo from '@/components/app-logo';
import LanguageBar from '@/components/language';
import AppearanceToggleDropdown from '@/components/appearance-dropdown';
import { Link } from '@inertiajs/react';
import { type PropsWithChildren } from 'react';

interface AuthLayoutProps {
    name?: string;
    title?: string;
    description?: string;
}

export default function AuthSimpleLayout({ children, title, description }: PropsWithChildren<AuthLayoutProps>) {
    return (
        <div className="relative min-h-svh flex flex-col items-center justify-center p-6 md:p-10 overflow-hidden bg-card transition-colors duration-500">
            {/* Premium Background Elements */}
            <div className="absolute inset-0 overflow-hidden z-0">
                <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-blue-500/10 dark:bg-blue-600/10 blur-[120px] rounded-full animate-pulse" />
                <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-purple-500/10 dark:bg-purple-600/10 blur-[120px] rounded-full animate-pulse" style={{ animationDelay: '1s' }} />
                
                {/* Subtle Grid Pattern */}
                <div className="absolute inset-0 bg-[url('https://grainy-gradients.vercel.app/noise.svg')] opacity-[0.03] dark:opacity-[0.05]" />
            </div>

            <div className="absolute top-6 right-6 z-50 hidden sm:flex items-center gap-2">
                <LanguageBar />
                <AppearanceToggleDropdown />
            </div>

            <div className="relative z-10 w-full max-w-sm">
                <div className="flex flex-col gap-10">
                    <div className="flex flex-col items-center gap-6">
                        <Link href={route('home')} className="flex flex-col items-center gap-2 transform transition-transform hover:scale-105 active:scale-95">
                            <AppLogo />
                            <span className="sr-only">{title}</span>
                        </Link>

                        <div className="space-y-2 text-center">
                            <h1 className="text-3xl font-black tracking-tight text-foreground">{title}</h1>
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
                <p className="text-muted-foreground text-[10px] uppercase tracking-widest font-bold">
                    &copy; 2025 Mynine Academy. All Rights Reserved.
                </p>
            </div>
        </div>
    );
}
