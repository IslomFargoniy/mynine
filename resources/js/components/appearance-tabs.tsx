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
            className={cn('glass-pill flex gap-1 p-1', className)} {...props}>
            {tabs.map(({ value, icon: Icon, label }) => (
                <button
                    key={value}
                    onClick={() => updateAppearance(value)}
                    className={cn(
                        'flex-1 flex items-center justify-center gap-2 h-9 px-4 rounded-full border border-transparent transition-all text-xs font-medium uppercase tracking-wider',
                        appearance === value
                            ? 'bg-glass-thumb border-glass-edge text-foreground font-semibold shadow-glass-pill'
                            : 'text-muted-foreground hover:text-foreground'
                    )}
                >
                    <Icon className="h-3 w-3" />
                    {showLabel && <span>{label}</span>}
                </button>
            ))}
        </div>
    );
}
