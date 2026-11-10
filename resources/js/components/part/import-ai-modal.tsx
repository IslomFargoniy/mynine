import { useForm } from '@inertiajs/react';
import React, { FormEventHandler, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Button } from '@/components/ui/button';
import { toast } from 'sonner';
import { Sparkles } from 'lucide-react';

import {
    Dialog,
    DialogClose,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogTitle,
    DialogTrigger
} from '@/components/ui/dialog';
import { Part } from '@/types';
import InputError from '@/components/input-error';
import { Label } from '@/components/ui/label';

interface ImportAiModalProps {
    part: Part;
}

export default function ImportAiModal({ part }: ImportAiModalProps) {
    const { t } = useTranslation();
    const [open, setOpen] = useState(false);

    const { data, setData, post, processing, reset, errors, clearErrors } = useForm<{
        text: string;
        file: File | null;
        error?: string;
    }>({
        text: '',
        file: null
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        post(route('part.import-ai', part.id), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpen(false);
                toast.success(t('imported_successfully'));
            },
            onError: (err) => {
                const errorMessage = err?.error || t('import_failed');
                toast.error(errorMessage);
            }
        });
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <button className="inline-flex items-center justify-center gap-2 h-9 px-4 btn-glass-primary hover:brightness-110 active:scale-95 text-primary-foreground font-bold text-xs rounded-full transition-all cursor-pointer shrink-0">
                    <Sparkles className="w-4 h-4 shrink-0" />
                    {t('ai_import')}
                </button>
            </DialogTrigger>

            <DialogContent className="sm:max-w-2xl w-full overflow-y-auto">
                <DialogTitle className="flex items-center gap-2">
                    <Sparkles className="w-5 h-5 text-brand" />
                    {t('modal.ai_import_title')}
                </DialogTitle>
                <DialogDescription>
                    {t('modal.ai_import_desc')}
                </DialogDescription>

                <form onSubmit={submit} className="space-y-4 mt-2">
                    <div className="space-y-1">
                        <Label htmlFor="text">{t('paste_test_text')}</Label>
                        <textarea
                             id="text"
                             value={data.text}
                             onChange={(e) => setData('text', e.target.value)}
                             placeholder={t('paste_test_placeholder')}
                             className="w-full h-48 p-3 text-sm rounded-xl border border-input bg-glass-subtle text-foreground focus:border-ring focus:ring-2 focus:ring-ring/40 outline-none"
                        />
                        <InputError message={errors.text} />
                    </div>

                    <div className="space-y-1">
                        <Label htmlFor="file">{t('upload_docx_or_txt')}</Label>
                        <input
                            type="file"
                            id="file"
                            accept=".docx,.txt"
                            onChange={(e) => setData('file', e.target.files?.[0] || null)}
                            className="block w-full text-sm text-muted-foreground file:mr-4 file:py-2 file:px-4 file:rounded-full file:border file:border-glass-edge file:text-sm file:font-semibold file:bg-indigo-500/12 file:text-brand hover:file:bg-indigo-500/20"
                        />
                        <InputError message={errors.file} />
                    </div>

                    {errors.error && (
                        <div className="text-sm font-semibold rounded-[18px] border border-rose-500/25 bg-rose-500/12 text-rose-800 dark:text-rose-200 p-2.5">
                            {errors.error}
                        </div>
                    )}

                    <DialogFooter className="flex justify-end gap-3 pt-4 border-t border-divider">
                        <DialogClose asChild>
                            <Button
                                variant="secondary"
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
                            className="disabled:opacity-50 flex items-center gap-1.5"
                        >
                            {processing ? (
                                <>
                                    <span className="animate-spin inline-block w-4 h-4 border-2 border-t-transparent border-white rounded-full"></span>
                                    {t('processing')}
                                </>
                            ) : (
                                <>
                                    <Sparkles className="w-4 h-4" />
                                    {t('import')}
                                </>
                            )}
                        </Button>
                    </DialogFooter>
                </form>
            </DialogContent>
        </Dialog>
    );
}
