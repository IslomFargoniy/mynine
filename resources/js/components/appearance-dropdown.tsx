
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { useAppearance } from '@/hooks/use-appearance';
import { Monitor, Moon, Sun, Check } from 'lucide-react';
import { HTMLAttributes } from 'react';
import { useTranslation } from 'react-i18next';

export default function AppearanceToggleDropdown({ className = '', ...props }: HTMLAttributes<HTMLDivElement>) {
    const { appearance, updateAppearance } = useAppearance();
    const { t } = useTranslation();

    const getCurrentIcon = () => {
        switch (appearance) {
            case 'dark':
                return <Moon className="h-4 w-4 text-brand " />;
            case 'light':
                return <Sun className="h-4 w-4 text-amber-600 dark:text-amber-300" />;
            default:
                return <Monitor className="h-4 w-4 text-brand " />;
        }
    };

    const getLabel = () => {
        switch (appearance) {
            case 'dark':
                return t('dark');
            case 'light':
                return t('light');
            default:
                return t('system');
        }
    };

    return (
        <div className={`inline-block ${className}`} {...props}>
            <DropdownMenu>
                <DropdownMenuTrigger asChild>
                    <button
                        type="button"
                        title={getLabel()}
                        aria-label={getLabel()}
                        className="inline-flex items-center justify-center h-9 w-9 rounded-full border border-glass-edge bg-glass-subtle text-foreground hover:bg-accent transition-colors cursor-pointer active:scale-95"
                    >
                        {getCurrentIcon()}
                    </button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-36 p-1 z-[70]">
                    <DropdownMenuItem
                        onClick={() => updateAppearance('light')}
                        className={`flex items-center justify-between px-3 py-2 text-xs font-semibold rounded-lg cursor-pointer transition-colors ${
                            appearance === 'light'
                                ? 'bg-indigo-500/12 text-primary'
                                : 'text-foreground'
                        }`}
                    >
                        <span className="flex items-center gap-2">
                            <Sun className="h-3.5 w-3.5 text-amber-500" />
                            <span>{t('light')}</span>
                        </span>
                        {appearance === 'light' && <Check className="h-3.5 w-3.5 text-primary" />}
                    </DropdownMenuItem>

                    <DropdownMenuItem
                        onClick={() => updateAppearance('dark')}
                        className={`flex items-center justify-between px-3 py-2 text-xs font-semibold rounded-lg cursor-pointer transition-colors ${
                            appearance === 'dark'
                                ? 'bg-indigo-500/12 text-primary'
                                : 'text-foreground'
                        }`}
                    >
                        <span className="flex items-center gap-2">
                            <Moon className="h-3.5 w-3.5 text-brand " />
                            <span>{t('dark')}</span>
                        </span>
                        {appearance === 'dark' && <Check className="h-3.5 w-3.5 text-primary" />}
                    </DropdownMenuItem>

                    <DropdownMenuItem
                        onClick={() => updateAppearance('system')}
                        className={`flex items-center justify-between px-3 py-2 text-xs font-semibold rounded-lg cursor-pointer transition-colors ${
                            appearance === 'system'
                                ? 'bg-indigo-500/12 text-primary'
                                : 'text-foreground'
                        }`}
                    >
                        <span className="flex items-center gap-2">
                            <Monitor className="h-3.5 w-3.5 text-brand " />
                            <span>{t('system')}</span>
                        </span>
                        {appearance === 'system' && <Check className="h-3.5 w-3.5 text-primary" />}
                    </DropdownMenuItem>
                </DropdownMenuContent>
            </DropdownMenu>
        </div>
    );
}
