import * as React from 'react';

import { cn } from '@/lib/utils';

/**
 * Data tables that fit the content width.
 *
 * - Compact cells (px-3 py-2.5), text wraps (`break-words`), long values truncate with a title tooltip (TruncatedText).
 * - Low-priority columns: put `hidden lg:table-cell` on their TableHead/TableCell and repeat the info inline in the
 *   primary cell with `lg:hidden`.
 * - Below md every row becomes a card ("stacked" layout): the header row is hidden and each TableCell with a `label`
 *   shows that label on the left. Cells without a label (the primary cell, actions) span the full card width.
 *   Pass `stacked={false}` to keep a real table on phones (small tables only).
 */

const StackedContext = React.createContext(true);

function Table({ className, containerClassName, stacked = true, ...props }: React.ComponentProps<'table'> & { containerClassName?: string; stacked?: boolean }) {
    return (
        <StackedContext.Provider value={stacked}>
            <div data-slot="table-container" className={cn('relative w-full min-w-0', !stacked && 'overflow-x-auto', stacked && 'max-md:p-2', containerClassName)}>
                <table
                    data-slot="table"
                    className={cn('w-full caption-bottom border-collapse text-left text-xs', stacked && 'max-md:block', className)}
                    {...props}
                />
            </div>
        </StackedContext.Provider>
    );
}

function TableHeader({ className, ...props }: React.ComponentProps<'thead'>) {
    const stacked = React.useContext(StackedContext);
    return (
        <thead
            data-slot="table-header"
            className={cn(
                'border-b border-divider bg-muted text-[10px] font-bold tracking-wide text-muted-foreground uppercase',
                stacked && 'max-md:hidden',
                className,
            )}
            {...props}
        />
    );
}

function TableBody({ className, ...props }: React.ComponentProps<'tbody'>) {
    const stacked = React.useContext(StackedContext);
    return <tbody data-slot="table-body" className={cn('divide-y divide-divider', stacked && 'max-md:block max-md:space-y-2 max-md:divide-y-0', className)} {...props} />;
}

function TableRow({ className, ...props }: React.ComponentProps<'tr'>) {
    const stacked = React.useContext(StackedContext);
    return (
        <tr
            data-slot="table-row"
            className={cn(
                'transition-colors hover:bg-accent/40',
                stacked && 'max-md:flex max-md:flex-col max-md:gap-1 max-md:rounded-[18px] max-md:border max-md:border-glass-edge max-md:bg-glass-subtle max-md:p-3',
                className,
            )}
            {...props}
        />
    );
}

function TableHead({ className, ...props }: React.ComponentProps<'th'>) {
    return <th data-slot="table-head" className={cn('px-3 py-2.5 align-middle font-bold whitespace-nowrap', className)} {...props} />;
}

function TableCell({ className, label, children, ...props }: React.ComponentProps<'td'> & { label?: React.ReactNode }) {
    const stacked = React.useContext(StackedContext);
    return (
        <td
            data-slot="table-cell"
            className={cn(
                'min-w-0 px-3 py-2.5 align-middle break-words',
                stacked && 'max-md:px-0 max-md:py-0.5',
                stacked && label !== undefined && 'max-md:flex max-md:items-start max-md:justify-between max-md:gap-3 max-md:text-right',
                className,
            )}
            {...props}
        >
            {stacked && label !== undefined && (
                <span className="shrink-0 text-left text-[10px] font-bold tracking-wide text-muted-foreground uppercase md:hidden">{label}</span>
            )}
            {stacked && label !== undefined ? <div className="min-w-0 max-md:flex max-md:flex-col max-md:items-end">{children}</div> : children}
        </td>
    );
}

function TableEmpty({ colSpan, children }: { colSpan: number; children: React.ReactNode }) {
    return (
        <tr className="max-md:block">
            <td colSpan={colSpan} className="px-3 py-10 text-center text-xs text-muted-foreground max-md:block">
                {children}
            </td>
        </tr>
    );
}

/**
 * One line, cut with an ellipsis; the full value is in the native tooltip. The max width caps how much the value
 * can widen its column (auto table layout); override it with a `max-w-*` class.
 */
function TruncatedText({ children, className, title }: { children: React.ReactNode; className?: string; title?: string }) {
    const text = title ?? (typeof children === 'string' || typeof children === 'number' ? String(children) : undefined);
    return (
        <span className={cn('block max-w-[16rem] min-w-0 truncate', className)} title={text}>
            {children}
        </span>
    );
}

export { Table, TableBody, TableCell, TableEmpty, TableHead, TableHeader, TableRow, TruncatedText };
