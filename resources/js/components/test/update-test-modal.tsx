import { useForm, usePage } from '@inertiajs/react';
import { FormEventHandler, useRef } from 'react';
import { useTranslation } from 'react-i18next';

import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import TestVariantField, { type TestVariant } from '@/components/test/test-variant-field';
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
import { Auth, Test } from '@/types';

interface UpdateTestModalProps {
    test: Test;
    open: boolean;
    setOpen: (open: boolean) => void;
    onSuccess?: () => void;
}

type TestForm = {
    name: string;
    comment: string;
    audio_path: File | null;
    active: number;
    open: number;
    variant: TestVariant;
};

export default function UpdateTestModal({ test, open, setOpen, onSuccess }: UpdateTestModalProps) {
    const { t } = useTranslation();
    const nameInput = useRef<HTMLInputElement>(null);

    const { data, setData, post, processing, reset, errors, clearErrors } = useForm<TestForm>({
        name: test.name,
        comment: test.comment ?? '',
        audio_path: null,
        active: test.active,
        open: test.open,
        variant: test.variant ?? 'academic'
    });

    const { auth } = usePage().props as unknown as { auth?: Auth };
    // The "open" flag publishes a practice test on the website: platform owner only (Mock Bank tests are never open).
    const isAdmin = !!auth?.access?.manageContent;

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        post(route('test.update', test.id), {
            preserveScroll: true,
            preserveState: true,
            onSuccess: () => {
                clearErrors();
                setOpen(false);
                toast.success(t('updated_successfully'));
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
            <DialogContent className="sm:max-w-lg w-full">
                <DialogHeader className="space-y-1 pb-2 border-b border-divider">
                    <DialogTitle className="text-lg font-bold text-foreground">
                        {t('modal.update_test_title')}
                    </DialogTitle>
                    <DialogDescription className="text-xs text-muted-foreground">
                        {t('modal.update_test_desc')}
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

                    <TestVariantField value={data.variant} onChange={(value) => setData('variant', value)} error={errors.variant} />

                    <div className="space-y-1">
                        <Label htmlFor="audio_path" className="text-sm font-semibold text-foreground/80">
                            {t('audio_path')}
                        </Label>
                        <Input
                            type="file"
                            id="audio_path"
                            accept="audio/*"
                            onChange={(e) => setData('audio_path', (e.target.files?.[0] as File) ?? null)}
                        />
                        <InputError message={errors.audio_path} />
                    </div>

                    <div className="grid grid-cols-2 gap-4">
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
                                    {data.active === 1 ? t('active') : t('inactive')}
                                </span>
                            </label>
                            <InputError message={errors.active} />
                        </div>

                        {isAdmin && (
                            <div className="space-y-1">
                                <Label htmlFor="open" className="text-sm font-semibold text-foreground/80 block">
                                    {t('test_bank.open_label')}
                                </Label>
                                <label className="inline-flex items-center cursor-pointer gap-2">
                                    <input
                                        type="checkbox"
                                        id="open"
                                        className="sr-only peer"
                                        checked={data.open === 1}
                                        onChange={(e) => setData('open', e.target.checked ? 1 : 0)}
                                    />
                                    <div className="relative w-11 h-6 bg-foreground/10 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-ring rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-divider after:border after:rounded-full after:w-5 after:h-5 after:transition-all border border-glass-edge peer-checked:bg-primary"></div>
                                    <span className="text-xs font-medium text-foreground/80">
                                        {data.open === 1 ? t('test_bank.open_state') : t('closed')}
                                    </span>
                                </label>
                                <InputError message={errors.open} />
                            </div>
                        )}
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
