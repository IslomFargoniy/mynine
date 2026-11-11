import { useForm } from '@inertiajs/react';
import React, { FormEventHandler, useRef, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Section, QuestionType } from '@/types';

import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { toast } from 'sonner';

import {
    Dialog,
    DialogClose,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogTitle
} from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import TextareaEditor from '@/components/textarea-editor';
import LiveGapDetector from '@/components/section/live-gap-detector';
import QuestionTypeGuide from '@/components/question/question-type-guide';

interface UpdateSectionModalProps {
    section: Section;
    open: boolean;
    setOpen: (open: boolean) => void;
}

export default function UpdateSectionModal({ section, open, setOpen }: UpdateSectionModalProps) {
    const { t } = useTranslation();
    const nameInput = useRef<HTMLInputElement>(null);

    const [questionTypes, setQuestionTypes] = useState<QuestionType[]>([]);

    const { data, setData, put, processing, reset, errors, clearErrors } = useForm({
        textarea: section.textarea,
        question_type_id: section.question_type_id,
        from_option: section.from_option,
        to_option: section.to_option
    });

    useEffect(() => {
        fetch(route('question-type.index'))
            .then((res) => res.json())
            .then((res) => {
                setQuestionTypes(res.data ?? res);
            })
            .catch((err) => console.error(err));

        setData({
            textarea: section.textarea,
            question_type_id: section.question_type_id,
            from_option: section.from_option,
            to_option: section.to_option
        });
    }, [section.id]);

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        put(route('section.update', section.id), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpen(false); // 🔒 CLOSE MODAL HERE
                toast.success(t('updated_successfully'));
            },
            onError: (err) => {
                nameInput.current?.focus();
                // Display a friendly error message if available
                const errorMessage = err?.error || t('create_failed'); // Use fallback error message
                toast.error(errorMessage); // Display error message
            }
        });

    };

    const selectedTypeObj = questionTypes.find(qt => qt.id === data.question_type_id) ?? section.question_type;
    const isMatchingType = selectedTypeObj?.type === 'matching' || data.question_type_id === 6;
    const isCompleteOrDrag = selectedTypeObj?.type === 'complete_section' || selectedTypeObj?.type === 'drag_and_drop';

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogContent className="sm:max-w-6xl w-full h-[80vh] max-h-[80vh] flex flex-col p-0 overflow-hidden">
                <div className="px-5 py-3 border-b border-divider shrink-0">
                    <DialogTitle className="text-base font-bold text-foreground">
                        {t('modal.update_section_title')}
                    </DialogTitle>
                    <DialogDescription className="text-xs text-muted-foreground">
                        {t('modal.update_section_desc')}
                    </DialogDescription>
                </div>

                <form onSubmit={submit} id="update-section-form" className="flex-1 overflow-y-auto px-5 py-3 flex flex-col">
                    <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start flex-1">
                        {/* Chap tomon: Boshqa ma'lumotlar va Gaps Detector */}
                        <div className="lg:col-span-5 space-y-3">
                            {/* Question Type + Guide Trigger */}
                            <div className="space-y-1">
                                <div className="flex items-center justify-between gap-2">
                                    <Label htmlFor="question_type" className="text-xs font-semibold text-foreground/80">
                                        {t('question_type')} *
                                    </Label>
                                    {selectedTypeObj && (
                                        <QuestionTypeGuide type={selectedTypeObj.type} />
                                    )}
                                </div>
                                <select
                                    id="question_type"
                                    value={data.question_type_id ?? ''}
                                    onChange={(e) => setData('question_type_id', Number(e.target.value) || 0)}
                                    className="block w-full rounded-xl border border-input bg-glass-subtle text-foreground focus:border-ring focus:ring-2 focus:ring-ring/40 px-3 py-2 text-xs font-medium focus:outline-none"
                                >
                                    <option value="">{t('select')}</option>
                                    {questionTypes.map((type) => (
                                        <option key={type.id} value={type.id}>
                                            {type.name}
                                        </option>
                                    ))}
                                </select>
                                <InputError message={errors.question_type_id} />
                            </div>

                            {/* Conditional fields for Matching (diapazon: A - F) */}
                            {isMatchingType && (
                                <div className="p-2.5 rounded-[18px] bg-indigo-500/12 border border-indigo-500/25 space-y-2">
                                    <div className="text-[11px] font-bold text-brand uppercase tracking-wider">
                                        {t('matching_options_range')} *
                                    </div>
                                    <div className="grid grid-cols-2 gap-3">
                                        <div>
                                            <Label htmlFor="from_option" className="text-[11px] font-semibold text-foreground/80">
                                                {t('from_char_or_num')}
                                            </Label>
                                            <Input
                                                id="from_option"
                                                placeholder={t('section_form.from_placeholder')}
                                                value={data.from_option}
                                                required={true}
                                                onChange={(e) => setData('from_option', e.target.value.toUpperCase())}
                                                className="mt-0.5 h-8 text-xs font-mono font-bold uppercase"
                                            />
                                            <InputError message={errors.from_option} />
                                        </div>
                                        <div>
                                            <Label htmlFor="to_option" className="text-[11px] font-semibold text-foreground/80">
                                                {t('to_char_or_num')}
                                            </Label>
                                            <Input
                                                id="to_option"
                                                placeholder={t('section_form.to_placeholder')}
                                                value={data.to_option}
                                                required={true}
                                                onChange={(e) => setData('to_option', e.target.value.toUpperCase())}
                                                className="mt-0.5 h-8 text-xs font-mono font-bold uppercase"
                                            />
                                            <InputError message={errors.to_option} />
                                        </div>
                                    </div>
                                    <p className="text-[10px] text-brand">
                                        {t('matching_range_hint')}
                                    </p>
                                </div>
                            )}

                            {/* Live Gap Detector for complete_section / drag_and_drop */}
                            {isCompleteOrDrag && (
                                <LiveGapDetector textarea={data.textarea} />
                            )}
                        </div>

                        {/* O'ng tomon: TinyMCE Editor */}
                        <div className="lg:col-span-7 space-y-1.5 flex flex-col h-full">
                            <div className="flex items-center justify-between">
                                <Label className="text-xs font-semibold text-foreground/80">
                                    {t('section_instructions')} *
                                </Label>
                                {isCompleteOrDrag && (
                                    <button
                                        type="button"
                                        onClick={() => {
                                            setData("textarea", (data.textarea || '') + " { to'g'ri_javob } ");
                                        }}
                                        className="text-[11px] font-bold text-brand hover:bg-indigo-500/20 bg-indigo-500/12 px-2.5 py-1 rounded-full border border-indigo-500/25 transition-colors cursor-pointer"
                                    >
                                        + &#123; &#125; {t('insert_bracket_gap')}
                                    </button>
                                )}
                            </div>
                            <div className="flex-1">
                                <TextareaEditor
                                    value={data.textarea}
                                    onChange={(content) => setData("textarea", content)}
                                    error={errors.textarea}
                                    height={500}
                                />
                            </div>
                        </div>
                    </div>
                </form>

                <DialogFooter className="px-5 py-2.5 border-t border-divider shrink-0 flex items-center justify-end gap-2.5">
                    <DialogClose asChild>
                        <Button
                            type="button"
                            variant="outline"
                            className="h-8 text-xs"
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
                        form="update-section-form"
                        disabled={processing}
                        className="h-8 text-xs font-semibold"
                    >
                        {t('save')}
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
