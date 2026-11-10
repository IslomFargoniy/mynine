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
                <button className="inline-flex items-center justify-center gap-2 h-9 px-4 bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 active:scale-95 text-white font-bold text-xs rounded-xl shadow-xs transition-all cursor-pointer shrink-0">
                    <Sparkles className="w-4 h-4 shrink-0" />
                    {t('ai_import')}
                </button>
            </DialogTrigger>

            <DialogContent className="sm:max-w-2xl w-full overflow-y-auto dark:border-gray-400">
                <DialogTitle className="flex items-center gap-2">
                    <Sparkles className="w-5 h-5 text-purple-500" />
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
                             className="w-full h-48 p-3 text-sm border rounded bg-white dark:bg-gray-800 dark:border-gray-700 dark:text-white outline-none focus:ring-1 focus:ring-purple-500"
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
                            className="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-purple-50 file:text-purple-700 hover:file:bg-purple-100 dark:file:bg-gray-800 dark:file:text-gray-300"
                        />
                        <InputError message={errors.file} />
                    </div>

                    {errors.error && (
                        <div className="text-sm font-semibold text-red-600 bg-red-50 dark:bg-red-950 p-2.5 rounded dark:text-red-400">
                            {errors.error}
                        </div>
                    )}

                    <DialogFooter className="flex justify-end gap-3 pt-4 border-t border-border">
                        <DialogClose asChild>
                            <Button
                                variant="secondary"
                                className="bg-muted text-foreground/80 hover:bg-gray-200 dark:hover:bg-gray-700"
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
                            className="bg-purple-600 text-white hover:bg-purple-700 dark:bg-purple-500 dark:hover:bg-purple-600 disabled:opacity-50 flex items-center gap-1.5"
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
