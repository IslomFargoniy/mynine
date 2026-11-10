import { useForm } from '@inertiajs/react';
import { FormEventHandler, useRef, useEffect } from 'react';
import { useTranslation } from 'react-i18next';

import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { toast } from 'sonner';

import {
    Dialog,
    DialogClose,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle
} from '@/components/ui/dialog';
import { Folder } from '@/types';

interface UpdateFolderModalProps {
    folder: Folder;
    open: boolean;
    setOpen: (open: boolean) => void;
}

export default function UpdateFolderModal({ folder, open, setOpen }: UpdateFolderModalProps) {
    const { t } = useTranslation();
    const nameInput = useRef<HTMLInputElement>(null);

    const { data, setData, put, processing, reset, errors, clearErrors } = useForm({
        name: folder.name,
        comment: folder.comment,
        active: folder.active
    });

    useEffect(() => {
        setData({
            name: folder.name,
            comment: folder.comment,
            active: folder.active
        });
    }, [folder, setData]);

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        put(route('folder.update', folder.id), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpen(false);
                toast.success(t('updated_successfully'));
            },
            onError: (err) => {
                nameInput.current?.focus();
                const errorMessage = err?.error || t('create_failed');
                toast.error(errorMessage);
            }
        });
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogContent className="sm:max-w-lg w-full">
                <DialogHeader className="space-y-1 pb-2 border-b border-divider">
                    <DialogTitle className="text-lg font-bold text-foreground">
                        {t('modal.update_title') || "Papkani tahrirlash"}
                    </DialogTitle>
                    <DialogDescription className="text-xs text-muted-foreground">
                        {t('modal.update_description') || "Papka ma'lumotlarini yangilang."}
                    </DialogDescription>
                </DialogHeader>

                <form onSubmit={submit} className="space-y-4 mt-2">
                    <div className="space-y-1">
                        <Label htmlFor="name" className="text-sm font-semibold text-foreground/80">
                            {t('name')} *
                        </Label>
                        <Input
                            id="name"
                            ref={nameInput}
                            value={data.name}
                            onChange={(e) => setData('name', e.target.value)}
                            required
                        />
                        <InputError message={errors.name} />
                    </div>

                    <div className="space-y-1">
                        <Label htmlFor="comment" className="text-sm font-semibold text-foreground/80">
                            {t('comment')}
                        </Label>
                        <Input
                            id="comment"
                            value={data.comment}
                            onChange={(e) => setData('comment', e.target.value)}
                        />
                        <InputError message={errors.comment} />
                    </div>

                    <div className="space-y-1">
                        <Label htmlFor="status" className="text-sm font-semibold text-foreground/80 block">
                            {t('status')}
                        </Label>
                        <label className="inline-flex items-center cursor-pointer gap-2">
                            <input
                                type="checkbox"
                                id="status"
                                className="sr-only peer"
                                checked={data.active === 1}
                                onChange={(e) => setData('active', e.target.checked ? 1 : 0)}
                            />
                            <div className="relative w-11 h-6 bg-foreground/10 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-ring rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-divider after:border after:rounded-full after:w-5 after:h-5 after:transition-all border border-glass-edge peer-checked:bg-primary"></div>
                            <span className="text-xs font-medium text-foreground/80">
                                {data.active === 1 ? 'Aktiv' : 'Nofaol'}
                            </span>
                        </label>
                        <InputError message={errors.active} />
                    </div>

                    <DialogFooter className="flex items-center justify-end gap-3 pt-4 mt-4 border-t border-divider">
                        <DialogClose asChild>
                            <Button
                                type="button"
                                variant="outline"
                                onClick={() => {
                                    reset();
                                    clearErrors();
                                    setOpen(false);
                                }}
                            >
                                {t('cancel')}
                            </Button>
                        </DialogClose>

                        <Button
                            type="submit"
                            disabled={processing}
                            className="font-semibold"
                        >
                            {t('save')}
                        </Button>
                    </DialogFooter>

                </form>
            </DialogContent>
        </Dialog>
    );
}
