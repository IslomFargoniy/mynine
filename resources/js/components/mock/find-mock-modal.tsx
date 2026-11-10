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
                toast.success("Imtihon muvaffaqiyatli boshlanmoqda!");
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
                    className="inline-flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 active:scale-95 px-4 py-2 text-white font-bold text-xs rounded-xl shadow-xs transition-all cursor-pointer"
                >
                    <IoCreate className="h-4 w-4" />
                    <span className="tracking-widest uppercase">{t('common.exam') || 'IMTIHON'}</span>
                </button>
            </DialogTrigger>

            <DialogContent className="sm:max-w-md w-full rounded-2xl border border-border shadow-2xl bg-card p-0 overflow-hidden">
                {/* Header */}
                <header className="border-b border-border bg-gray-50/80 dark:bg-gray-800/40 p-6">
                    <div className="flex items-center gap-3.5">
                        <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-indigo-600 text-white shadow-xs">
                            <LayoutGrid className="h-5 w-5" />
                        </div>
                        <div>
                            <DialogTitle className="text-lg font-extrabold text-foreground">
                                Imtihonga Kirish (Mock Exam)
                            </DialogTitle>
                            <p className="text-xs text-muted-foreground mt-0.5">
                                Sizga berilgan imtihon kodini kiriting
                            </p>
                        </div>
                    </div>
                </header>

                <form onSubmit={submit} className="p-6 space-y-4">
                    <div className="space-y-2">
                        <Label htmlFor="code-input" className="text-xs font-bold text-foreground/80">
                            Nomzod Kodingiz *
                        </Label>
                        <Input
                            id="code-input"
                            ref={codeInput}
                            placeholder="Masalan: TEST1-849201"
                            className="h-11 rounded-xl border-border bg-white dark:bg-gray-800 px-4 font-mono font-bold text-sm tracking-wider uppercase"
                            value={data.code}
                            onChange={(e) => setData('code', e.target.value.toUpperCase())}
                            disabled={processing}
                            required
                        />
                        <InputError message={errors.code} />
                    </div>

                    <DialogFooter className="flex items-center justify-end gap-2 pt-3 border-t border-border">
                        <DialogClose asChild>
                            <Button
                                type="button"
                                variant="outline"
                                className="rounded-xl text-xs font-semibold"
                            >
                                {t('cancel')}
                            </Button>
                        </DialogClose>

                        <Button
                            type="submit"
                            disabled={processing}
                            className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs rounded-xl shadow-xs active:scale-95"
                        >
                            Imtihonni Boshlash →
                        </Button>
                    </DialogFooter>
                </form>
            </DialogContent>
        </Dialog>
    );
}
