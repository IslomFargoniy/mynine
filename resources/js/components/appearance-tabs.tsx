import { Appearance, useAppearance } from '@/hooks/use-appearance';
import { cn } from '@/lib/utils';
import { LucideIcon, Monitor, Moon, Sun } from 'lucide-react';
import { HTMLAttributes } from 'react';
import { useTranslation } from 'react-i18next';

interface AppearanceToggleTabProps extends HTMLAttributes<HTMLDivElement> {
    label?: boolean;
}

export default function AppearanceToggleTab({
                                                className = '',
                                                label: showLabel = true,
                                                ...props
                                            }: AppearanceToggleTabProps) {
    const { appearance, updateAppearance } = useAppearance();
    const { t } = useTranslation();

    const tabs: { value: Appearance; icon: LucideIcon; label: string }[] = [
        { value: 'light', icon: Sun, label: t('appearance_toggle.light') },  // Translation key
        { value: 'dark', icon: Moon, label: t('appearance_toggle.dark') },  // Translation key
        { value: 'system', icon: Monitor, label: t('appearance_toggle.system') }  // Translation key
    ];

    return (
        <div
            className={cn('flex p-1 bg-gray-200 dark:bg-gray-700 rounded-md', className)} {...props}>
            {tabs.map(({ value, icon: Icon, label }) => (
                <button
                    key={value}
                    onClick={() => updateAppearance(value)}
                    className={cn(
                        'flex-1 flex items-center justify-center gap-2 px-2.5 py-1.5 rounded transition-all text-xs font-medium uppercase tracking-wider',
                        appearance === value
                            ? 'bg-card text-foreground shadow-sm'
                            : 'text-muted-foreground hover:text-gray-900 dark:hover:text-gray-200'
                    )}
                >
                    <Icon className="h-3 w-3" />
                    {showLabel && <span>{label}</span>}
                </button>
            ))}
        </div>
    );
}
