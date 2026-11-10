import { Button } from '@/components/ui/button';
import {
    Dialog,
    DialogClose,
    DialogContent,
    DialogFooter,
    DialogHeader,
    DialogTitle,
    DialogDescription
} from '@/components/ui/dialog';
import { useTranslation } from 'react-i18next';
import { AlertTriangle } from 'lucide-react';

interface DeleteItemModalProps {
    item: { id: number; name?: string; textarea?: string };
    open: boolean;
    setOpen: (open: boolean) => void;
    onDelete: (id: number) => void;
}

export default function DeleteItemModal({ item, open, setOpen, onDelete }: DeleteItemModalProps) {
    const { t } = useTranslation();

    const handleDelete = () => {
        onDelete(item.id);
        setOpen(false);
    };

    const displayName = item.name || (item.textarea ? item.textarea.replace(/<[^>]*>/g, '').slice(0, 40) : null);

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogContent className="sm:max-w-md w-full dark:border-gray-700">
                <DialogHeader className="space-y-1 pb-2 border-b border-border">
                    <div className="flex items-center gap-2 text-red-600 dark:text-red-400">
                        <AlertTriangle className="w-5 h-5 shrink-0" />
                        <DialogTitle className="text-lg font-bold text-foreground">
                            {t('modal.delete_title') || "O'chirishni tasdiqlang"}
                        </DialogTitle>
                    </div>
                    <DialogDescription className="text-xs text-muted-foreground">
                        {t('modal.delete_confirmation') || "Ushbu ma'lumotni o'chirishga ishonchingiz komilmi? Ushbu amalni ortga qaytarib bo'lmaydi."}
                    </DialogDescription>
                </DialogHeader>

                {displayName && (
                    <div className="p-3 my-1 rounded-lg bg-red-50/60 dark:bg-red-950/30 border border-red-100 dark:border-red-900 text-xs font-semibold text-red-900 dark:text-red-200 truncate">
                        "{displayName}"
                    </div>
                )}

                <DialogFooter className="flex items-center justify-end gap-3 pt-3 mt-2 border-t border-border">
                    <DialogClose asChild>
                        <Button
                            type="button"
                            variant="outline"
                            className="border-gray-300 dark:border-gray-700"
                            onClick={() => setOpen(false)}
                        >
                            {t('cancel')}
                        </Button>
                    </DialogClose>

                    <Button
                        type="button"
                        variant="destructive"
                        onClick={handleDelete}
                        className="bg-red-600 hover:bg-red-700 text-white font-semibold shadow-xs"
                    >
                        {t('delete')}
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
