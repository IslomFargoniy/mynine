import { cn } from '@/lib/utils';
import { type CenterSummary } from '@/types';
import { Link } from '@inertiajs/react';
import { Building2, Lock } from 'lucide-react';
import { useTranslation } from 'react-i18next';

/**
 * The center the staff user works for (sidebar). A suspended center is read-only; the SuperAdmin sees which
 * center is active and can switch it on the Centers page.
 */
export function CenterBadge({ center, superAdmin }: { center: CenterSummary; superAdmin: boolean }) {
    const { t } = useTranslation();

    const body = (
        <div
            className={cn(
                'glass-subtle flex items-center gap-2.5 rounded-[16px] px-3 py-2 group-data-[collapsible=icon]:hidden',
                center.suspended && 'border border-rose-500/30 bg-rose-500/10',
            )}
        >
            {center.logo_url ? (
                <img src={center.logo_url} alt="" className="h-8 w-8 shrink-0 rounded-[10px] object-cover" />
            ) : (
                <span className="text-brand flex h-8 w-8 shrink-0 items-center justify-center rounded-[10px] bg-indigo-500/12">
                    <Building2 className="h-4 w-4" />
                </span>
            )}
            <div className="min-w-0 flex-1">
                <div className="text-foreground truncate text-xs font-bold">{center.name}</div>
                <div className="text-muted-foreground flex items-center gap-1 font-mono text-[10px]">
                    {center.code}
                    {superAdmin && <span className="font-sans">· {t('centers.badge.active')}</span>}
                </div>
                {center.suspended && (
                    <div className="mt-0.5 flex items-center gap-1 text-[10px] font-bold text-rose-700 dark:text-rose-300">
                        <Lock className="h-3 w-3" />
                        {t('centers.badge.read_only')}
                    </div>
                )}
            </div>
        </div>
    );

    return <div className="px-3 pb-1">{superAdmin ? <Link href={route('centers.index')}>{body}</Link> : body}</div>;
}
