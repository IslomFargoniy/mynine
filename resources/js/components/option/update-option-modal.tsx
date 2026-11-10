import { useForm } from '@inertiajs/react';
import React, { FormEventHandler, useRef, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { toast } from 'sonner';

import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import {
    Dialog,
    DialogClose,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogTitle
} from '@/components/ui/dialog';

import { Option, QuestionType } from '@/types';

interface UpdateOptionModalProps {
    option: Option;
    question_type?: QuestionType;
    open: boolean;
    setOpen: (open: boolean) => void;
}

export default function UpdateOptionModal({
                                              option,
                                              question_type,
                                              open,
                                              setOpen
                                          }: UpdateOptionModalProps) {
    const { t } = useTranslation();
    const nameInput = useRef<HTMLInputElement>(null);

    const { data, setData, put, processing, reset, errors, clearErrors } = useForm({
        textarea: option.textarea,
        is_correct: option.is_correct
    });

    // ✅ Sync option prop when modal opens or option changes
    useEffect(() => {
        if (open) {
            setData({
                textarea: option.textarea,
                is_correct: option.is_correct
            });
        }
    }, [option, open]);

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        put(route('option.update', option.id), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpen(false);
                toast.success(t('updated_successfully'));
            },
            onError: () => {
                nameInput.current?.focus();
                toast.error(t('update_failed'));
            }
        });
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogContent className="dark:border-gray-700">
                <DialogTitle>{t('modal.update_title')}</DialogTitle>
                <DialogDescription>{t('modal.update_description')}</DialogDescription>

                <form onSubmit={submit} className="space-y-4">
                    {/* Textarea input */}
                    <div>
                        <Label htmlFor="textarea">{t('textarea')}</Label>
                        <Input
                            id="textarea"
                            ref={nameInput}
                            value={data.textarea}
                            onChange={(e) => setData('textarea', e.target.value)}
                            className="mt-1"
                            disabled={question_type?.type === 'true_false' || question_type?.type === 'yes_no'}
                        />
                        <InputError message={errors.textarea} />
                    </div>

                    {/* Checkbox */}
                    <div className="flex items-center gap-2">
                        <Checkbox
                            id="is_correct"
                            checked={!!data.is_correct} // ✅ boolean for UI
                            onCheckedChange={(checked) =>
                                setData('is_correct', checked === true ? 1 : 0) // ✅ store 0|1
                            }
                        />

                        <Label htmlFor="is_correct">{t('is_correct')}</Label>
                    </div>
                    <InputError message={errors.is_correct} />

                    {/* Footer */}
                    <DialogFooter className="flex justify-end gap-3 pt-4 border-t border-border">
                        <DialogClose asChild>
                            <Button
                                type="button"
                                variant="secondary"
                                className="bg-muted text-foreground/80 hover:bg-gray-200
                             dark:hover:bg-gray-700"
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
                            className="bg-blue-600 text-white hover:bg-blue-700
                         dark:bg-blue-500 dark:hover:bg-blue-600
                         disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            {processing ? t('saving') + '...' : t('save')}
                        </Button>
                    </DialogFooter>
                </form>
            </DialogContent>
        </Dialog>
    );
}
