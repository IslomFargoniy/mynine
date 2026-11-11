import { useForm } from '@inertiajs/react';
import { FormEventHandler, useRef, useState } from 'react';
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
    DialogTitle,
    DialogTrigger
} from '@/components/ui/dialog';
import { Plus } from 'lucide-react';

export default function CreateFolderModal({ onSuccess }: { onSuccess?: () => void } = {}) {
    const { t } = useTranslation();
    const [open, setOpen] = useState(false);
    const nameInput = useRef<HTMLInputElement>(null);

    const { data, setData, post, processing, reset, errors, clearErrors } = useForm({
        name: '',
        comment: '',
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        post(route('folder.store'), {
            preserveScroll: true,
            preserveState: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpen(false);
                toast.success(t('created_successfully'));
                onSuccess?.();
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
            <DialogTrigger asChild>
                <button
                    type="button"
                    className="inline-flex h-9 shrink-0 items-center gap-2 px-4 btn-glass-primary hover:brightness-110 active:scale-95 text-primary-foreground font-bold text-xs rounded-full transition-all cursor-pointer"
                >
                    <Plus className="w-4 h-4" />
                    {t('test_bank.create_folder')}
                </button>
            </DialogTrigger>

            <DialogContent className="sm:max-w-lg w-full">
                <DialogHeader className="space-y-1 pb-2 border-b border-divider">
                    <DialogTitle className="text-lg font-bold text-foreground">
                        {t('modal.create_folder_title')}
                    </DialogTitle>
                    <DialogDescription className="text-xs text-muted-foreground">
                        {t('modal.create_folder_desc')}
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
                            placeholder={t('test_bank.folder_name_placeholder')}
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
                            placeholder={t('test_bank.comment_placeholder')}
                            value={data.comment}
                            onChange={(e) => setData('comment', e.target.value)}
                        />
                        <InputError message={errors.comment} />
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
