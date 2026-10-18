
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
                return <Moon className="h-4 w-4 text-purple-400" />;
            case 'light':
                return <Sun className="h-4 w-4 text-amber-500" />;
            default:
                return <Monitor className="h-4 w-4 text-blue-500" />;
        }
    };

    const getLabel = () => {
        switch (appearance) {
            case 'dark':
                return t('dark') || 'Dark';
            case 'light':
                return t('light') || 'Light';
            default:
                return t('system') || 'System';
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
                        className="inline-flex items-center justify-center h-9 w-9 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-700 transition-all cursor-pointer shadow-xs active:scale-95"
                    >
                        {getCurrentIcon()}
                    </button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-36 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-1 shadow-lg z-[70]">
                    <DropdownMenuItem
                        onClick={() => updateAppearance('light')}
                        className={`flex items-center justify-between px-3 py-2 text-xs font-semibold rounded-lg cursor-pointer transition-colors ${
                            appearance === 'light'
                                ? 'bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400'
                                : 'text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700'
                        }`}
                    >
                        <span className="flex items-center gap-2">
                            <Sun className="h-3.5 w-3.5 text-amber-500" />
                            <span>Light</span>
                        </span>
                        {appearance === 'light' && <Check className="h-3.5 w-3.5 text-blue-600 dark:text-blue-400" />}
                    </DropdownMenuItem>

                    <DropdownMenuItem
                        onClick={() => updateAppearance('dark')}
                        className={`flex items-center justify-between px-3 py-2 text-xs font-semibold rounded-lg cursor-pointer transition-colors ${
                            appearance === 'dark'
                                ? 'bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400'
                                : 'text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700'
                        }`}
                    >
                        <span className="flex items-center gap-2">
                            <Moon className="h-3.5 w-3.5 text-purple-400" />
                            <span>Dark</span>
                        </span>
                        {appearance === 'dark' && <Check className="h-3.5 w-3.5 text-blue-600 dark:text-blue-400" />}
                    </DropdownMenuItem>

                    <DropdownMenuItem
                        onClick={() => updateAppearance('system')}
                        className={`flex items-center justify-between px-3 py-2 text-xs font-semibold rounded-lg cursor-pointer transition-colors ${
                            appearance === 'system'
                                ? 'bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400'
                                : 'text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700'
                        }`}
                    >
                        <span className="flex items-center gap-2">
                            <Monitor className="h-3.5 w-3.5 text-blue-500" />
                            <span>System</span>
                        </span>
                        {appearance === 'system' && <Check className="h-3.5 w-3.5 text-blue-600 dark:text-blue-400" />}
                    </DropdownMenuItem>
                </DropdownMenuContent>
            </DropdownMenu>
        </div>
    );
}
