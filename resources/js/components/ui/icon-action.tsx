import * as React from 'react';

import { Tooltip, TooltipContent, TooltipTrigger } from '@/components/ui/tooltip';
import { cn } from '@/lib/utils';

type Tone = 'default' | 'brand' | 'danger' | 'success' | 'warning';

const tones: Record<Tone, string> = {
    default: 'text-muted-foreground hover:bg-accent hover:text-foreground',
    brand: 'text-brand hover:bg-indigo-500/12',
    danger: 'text-rose-700 hover:bg-rose-500/12 dark:text-rose-300',
    success: 'text-emerald-700 hover:bg-emerald-500/12 dark:text-emerald-300',
    warning: 'text-amber-700 hover:bg-amber-500/15 dark:text-amber-300',
};

type IconActionProps = Omit<React.ComponentProps<'button'>, 'aria-label'> & {
    /** Accessible name; also shown as the tooltip. */
    label: string;
    tone?: Tone;
    /** Render the child element (e.g. an Inertia <Link> or <a>) instead of a <button>. */
    asChild?: boolean;
};

/**
 * Compact icon-only action (table rows, card headers): 32px hit area, aria-label and a tooltip.
 */
const IconAction = React.forwardRef<HTMLButtonElement, IconActionProps>(function IconAction(
    { label, tone = 'default', className, children, asChild = false, ...props },
    ref,
) {
    const classes = cn(
        'inline-flex size-8 shrink-0 cursor-pointer items-center justify-center rounded-full transition-colors outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 [&_svg]:size-4 [&_svg]:shrink-0',
        tones[tone],
        className,
    );

    const trigger =
        asChild && React.isValidElement<{ className?: string; 'aria-label'?: string }>(children) ? (
            React.cloneElement(children, { className: cn(classes, children.props.className), 'aria-label': label })
        ) : (
            <button ref={ref} type="button" aria-label={label} className={classes} {...props}>
                {children}
            </button>
        );

    return (
        <Tooltip>
            <TooltipTrigger asChild>{trigger}</TooltipTrigger>
            <TooltipContent>{label}</TooltipContent>
        </Tooltip>
    );
});

export { IconAction };
