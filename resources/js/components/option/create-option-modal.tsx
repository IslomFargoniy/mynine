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
import { Checkbox } from '@/components/ui/checkbox';
import { Question, Section } from '@/types';
import { baseButton } from '@/components/ui/baseButton';

interface CreateOptionModalProps {
    question?: Question;
    section?: Section;
}

export default function CreateOptionModal({ question, section }: CreateOptionModalProps) {
    const { t } = useTranslation();
    const [open, setOpen] = useState(false);
    const nameInput = useRef<HTMLInputElement>(null);

    const { data, setData, post, processing, reset, errors, clearErrors } = useForm<{
        section_id?: number;
        question_id?: number;
        textarea: string;
        is_correct: boolean;
    }>({
        section_id: section?.id,
        question_id: question?.id,
        textarea: '',
        is_correct: false,
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        post(route('option.store'), {
            preserveScroll: true,
            onSuccess: () => {
                toast.success(t('created_successfully'));
                reset();
                clearErrors();
                setOpen(false);
            },
            onError: (err: any) => {
                nameInput.current?.focus();
                const errorMessage = err?.error || t('create_failed');
                toast.error(errorMessage);
            },
        });
    };

    return (
        <Dialog open={open} onOpenChange={(val) => {
            setOpen(val);
            if (!val) {
                reset();
                clearErrors();
            }
        }}>
            <DialogTrigger asChild>
                <button
                    className={`${baseButton} bg-blue-600 hover:bg-blue-700 focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700`}
                >
                    <IoCreate className="w-4 h-4" />
                    {t('create')} {t('option')}
                </button>
            </DialogTrigger>

            <DialogContent className="dark:border-gray-400">
                <DialogTitle>{t('modal.create_title')}</DialogTitle>
                <DialogDescription>{t('modal.create_description')}</DialogDescription>

                <form onSubmit={submit} className="space-y-4">
                    {/* Option text */}
                    <div>
                        <Label htmlFor="textarea">{t('textarea')}</Label>
                        <Input
                            id="textarea"
                            ref={nameInput}
                            value={data.textarea}
                            onChange={(e) => setData('textarea', e.target.value)}
                            placeholder={t('enter_option_text')}
                        />
                        <InputError message={errors.textarea} />
                    </div>

                    {/* Is correct checkbox */}
                    <div className="flex items-center gap-2">
                        <Checkbox
                            id="is_correct"
                            checked={data.is_correct}
                            onCheckedChange={(checked) => setData('is_correct', checked === true)}
                        />
                        <Label htmlFor="is_correct">{t('is_correct')}</Label>
                        <InputError message={errors.is_correct} />
                    </div>

                    {/* Footer */}
                    <DialogFooter className="flex justify-end gap-3 pt-4 border-t border-border">
                        <DialogClose asChild>
                            <Button
                                type="button"
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
                            {processing ? t('saving') + '...' : t('save')}
                        </Button>
                    </DialogFooter>
                </form>
            </DialogContent>
        </Dialog>
    );
}
