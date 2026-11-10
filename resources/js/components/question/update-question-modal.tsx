import { useForm } from '@inertiajs/react';
import React, { FormEventHandler, useRef, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';

import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import { toast } from 'sonner';

import {
    Dialog,
    DialogClose,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogTitle
} from '@/components/ui/dialog';
import { Question, Section } from '@/types';
import { buildRange } from '@/utils/rangeHelpers';
import { Plus, ClipboardList, Trash2, CheckCircle2 } from 'lucide-react';
import QuestionTypeGuide from '@/components/question/question-type-guide';

interface UpdateQuestionModalProps {
    question: Question;
    section: Section;
    open: boolean;
    setOpen: (open: boolean) => void;
}

export default function UpdateQuestionModal({ question, section, open, setOpen }: UpdateQuestionModalProps) {
    const { t } = useTranslation();
    const nameInput = useRef<HTMLInputElement>(null);
    const [showSmartPaste, setShowSmartPaste] = useState(false);
    const [smartPasteText, setSmartPasteText] = useState('');

    const { data, setData, put, processing, reset, errors, clearErrors } = useForm<{
        textarea: string;
        answer_text: string;
        options: { id?: number; textarea: string; is_correct: boolean }[];
    }>({
        textarea: question.textarea || '',
        answer_text: question.answer_text || '',
        options: question.options?.map(o => ({
            id: o.id,
            textarea: o.textarea || '',
            is_correct: Boolean(o.is_correct)
        })) || []
    });

    useEffect(() => {
        if (!open) return;

        let initialOptions: { id?: number; textarea: string; is_correct: boolean }[] = question.options?.map(o => ({
            id: o.id,
            textarea: o.textarea || '',
            is_correct: Boolean(o.is_correct)
        })) || [];

        const qType = section.question_type?.type;
        if (initialOptions.length === 0) {
            if (qType === 'true_false') {
                initialOptions = [
                    { textarea: 'True', is_correct: false },
                    { textarea: 'False', is_correct: false },
                    { textarea: 'Not Given', is_correct: false }
                ];
            } else if (qType === 'yes_no') {
                initialOptions = [
                    { textarea: 'Yes', is_correct: false },
                    { textarea: 'No', is_correct: false },
                    { textarea: 'Not Given', is_correct: false }
                ];
            }
        }

        setData({
            textarea: question.textarea || '',
            answer_text: question.answer_text || '',
            options: initialOptions
        });
    }, [open, question]);

    const addOption = () => {
        setData('options', [...data.options, { textarea: '', is_correct: false }]);
    };

    const removeOption = (index: number) => {
        const updated = data.options.filter((_, i) => i !== index);
        setData('options', updated);
    };

    const updateOption = (index: number, field: 'textarea' | 'is_correct', value: any) => {
        const updated = [...data.options];
        if (field === 'is_correct' && value === true) {
            const isSingular =
                section.question_type?.type === 'multiple_choice' ||
                section.question_type?.type === 'true_false' ||
                section.question_type?.type === 'yes_no';

            if (isSingular) {
                updated.forEach((option, i) => {
                    option.is_correct = (i === index);
                });
            } else {
                updated[index].is_correct = value;
            }
        } else {
            (updated[index] as any)[field] = value;
        }
        setData('options', updated);
    };

    const handleSmartPaste = () => {
        if (!smartPasteText.trim()) return;
        const lines = smartPasteText.split(/\r?\n/).map(line => line.trim()).filter(line => line.length > 0);
        const parsedOptions = lines.map(line => {
            let cleanedText = line.replace(/^[A-Z0-9][-.)\s]+/i, '').trim();
            const isCorrect = line.includes('*') || line.toLowerCase().includes('(correct)');
            cleanedText = cleanedText.replace(/\*$/, '').replace(/\(correct\)$/i, '').trim();
            return { textarea: cleanedText, is_correct: isCorrect };
        });
        setData('options', [...data.options, ...parsedOptions]);
        setSmartPasteText('');
        setShowSmartPaste(false);
        toast.success(`${parsedOptions.length} ta variant qo'shildi!`);
    };

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        put(route('question.update', question.id), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpen(false);
                toast.success(t('updated_successfully'));
            },
            onError: (err) => {
                nameInput.current?.focus();
                const errorMessage = err?.error || t('update_failed');
                toast.error(errorMessage);
            }
        });
    };

    const qType = section.question_type?.type;

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogContent className="sm:max-w-4xl w-full overflow-y-auto">
                <DialogTitle className="text-lg font-bold text-foreground">
                    {t('modal.update_title') || "Savolni tahrirlash"}
                </DialogTitle>
                <DialogDescription className="text-xs text-muted-foreground">
                    Savol matni va barcha variantlarini bir joyda tahrirlang.
                </DialogDescription>

                <form onSubmit={submit} className="space-y-4 mt-1">

                    {/* Question Prompt Textarea + Guide trigger */}
                    <div className="space-y-1">
                        <div className="flex items-center justify-between gap-2">
                            <Label htmlFor="textarea" className="text-sm font-semibold text-foreground/80">
                                {t('question_prompt') || "Savol Matni / Prompt"} *
                            </Label>
                            <QuestionTypeGuide type={qType} />
                        </div>
                        <Input
                            id="textarea"
                            ref={nameInput}
                            placeholder="Savol matnini kiriting"
                            value={data.textarea}
                            onChange={(e) => setData('textarea', e.target.value)}
                            className="text-sm"
                        />
                        <InputError message={errors.textarea} />
                    </div>

                    {/* Fill in the Blank: Answer Text Input */}
                    {qType === 'fill_blank' && (
                        <div className="p-3 bg-indigo-500/12 rounded-[18px] border border-indigo-500/25 space-y-1">
                            <Label htmlFor="answer_text" className="text-sm font-semibold text-brand">
                                To'g'ri Javob Matni (Correct Answer) *
                            </Label>
                            <Input
                                id="answer_text"
                                placeholder="Masalan: climate change"
                                value={data.answer_text}
                                onChange={(e) => setData('answer_text', e.target.value)}
                                className="bg-glass-strong"
                            />
                            <InputError message={errors.answer_text} />
                        </div>
                    )}

                    {/* Matching: Select Dropdown from range A-F */}
                    {qType === 'matching' && (
                        <div className="p-3 bg-indigo-500/12 rounded-[18px] border border-indigo-500/25 space-y-1">
                            <Label htmlFor="answer_text" className="text-sm font-semibold text-brand">
                                To'g'ri Mos keluvchi Harf (Select Answer) *
                            </Label>
                            <select
                                id="answer_text"
                                value={data.answer_text ?? ''}
                                onChange={(e) => setData('answer_text', e.target.value)}
                                className="block w-full rounded-xl border border-input bg-glass-subtle text-foreground focus:border-ring focus:ring-2 focus:ring-ring/40 px-3.5 py-2 text-sm focus:outline-none"
                            >
                                <option value="">{t('select') || "-- To'g'ri harfni tanlang --"}</option>
                                {buildRange(section.from_option, section.to_option).map(opt => (
                                    <option key={opt} value={opt}>{opt}</option>
                                ))}
                            </select>
                            <InputError message={errors.answer_text} />
                        </div>
                    )}

                    {/* Multiple Choice / Response / True False / Yes No Options */}
                    {(qType === 'true_false' || qType === 'yes_no' || qType === 'multiple_choice' || qType === 'multiple_response') && (
                        <div className="space-y-3">
                            {(qType === 'true_false' || qType === 'yes_no') ? (
                                <div className="space-y-2">
                                    <Label className="text-xs font-bold text-foreground/80 uppercase tracking-wider">
                                        To'g'ri javob variantini belgilang *
                                    </Label>
                                    <div className="grid grid-cols-3 gap-3">
                                        {data.options.map((option, index) => (
                                            <div
                                                key={index}
                                                onClick={() => updateOption(index, 'is_correct', true)}
                                                className={`flex items-center justify-between p-3 border rounded-[18px] cursor-pointer select-none transition-all ${
                                                    option.is_correct
                                                        ? 'border-primary bg-indigo-500/12 ring-2 ring-ring/30'
                                                        : 'border-glass-edge bg-glass-subtle hover:bg-accent'
                                                }`}
                                            >
                                                <span className="font-bold text-sm text-foreground">
                                                    {option.textarea}
                                                </span>
                                                <div className={`w-5 h-5 rounded-full border flex items-center justify-center transition-colors ${
                                                    option.is_correct
                                                        ? 'border-primary bg-primary text-primary-foreground'
                                                        : 'border-input'
                                                }`}>
                                                    {option.is_correct && <CheckCircle2 className="w-4 h-4" />}
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            ) : (
                                <div className="space-y-3">
                                    <div className="flex items-center justify-between">
                                        <Label className="text-sm font-bold text-foreground">
                                            Javob Variantlari (Options)
                                        </Label>
                                        <Button
                                            type="button"
                                            variant="outline"
                                            size="sm"
                                            onClick={() => setShowSmartPaste(!showSmartPaste)}
                                            className="text-xs gap-1.5 border-violet-500/30 text-violet-800 hover:bg-violet-500/12 dark:text-violet-200"
                                        >
                                            <ClipboardList className="w-3.5 h-3.5" />
                                            {showSmartPaste ? 'Yashirish' : 'Aqlli nusxalash (Smart Paste)'}
                                        </Button>
                                    </div>

                                    {showSmartPaste && (
                                        <div className="p-3 border border-dashed border-violet-500/30 rounded-[18px] bg-violet-500/10 space-y-2">
                                            <p className="text-xs text-violet-800 dark:text-violet-200 font-medium">
                                                Matnli variantlarni har bir qatorda nusxalab tashlang (To'g'ri javob ketidan * qo'ying):
                                            </p>
                                            <textarea
                                                placeholder={"A) Option 1\nB) Option 2*\nC) Option 3\nD) Option 4"}
                                                value={smartPasteText}
                                                onChange={(e) => setSmartPasteText(e.target.value)}
                                                className="w-full h-24 p-2 text-xs rounded-xl border border-input bg-glass-subtle text-foreground focus:border-ring focus:ring-2 focus:ring-ring/40 font-mono outline-none"
                                            />
                                            <Button
                                                type="button"
                                                size="sm"
                                                onClick={handleSmartPaste}
                                                className="text-xs font-semibold"
                                            >
                                                Variantlarni tahlil qilib qo'shish
                                            </Button>
                                        </div>
                                    )}

                                    {/* Options list */}
                                    <div className="space-y-2">
                                        {data.options.map((option, index) => (
                                            <div key={index} className="flex items-center gap-2">
                                                <Input
                                                    placeholder={`Variant ${String.fromCharCode(65 + index)}`}
                                                    value={option.textarea}
                                                    onChange={(e) => updateOption(index, 'textarea', e.target.value)}
                                                    className="flex-1 text-sm"
                                                />

                                                <label className="flex items-center gap-1.5 px-3 py-2 border border-glass-edge bg-glass-subtle rounded-full cursor-pointer select-none shrink-0 hover:bg-accent">
                                                    <Checkbox
                                                        checked={option.is_correct}
                                                        onCheckedChange={(checked) =>
                                                            updateOption(index, 'is_correct', checked === true)
                                                        }
                                                    />
                                                    <span className="text-xs font-semibold text-foreground/80">
                                                        {t('correct') || "To'g'ri"}
                                                    </span>
                                                </label>

                                                <Button
                                                    type="button"
                                                    variant="ghost"
                                                    size="icon"
                                                    onClick={() => removeOption(index)}
                                                    className="text-rose-700 dark:text-rose-300 hover:text-rose-800 dark:hover:text-rose-200 hover:bg-rose-500/12 shrink-0"
                                                >
                                                    <Trash2 className="w-4 h-4" />
                                                </Button>
                                            </div>
                                        ))}
                                    </div>

                                    {/* Dotted + Variant qo'shish button */}
                                    <button
                                        type="button"
                                        onClick={addOption}
                                        className="w-full py-2 border-2 border-dashed border-glass-dash hover:border-ring hover:bg-indigo-500/12 text-muted-foreground hover:text-brand rounded-full text-xs font-semibold flex items-center justify-center gap-1.5 transition-all cursor-pointer"
                                    >
                                        <Plus className="w-4 h-4" />
                                        {t('add_option') || "Yangi variant qo'shish"}
                                    </button>
                                </div>
                            )}
                        </div>
                    )}

                    {/* Modal Footer */}
                    <DialogFooter className="flex items-center justify-end gap-3 pt-4 border-t border-divider">
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
