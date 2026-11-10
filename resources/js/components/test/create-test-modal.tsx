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

export default function CreateTestModal({ folder_id }: { folder_id: number }) {
    const { t } = useTranslation();
    const [open, setOpen] = useState(false);
    const nameInput = useRef<HTMLInputElement>(null);

    const { data, setData, post, processing, reset, errors, clearErrors } = useForm<{
        folder_id: number;
        name: string;
        comment: string;
        audio_path: File | null;
    }>({
        folder_id: folder_id,
        name: '',
        comment: '',
        audio_path: null
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        post(route('test.store'), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpen(false);
                toast.success(t('created_successfully'));
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
                <button className="inline-flex items-center gap-2 px-4 py-2.5 bg-blue-600 hover:bg-blue-700 active:scale-95 text-white font-bold text-xs rounded-xl shadow-xs transition-all cursor-pointer">
                    <Plus className="w-4 h-4" />
                    {t('create')} {t('test')}
                </button>
            </DialogTrigger>

            <DialogContent className="sm:max-w-lg w-full rounded-2xl border border-border shadow-2xl bg-card">
                <DialogHeader className="space-y-1 pb-2 border-b border-border">
                    <DialogTitle className="text-lg font-bold text-foreground">
                        {t('modal.create_test_title')}
                    </DialogTitle>
                    <DialogDescription className="text-xs text-muted-foreground">
                        {t('modal.create_test_desc')}
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
                            placeholder="Masalan: Cambridge 18 Test 1"
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
                            placeholder="Izoh (ixtiyoriy)"
                            value={data.comment}
                            onChange={(e) => setData('comment', e.target.value)}
                        />
                        <InputError message={errors.comment} />
                    </div>

                    <div className="space-y-1">
                        <Label htmlFor="audio_path" className="text-sm font-semibold text-foreground/80">
                            {t('audio_path') || 'Audio fayl'}
                        </Label>
                        <Input
                            type="file"
                            id="audio_path"
                            accept="audio/*"
                            onChange={(e) => setData('audio_path', (e.target.files?.[0] as File) ?? null)}
                        />
                        <InputError message={errors.audio_path} />
                    </div>

                    <DialogFooter className="flex items-center justify-end gap-3 pt-4 mt-4 border-t border-border">
                        <DialogClose asChild>
                            <Button
                                type="button"
                                variant="outline"
                                className="border-gray-300 dark:border-gray-700"
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
                            className="bg-blue-600 hover:bg-blue-700 text-white font-semibold shadow-xs"
                        >
                            {t('save')}
                        </Button>
                    </DialogFooter>

                </form>
            </DialogContent>
        </Dialog>
    );
}
