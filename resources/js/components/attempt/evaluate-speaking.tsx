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
    DialogTitle,
    DialogTrigger
} from '@/components/ui/dialog';
import { IoCreate } from 'react-icons/io5';
import { baseButton } from '@/components/ui/baseButton';
import { Attempt } from '@/types';
import { Textarea } from '@headlessui/react';


interface UpdateFolderModalProps {
    attempt: Attempt;
}

export default function EvaluateSpeaking({ attempt }: UpdateFolderModalProps) {
    const { t } = useTranslation();
    const [open, setOpen] = useState(false);

    const nameInput = useRef<HTMLInputElement>(null);

    const { data, setData, post, processing, reset, errors, clearErrors } = useForm({
        attempt_id: attempt.id,
        score: '',
        comment: ''
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        post(route('attempt-type.store'), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpen(false); // 🔒 CLOSE MODAL HERE
                toast.success(t('created_successfully'));
            },
            onError: (err) => {
                nameInput.current?.focus();
                // Display a friendly error message if available
                const errorMessage = err?.error || t('create_failed'); // Use fallback error message
                toast.error(errorMessage); // Display error message
            }
        });
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <button
                    className={`${baseButton} bg-blue-600 hover:bg-blue-700 focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700`}
                >
                    <IoCreate className="w-4 h-4" />
                    {t('evaluate_speaking')}
                </button>
            </DialogTrigger>

            <DialogContent className={'dark:border-gray-400'}>
                <DialogTitle>{t('evaluate_speaking')}</DialogTitle>
                <DialogDescription>{t('modal.create_description')}</DialogDescription>

                <form onSubmit={submit} className="space-y-4">
                    <div>
                        <Label htmlFor="score">{t('score')}</Label>
                        <Input
                            id="score"
                            type='number'
                            ref={nameInput}
                            value={data.score}
                            onChange={(e) => setData('score', e.target.value)}
                        />
                        <InputError message={errors.score} />
                    </div>

                    <div className="mb-4">
                        <Label htmlFor="comment" className="block text-sm font-medium text-foreground/80">
                            {t('comment')}
                        </Label>
                        <Textarea
                            id="comment"
                            value={data.comment}
                            onChange={(e) => setData('comment', e.target.value)}
                            className="mt-1 block w-full rounded-lg border border-gray-300 dark:border-gray-600
                   bg-white dark:bg-gray-800 text-foreground 
                   shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm p-2"
                            rows={4}
                        />
                        <InputError message={errors.comment} className="text-red-500 text-sm mt-1" />
                    </div>


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
                            className="bg-blue-600 text-white hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 disabled:opacity-50"
                        >
                            {t('save')}
                        </Button>
                    </DialogFooter>

                </form>
            </DialogContent>
        </Dialog>
    );
}
