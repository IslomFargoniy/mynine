import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Section, Option } from '@/types';
import { router } from '@inertiajs/react';
import { toast } from 'sonner';
import {
    Dialog,
    DialogClose,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogTitle,
    DialogTrigger,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Plus, Trash2, Edit3, AlignLeft, List, ArrowUp, ArrowDown } from 'lucide-react';

interface ManageSectionOptionsModalProps {
    section: Section;
    trigger?: React.ReactNode;
}

export default function ManageSectionOptionsModal({
    section,
    trigger,
}: ManageSectionOptionsModalProps) {
    const { t } = useTranslation();
    const [open, setOpen] = useState(false);
    const [mode, setMode] = useState<'list' | 'bulk'>('list');
    const [optionsList, setOptionsList] = useState<string[]>([]);
    const [bulkText, setBulkText] = useState<string>('');
    const [processing, setProcessing] = useState(false);

    // Initial populate from section.options
    useEffect(() => {
        if (open) {
            const initial = (section.options || []).map((o: Option) => o.textarea || '');
            setOptionsList(initial.length > 0 ? initial : ['']);
            setBulkText(initial.join('\n'));
        }
    }, [open, section.options]);

    // When switching to Bulk mode, sync from List
    const handleSwitchToBulk = () => {
        const text = optionsList.filter(o => o.trim() !== '').join('\n');
        setBulkText(text);
        setMode('bulk');
    };

    // When switching to List mode, sync from Bulk
    const handleSwitchToList = () => {
        const parsed = bulkText
            .split('\n')
            .map(line => line.replace(/^[A-Z0-9]+[.)\-:\s]+/i, '').trim())
            .filter(line => line !== '');
        setOptionsList(parsed.length > 0 ? parsed : ['']);
        setMode('list');
    };

    const handleAddRow = () => {
        setOptionsList(prev => [...prev, '']);
    };

    const handleRemoveRow = (index: number) => {
        setOptionsList(prev => {
            const next = prev.filter((_, i) => i !== index);
            return next.length > 0 ? next : [''];
        });
    };

    const handleMoveRow = (index: number, direction: 'up' | 'down') => {
        setOptionsList(prev => {
            const next = [...prev];
            const targetIndex = direction === 'up' ? index - 1 : index + 1;
            if (targetIndex < 0 || targetIndex >= next.length) return prev;
            const temp = next[index];
            next[index] = next[targetIndex];
            next[targetIndex] = temp;
            return next;
        });
    };

    const handleRowChange = (index: number, val: string) => {
        setOptionsList(prev => {
            const next = [...prev];
            next[index] = val;
            return next;
        });
    };

    const handleClearAll = () => {
        setOptionsList(['']);
        setBulkText('');
    };

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        setProcessing(true);

        // Get final list of non-empty options
        let finalOptions: string[] = [];
        if (mode === 'bulk') {
            finalOptions = bulkText
                .split('\n')
                .map(line => line.replace(/^[A-Z0-9]+[.)\-:\s]+/i, '').trim())
                .filter(line => line !== '');
        } else {
            finalOptions = optionsList.map(o => o.trim()).filter(o => o !== '');
        }

        router.post(
            route('section.options.sync', section.id),
            { options: finalOptions },
            {
                preserveScroll: true,
                onSuccess: () => {
                    setProcessing(false);
                    setOpen(false);
                    toast.success(t('updated_successfully') || "Variantlar muvaffaqiyatli saqlandi!");
                },
                onError: (err: any) => {
                    setProcessing(false);
                    const errorMessage = err?.error || t('update_failed') || "Xatolik yuz berdi";
                    toast.error(errorMessage);
                },
            }
        );
    };

    const currentCount = mode === 'bulk'
        ? bulkText.split('\n').filter(l => l.trim() !== '').length
        : optionsList.filter(o => o.trim() !== '').length;

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                {trigger ? (
                    trigger
                ) : (
                    <button
                        type="button"
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold bg-blue-600 hover:bg-blue-700 text-white shadow-xs transition-colors cursor-pointer"
                    >
                        <Edit3 className="w-3.5 h-3.5" />
                        <span>{t('manage_incorrect_options') || "Noto'g'ri variantlarni boshqarish / tahrirlash"}</span>
                        {(section.options?.length ?? 0) > 0 && (
                            <span className="ml-1 px-1.5 py-0.2 rounded-full bg-blue-800 text-[10px]">
                                {section.options?.length}
                            </span>
                        )}
                    </button>
                )}
            </DialogTrigger>

            <DialogContent className="sm:max-w-2xl w-full max-h-[85vh] flex flex-col p-0 overflow-hidden dark:border-gray-700">
                {/* Header */}
                <div className="px-5 py-3 border-b border-gray-100 dark:border-gray-800 shrink-0 bg-white dark:bg-gray-900 flex items-center justify-between">
                    <div>
                        <DialogTitle className="text-base font-bold text-gray-900 dark:text-gray-100 flex items-center gap-2">
                            <span>{t('manage_incorrect_options') || "Noto'g'ri variantlar (Distractors)"}</span>
                            <span className="px-2 py-0.5 rounded-full bg-blue-100 dark:bg-blue-900/60 text-blue-800 dark:text-blue-200 text-xs font-semibold">
                                {currentCount} ta variant
                            </span>
                        </DialogTitle>
                        <DialogDescription className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                            Sudrab joylashtirish (Drag & Drop) uchun barcha qo'shimcha chalg'ituvchi variantlarni bitta joyda kiriting va tahrirlang.
                        </DialogDescription>
                    </div>
                </div>

                {/* Mode Selector Tabs */}
                <div className="px-5 pt-3 pb-1 border-b border-gray-100 dark:border-gray-800 flex items-center justify-between gap-2 bg-gray-50/70 dark:bg-gray-900/50 shrink-0">
                    <div className="flex items-center gap-1.5 p-0.5 bg-gray-200/70 dark:bg-gray-800 rounded-lg">
                        <button
                            type="button"
                            onClick={handleSwitchToList}
                            className={`flex items-center gap-1.5 px-3 py-1 text-xs font-semibold rounded-md transition-colors ${
                                mode === 'list'
                                    ? 'bg-white dark:bg-gray-700 text-blue-600 dark:text-blue-400 shadow-xs'
                                    : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200'
                            }`}
                        >
                            <List className="w-3.5 h-3.5" />
                            <span>{t('list_mode') || "Ro'yxat ko'rinishi"}</span>
                        </button>
                        <button
                            type="button"
                            onClick={handleSwitchToBulk}
                            className={`flex items-center gap-1.5 px-3 py-1 text-xs font-semibold rounded-md transition-colors ${
                                mode === 'bulk'
                                    ? 'bg-white dark:bg-gray-700 text-blue-600 dark:text-blue-400 shadow-xs'
                                    : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200'
                            }`}
                        >
                            <AlignLeft className="w-3.5 h-3.5" />
                            <span>{t('bulk_text_mode') || "Tezkor matn orqali kiritish"}</span>
                        </button>
                    </div>

                    <button
                        type="button"
                        onClick={handleClearAll}
                        className="text-[11px] font-semibold text-red-500 hover:text-red-700 dark:hover:text-red-400 px-2 py-1 hover:bg-red-50 dark:hover:bg-red-950/40 rounded transition-colors"
                    >
                        {t('clear_all_options') || "Barchasini tozalash"}
                    </button>
                </div>

                {/* Form Body */}
                <form onSubmit={handleSubmit} id="manage-options-form" className="flex-1 overflow-y-auto px-5 py-3">
                    {mode === 'list' ? (
                        <div className="space-y-2">
                            {optionsList.map((optionText, idx) => {
                                const letter = String.fromCharCode(65 + idx);
                                return (
                                    <div
                                        key={idx}
                                        className="flex items-center gap-2 p-1.5 rounded-lg bg-gray-50 dark:bg-gray-800/60 border border-gray-200 dark:border-gray-700 transition-all hover:border-blue-300 dark:hover:border-blue-700"
                                    >
                                        {/* Letter badge */}
                                        <span className="w-6 h-6 shrink-0 rounded-md bg-blue-600 text-white dark:bg-blue-500 font-bold font-mono text-xs flex items-center justify-center">
                                            {letter}
                                        </span>

                                        {/* Input */}
                                        <Input
                                            type="text"
                                            value={optionText}
                                            onChange={(e) => handleRowChange(idx, e.target.value)}
                                            placeholder={`${t('option_row_placeholder') || "Variant matnini kiriting..."} (Masalan: vast range)`}
                                            className="h-8 text-xs flex-1 bg-white dark:bg-gray-900"
                                            autoFocus={idx === optionsList.length - 1 && optionText === ''}
                                        />

                                        {/* Reorder Up/Down */}
                                        <div className="flex items-center gap-0.5 shrink-0">
                                            <button
                                                type="button"
                                                disabled={idx === 0}
                                                onClick={() => handleMoveRow(idx, 'up')}
                                                className="p-1 rounded text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 disabled:opacity-30 disabled:pointer-events-none hover:bg-gray-200 dark:hover:bg-gray-700"
                                                title="Yuqoriga surish"
                                            >
                                                <ArrowUp className="w-3.5 h-3.5" />
                                            </button>
                                            <button
                                                type="button"
                                                disabled={idx === optionsList.length - 1}
                                                onClick={() => handleMoveRow(idx, 'down')}
                                                className="p-1 rounded text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 disabled:opacity-30 disabled:pointer-events-none hover:bg-gray-200 dark:hover:bg-gray-700"
                                                title="Pastga surish"
                                            >
                                                <ArrowDown className="w-3.5 h-3.5" />
                                            </button>
                                        </div>

                                        {/* Delete button */}
                                        <button
                                            type="button"
                                            onClick={() => handleRemoveRow(idx)}
                                            className="p-1 rounded text-red-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-950/50 shrink-0 transition-colors"
                                            title="O'chirish"
                                        >
                                            <Trash2 className="w-3.5 h-3.5" />
                                        </button>
                                    </div>
                                );
                            })}

                            <div className="pt-2">
                                <Button
                                    type="button"
                                    variant="outline"
                                    onClick={handleAddRow}
                                    className="w-full h-8 text-xs border-dashed border-gray-300 dark:border-gray-700 hover:border-blue-500 hover:text-blue-600 flex items-center justify-center gap-1.5"
                                >
                                    <Plus className="w-3.5 h-3.5" />
                                    <span>{t('add_option') || "Yangi variant qatori qo'shish"}</span>
                                </Button>
                            </div>
                        </div>
                    ) : (
                        <div className="space-y-2">
                            <div className="text-xs text-gray-500 dark:text-gray-400 flex items-center justify-between">
                                <span>Har bir variantni alohida yangi qatordan yozing yoki nusxalab qo'ying:</span>
                                <span className="font-semibold text-blue-600 dark:text-blue-400">{currentCount} ta qator</span>
                            </div>
                            <textarea
                                rows={9}
                                value={bulkText}
                                onChange={(e) => setBulkText(e.target.value)}
                                placeholder={t('options_bulk_placeholder')}
                                className="w-full rounded-lg border border-gray-300 bg-white p-3 font-mono text-xs leading-relaxed min-h-[220px] dark:border-gray-700 dark:bg-gray-900 dark:text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500/20 shadow-xs outline-none"
                            />
                            <p className="text-[11px] text-gray-400">
                                💡 Maslahat: Har bir qatorda bittadan noto'g'ri so'z/ibora yoziladi. Prefikslar (A), 1.) avtomatik tozalanadi.
                            </p>
                        </div>
                    )}
                </form>

                {/* Footer */}
                <DialogFooter className="px-5 py-2.5 border-t border-gray-100 dark:border-gray-800 shrink-0 bg-gray-50/90 dark:bg-gray-900 flex items-center justify-end gap-2.5">
                    <DialogClose asChild>
                        <Button
                            type="button"
                            variant="outline"
                            className="h-8 text-xs border-gray-300 dark:border-gray-700"
                            onClick={() => setOpen(false)}
                        >
                            {t('cancel') || "Bekor qilish"}
                        </Button>
                    </DialogClose>

                    <Button
                        type="submit"
                        form="manage-options-form"
                        disabled={processing}
                        className="h-8 text-xs bg-blue-600 hover:bg-blue-700 text-white font-semibold shadow-xs flex items-center gap-1.5"
                    >
                        {processing ? (t('saving') || "Saqlanmoqda...") : (t('save_options') || "Barchasini saqlash")}
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
