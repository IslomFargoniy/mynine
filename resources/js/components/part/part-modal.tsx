import { useForm } from '@inertiajs/react';
import React, { FormEventHandler, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Button } from '@/components/ui/button';
import { toast } from 'sonner';
import {
    Dialog,
    DialogContent,
    DialogTitle,
} from '@/components/ui/dialog';
import { Part, TestType } from '@/types';
import InputError from '@/components/input-error';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import TextareaEditor from '@/components/textarea-editor';

interface PartModalProps {
    testType: TestType;
    part?: Part | null; // null for Create mode, Part object for Edit mode
    open: boolean;
    setOpen: (open: boolean) => void;
}

export default function PartModal({ testType, part, open, setOpen }: PartModalProps) {
    const { t } = useTranslation();
    const isEdit = Boolean(part?.id);

    const { data, setData, post, put, processing, reset, errors, clearErrors } = useForm({
        test_type_id: testType?.id,
        name: part?.name || '',
        textarea: part?.textarea || '',
        minute: part?.minute || null,
        comment: part?.comment || ''
    });

    useEffect(() => {
        if (!open) return;

        setData({
            test_type_id: testType?.id,
            name: part?.name || '',
            textarea: part?.textarea || '',
            minute: part?.minute || null,
            comment: part?.comment || ''
        });
    }, [open, part, testType]);

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        if (isEdit && part?.id) {
            put(route('part.update', part.id), {
                preserveScroll: true,
                onSuccess: () => {
                    reset();
                    clearErrors();
                    setOpen(false);
                    toast.success(t('updated_successfully'));
                },
                onError: (err) => {
                    const errorMessage = err?.error || t('update_failed');
                    toast.error(errorMessage);
                }
            });
        } else {
            post(route('part.store'), {
                preserveScroll: true,
                onSuccess: () => {
                    reset();
                    clearErrors();
                    setOpen(false);
                    toast.success(t('created_successfully'));
                },
                onError: (err) => {
                    const errorMessage = err?.error || t('create_failed');
                    toast.error(errorMessage);
                }
            });
        }
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogContent className="sm:max-w-none w-screen h-screen rounded-none border-none p-0 overflow-hidden flex flex-col">

                {/* Sticky Full-Screen Header */}
                <div className="flex items-center justify-between px-6 py-3.5 pr-14 border-b border-divider bg-muted shrink-0">
                    <div className="flex items-center gap-3">
                        <DialogTitle className="text-lg font-bold text-foreground">
                            {isEdit ? `${t('edit')} ${part?.name}` : `${t('add_part')} (${testType?.type?.name || ''})`}
                        </DialogTitle>
                        {testType?.test?.name && (
                            <>
                                <span className="text-xs text-muted-foreground">|</span>
                                <span className="text-xs font-semibold text-muted-foreground">
                                    {testType?.test?.name} {testType?.type?.name ? `/ ${testType.type.name}` : ''}
                                </span>
                            </>
                        )}
                    </div>
                </div>

                {/* Main Content Form */}
                <form onSubmit={submit} className="flex flex-col flex-1 min-h-0 overflow-hidden">
                    <div className="flex-1 overflow-y-auto p-6 space-y-4">

                        {/* Top Inputs: Name & Comment */}
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <Label htmlFor="part_name" className="text-sm font-semibold text-foreground/80">
                                    {t('name')} *
                                </Label>
                                <Input
                                    id="part_name"
                                    placeholder={t('part_form.name_placeholder')}
                                    value={data.name}
                                    onChange={(e) => setData('name', e.target.value)}
                                    required
                                    className="mt-1"
                                />
                                <InputError message={errors.name} />
                            </div>

                            <div>
                                <Label htmlFor="part_comment" className="text-sm font-semibold text-foreground/80">
                                    {t('comment')}
                                </Label>
                                <Input
                                    id="part_comment"
                                    placeholder={t('part_form.comment_placeholder')}
                                    value={data.comment}
                                    onChange={(e) => setData('comment', e.target.value)}
                                    className="mt-1"
                                />
                                <InputError message={errors.comment} />
                            </div>
                        </div>

                        {/* TinyMCE Full Passage Editor */}
                        <div className="space-y-1.5 flex flex-col flex-1">
                            <Label className="text-sm font-semibold text-foreground/80">
                                {t('part_form.passage')}
                            </Label>
                            <TextareaEditor
                                value={data.textarea}
                                onChange={(content) => setData('textarea', content)}
                                height={520}
                            />
                        </div>
                    </div>

                    {/* Full-Screen Footer Bar */}
                    <div className="shrink-0 flex items-center justify-end gap-3 px-6 py-3.5 border-t border-divider bg-muted">
                        <Button
                            type="button"
                            variant="outline"
                            onClick={() => setOpen(false)}
                        >
                            {t('cancel')}
                        </Button>
                        <Button
                            type="submit"
                            disabled={processing}
                            className="font-semibold px-6"
                        >
                            {isEdit ? t('update') : t('save')}
                        </Button>
                    </div>
                </form>

            </DialogContent>
        </Dialog>
    );
}
