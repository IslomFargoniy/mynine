import { useForm } from '@inertiajs/react';
import { LayoutGrid } from 'lucide-react';
import { FormEventHandler, useCallback, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { IoCreate } from 'react-icons/io5';
import { toast } from 'sonner';

import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Dialog, DialogClose, DialogContent, DialogFooter, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

export default function FindMockModal() {
    const { t } = useTranslation();
    const [open, setOpen] = useState(false);
    const codeInput = useRef<HTMLInputElement>(null);

    const { data, setData, post, processing, reset, errors, clearErrors } = useForm({
        code: '',
    });

    const handleOpenChange = useCallback(
        (state: boolean) => {
            setOpen(state);
            if (!state) {
                setTimeout(() => {
                    reset();
                    clearErrors();
                }, 200);
            }
        },
        [reset, clearErrors],
    );

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        post(route('mock-student.enter'), {
            preserveState: false,
            preserveScroll: true,
            onSuccess: () => {
                setOpen(false);
                toast.success(t('find_mock.started'));
            },
            onError: (err) => {
                codeInput.current?.focus();
                const errorMessage = err?.code || err?.error || "Kiritilgan kod xato!";
                toast.error(errorMessage);
            },
        });
    };

    return (
        <Dialog open={open} onOpenChange={handleOpenChange}>
            <DialogTrigger asChild>
                <button
                    type="button"
                    className="btn-glass-primary inline-flex items-center justify-center gap-2 hover:brightness-110 active:scale-95 px-5 py-2 font-bold text-xs rounded-full transition-all cursor-pointer"
                >
                    <IoCreate className="h-4 w-4" />
                    <span className="tracking-widest uppercase">{t('common.exam')}</span>
                </button>
            </DialogTrigger>

            <DialogContent className="sm:max-w-md w-full p-0 overflow-hidden">
                {/* Header */}
                <header className="border-b border-divider p-6">
                    <div className="flex items-center gap-3.5">
                        <div className="btn-glass-primary flex h-11 w-11 shrink-0 items-center justify-center rounded-[14px]">
                            <LayoutGrid className="h-5 w-5" />
                        </div>
                        <div>
                            <DialogTitle className="text-lg font-extrabold text-foreground">
                                {t('find_mock.title')}
                            </DialogTitle>
                            <p className="text-xs text-muted-foreground mt-0.5">
                                {t('find_mock.desc')}
                            </p>
                        </div>
                    </div>
                </header>

                <form onSubmit={submit} className="p-6 space-y-4">
                    <div className="space-y-2">
                        <Label htmlFor="code-input" className="text-xs font-bold text-foreground">
                            {t('find_mock.code_label')}
                        </Label>
                        <Input
                            id="code-input"
                            ref={codeInput}
                            placeholder={t('find_mock.code_placeholder')}
                            className="h-11 rounded-xl px-4 font-mono font-bold text-sm tracking-[0.3em]"
                            inputMode="numeric"
                            autoComplete="one-time-code"
                            pattern="[0-9]{6}"
                            maxLength={6}
                            value={data.code}
                            onChange={(e) => setData('code', e.target.value.replace(/\D/g, '').slice(0, 6))}
                            disabled={processing}
                            required
                        />
                        <InputError message={errors.code} />
                    </div>

                    <DialogFooter className="flex items-center justify-end gap-2 pt-3 border-t border-divider">
                        <DialogClose asChild>
                            <Button
                                type="button"
                                variant="outline"
                                className="rounded-full text-xs font-semibold"
                            >
                                {t('cancel')}
                            </Button>
                        </DialogClose>

                        <Button
                            type="submit"
                            disabled={processing}
                            className="font-bold text-xs rounded-full active:scale-95"
                        >
                            {t('find_mock.submit')}
                        </Button>
                    </DialogFooter>
                </form>
            </DialogContent>
        </Dialog>
    );
}
