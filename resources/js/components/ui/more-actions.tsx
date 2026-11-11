import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { IconAction } from '@/components/ui/icon-action';
import { cn } from '@/lib/utils';
import { MoreHorizontal } from 'lucide-react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';

export interface MoreActionItem {
    label: string;
    icon?: React.ReactNode;
    onSelect: () => void;
    danger?: boolean;
    disabled?: boolean;
    hidden?: boolean;
}

/** "…" menu for the less frequent row actions (keeps action columns narrow). */
export function MoreActions({ items, label }: { items: MoreActionItem[]; label?: string }) {
    const { t } = useTranslation();
    const visible = items.filter((item) => !item.hidden);
    if (visible.length === 0) return null;

    return (
        <DropdownMenu modal={false}>
            <DropdownMenuTrigger asChild>
                <IconAction label={label ?? t('common.more_actions')}>
                    <MoreHorizontal />
                </IconAction>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="min-w-44">
                {visible.map((item) => (
                    <DropdownMenuItem
                        key={item.label}
                        disabled={item.disabled}
                        onSelect={item.onSelect}
                        className={cn('cursor-pointer gap-2 text-xs', item.danger && 'text-rose-700 focus:text-rose-700 dark:text-rose-300 dark:focus:text-rose-300')}
                    >
                        {item.icon}
                        {item.label}
                    </DropdownMenuItem>
                ))}
            </DropdownMenuContent>
        </DropdownMenu>
    );
}
