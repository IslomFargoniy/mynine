import { Button } from '@/components/ui/button';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { ChevronDown, FileText, Printer, ReceiptText } from 'lucide-react';
import { useTranslation } from 'react-i18next';

const selection = (mockId: number, ids?: number[]) => (ids && ids.length > 0 ? { mock: mockId, ids: ids.join(',') } : { mock: mockId });

/** 80 mm receipt tickets (Xprinter): opens the browser print dialog in a new tab, which closes after printing. */
export function printCodeTickets(mockId: number, ids?: number[]) {
    window.open(route('mock.code-tickets', selection(mockId, ids)), '_blank');
}

/** A4 PDF code cards (8 per page). */
export function printCodeCardsPdf(mockId: number, ids?: number[]) {
    window.open(route('mock.code-cards', selection(mockId, ids)), '_blank');
}

/** Split button: "Receipt (80 mm)" by default, "A4 PDF" in the menu. */
export function PrintCodesButton({ mockId, ids, label }: { mockId: number; ids?: number[]; label?: string }) {
    const { t } = useTranslation();

    return (
        <div className="inline-flex items-stretch">
            <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => printCodeTickets(mockId, ids)}
                className="rounded-l-full rounded-r-none border-r-0 text-xs font-semibold"
                title={t('exam_admin.candidates.print_receipt')}
            >
                <Printer className="h-3.5 w-3.5 text-brand" />
                {label ?? t('exam_admin.candidates.print_cards')}
            </Button>
            <DropdownMenu modal={false}>
                <DropdownMenuTrigger asChild>
                    <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        aria-label={t('exam_admin.candidates.print_options')}
                        title={t('exam_admin.candidates.print_options')}
                        className="rounded-l-none rounded-r-full px-2"
                    >
                        <ChevronDown className="h-3.5 w-3.5" />
                    </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="min-w-44">
                    <DropdownMenuItem className="cursor-pointer gap-2 text-xs" onSelect={() => printCodeTickets(mockId, ids)}>
                        <ReceiptText className="h-4 w-4" />
                        {t('exam_admin.candidates.print_receipt')}
                    </DropdownMenuItem>
                    <DropdownMenuItem className="cursor-pointer gap-2 text-xs" onSelect={() => printCodeCardsPdf(mockId, ids)}>
                        <FileText className="h-4 w-4" />
                        {t('exam_admin.candidates.print_a4')}
                    </DropdownMenuItem>
                </DropdownMenuContent>
            </DropdownMenu>
        </div>
    );
}
