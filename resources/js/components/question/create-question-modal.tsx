import { useForm } from '@inertiajs/react';
import React, { FormEventHandler, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';

import { Button } from '@/components/ui/button';
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
import { Section } from '@/types';
import InputError from '@/components/input-error';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Checkbox } from '@/components/ui/checkbox';
import { buildRange } from '@/utils/rangeHelpers';
import { Plus, ClipboardList, Trash2, CheckCircle2 } from 'lucide-react';
import QuestionTypeGuide from '@/components/question/question-type-guide';

interface SectionUpdateProps {
    section: Section;
}

export default function CreateQuestionModal({ section }: SectionUpdateProps) {
    const { t } = useTranslation();
    const [open, setOpen] = useState(false);
    const [showSmartPaste, setShowSmartPaste] = useState(false);
    const [smartPasteText, setSmartPasteText] = useState('');

    const nameInput = useRef<HTMLInputElement>(null);

    const { data, setData, post, processing, reset, errors, clearErrors } = useForm<{
        section_id: number;
        textarea: string;
        answer_text: string;
        options: { textarea: string; is_correct: boolean }[];
    }>({
        section_id: section.id,
        textarea: '',
        answer_text: '',
        options: []
    });

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

        post(route('question.store'), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpen(false);
                toast.success(t('created_successfully'));
            },
            onError: (err) => {
                nameInput.current?.focus();
                const errorMessage = err?.error || t('create_failed');
                toast.error(errorMessage);
            }
        });
    };

    useEffect(() => {
        if (!open) return;

        if (section.question_type?.type === 'true_false') {
            setData('options', [
                { textarea: 'True', is_correct: false },
                { textarea: 'False', is_correct: false },
                { textarea: 'Not Given', is_correct: false }
            ]);
        } else if (section.question_type?.type === 'yes_no') {
            setData('options', [
                { textarea: 'Yes', is_correct: false },
                { textarea: 'No', is_correct: false },
                { textarea: 'Not Given', is_correct: false }
            ]);
        }
    }, [open, section.question_type?.type]);

    const qType = section.question_type?.type;

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <button className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-blue-600 hover:bg-blue-700 active:scale-95 text-white font-semibold text-xs rounded-lg shadow-xs transition-all cursor-pointer">
                    <Plus className="w-4 h-4" />
                    {t('create')} {t('question')}
                </button>
            </DialogTrigger>

            <DialogContent className="sm:max-w-4xl w-full overflow-y-auto dark:border-gray-700">
                <DialogTitle className="text-lg font-bold text-foreground">
                    {t('modal.create_title') || "Yangi savol qo'shish"}
                </DialogTitle>
                <DialogDescription className="text-xs text-muted-foreground">
                    {section.question_type?.name} savoli uchun ma'lumotlarni kiriting.
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
                            placeholder="Masalan: What is the main idea of paragraph A?"
                            value={data.textarea}
                            onChange={(e) => setData('textarea', e.target.value)}
                            className="text-sm"
                        />
                        <InputError message={errors.textarea} />
                    </div>

                    {/* Fill in the Blank: Answer Text Input */}
                    {qType === 'fill_blank' && (
                        <div className="p-3 bg-blue-50/70 dark:bg-blue-950/40 rounded-xl border border-blue-200 dark:border-blue-800 space-y-1">
                            <Label htmlFor="answer_text" className="text-sm font-semibold text-blue-900 dark:text-blue-200">
                                To'g'ri Javob Matni (Correct Answer) *
                            </Label>
                            <Input
                                id="answer_text"
                                placeholder="Masalan: climate change"
                                value={data.answer_text}
                                onChange={(e) => setData('answer_text', e.target.value)}
                                className="bg-white dark:bg-gray-800"
                            />
                            <p className="text-[11px] text-blue-600 dark:text-blue-400">
                                Foydalanuvchi kiritgan matn ushbu so'z bilan tekshiriladi (harf kattaligi farq qilmaydi).
                            </p>
                            <InputError message={errors.answer_text} />
                        </div>
                    )}

                    {/* Matching: Select Dropdown from range A-F */}
                    {qType === 'matching' && (
                        <div className="p-3 bg-indigo-50/70 dark:bg-indigo-950/40 rounded-xl border border-indigo-200 dark:border-indigo-800 space-y-1">
                            <Label htmlFor="answer_text" className="text-sm font-semibold text-indigo-900 dark:text-indigo-200">
                                To'g'ri Mos keluvchi Harf (Select Answer) *
                            </Label>
                            <select
                                id="answer_text"
                                value={data.answer_text ?? ''}
                                onChange={(e) => setData('answer_text', e.target.value)}
                                className="block w-full rounded-lg border border-gray-300 bg-white px-3.5 py-2 text-sm shadow-xs focus:border-indigo-500 focus:ring-indigo-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white"
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
                                                className={`flex items-center justify-between p-3 border rounded-xl cursor-pointer select-none transition-all ${
                                                    option.is_correct
                                                        ? 'border-blue-600 bg-blue-50 dark:bg-blue-950/60 dark:border-blue-500 ring-2 ring-blue-600/20'
                                                        : 'border-border hover:bg-gray-50 dark:hover:bg-gray-800'
                                                }`}
                                            >
                                                <span className="font-bold text-sm text-foreground">
                                                    {option.textarea}
                                                </span>
                                                <div className={`w-5 h-5 rounded-full border flex items-center justify-center transition-colors ${
                                                    option.is_correct
                                                        ? 'border-blue-600 bg-blue-600 text-white'
                                                        : 'border-gray-300 dark:border-gray-600'
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
                                            className="text-xs gap-1.5 border-purple-300 text-purple-700 hover:bg-purple-50 dark:border-purple-800 dark:text-purple-300 dark:hover:bg-purple-950"
                                        >
                                            <ClipboardList className="w-3.5 h-3.5" />
                                            {showSmartPaste ? 'Yashirish' : 'Aqlli nusxalash (Smart Paste)'}
                                        </Button>
                                    </div>

                                    {showSmartPaste && (
                                        <div className="p-3 border border-dashed border-purple-300 dark:border-purple-800 rounded-xl bg-purple-50/50 dark:bg-purple-950/30 space-y-2">
                                            <p className="text-xs text-purple-900 dark:text-purple-200 font-medium">
                                                Matnli variantlarni har bir qatorda nusxalab tashlang (To'g'ri javob ketidan * qo'ying):
                                            </p>
                                            <textarea
                                                placeholder={"A) Option 1\nB) Option 2*\nC) Option 3\nD) Option 4"}
                                                value={smartPasteText}
                                                onChange={(e) => setSmartPasteText(e.target.value)}
                                                className="w-full h-24 p-2 text-xs border rounded-lg bg-white dark:bg-gray-800 dark:border-gray-700 dark:text-white font-mono focus:ring-2 focus:ring-purple-500 outline-none"
                                            />
                                            <Button
                                                type="button"
                                                size="sm"
                                                onClick={handleSmartPaste}
                                                className="bg-purple-600 hover:bg-purple-700 text-white text-xs font-semibold"
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

                                                <label className="flex items-center gap-1.5 px-3 py-2 border rounded-lg cursor-pointer select-none shrink-0 hover:bg-gray-50 dark:hover:bg-gray-800">
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
                                                    className="text-red-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-950 shrink-0"
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
                                        className="w-full py-2 border-2 border-dashed border-gray-300 dark:border-gray-700 hover:border-blue-500 dark:hover:border-blue-400 hover:bg-blue-50/50 dark:hover:bg-blue-950/30 text-foreground/80 hover:text-blue-600 rounded-lg text-xs font-semibold flex items-center justify-center gap-1.5 transition-all cursor-pointer"
                                    >
                                        <Plus className="w-4 h-4" />
                                        {t('add_option') || "Yangi variant qo'shish"}
                                    </button>
                                </div>
                            )}
                        </div>
                    )}

                    {/* Modal Footer */}
                    <DialogFooter className="flex items-center justify-end gap-3 pt-4 border-t border-border">
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
                            className="bg-blue-600 hover:bg-blue-700 text-white font-semibold shadow-sm"
                        >
                            {t('save')}
                        </Button>
                    </DialogFooter>

                </form>
            </DialogContent>
        </Dialog>
    );
}
