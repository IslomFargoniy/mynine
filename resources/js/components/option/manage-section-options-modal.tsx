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
                    toast.success(t('updated_successfully'));
                },
                onError: (err: any) => {
                    setProcessing(false);
                    const errorMessage = err?.error || t('update_failed');
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
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold btn-glass-primary hover:brightness-110 text-primary-foreground transition-colors cursor-pointer"
                    >
                        <Edit3 className="w-3.5 h-3.5" />
                        <span>{t('manage_incorrect_options')}</span>
                        {(section.options?.length ?? 0) > 0 && (
                            <span className="ml-1 px-1.5 py-0.2 rounded-full bg-white/20 text-[10px]">
                                {section.options?.length}
                            </span>
                        )}
                    </button>
                )}
            </DialogTrigger>

            <DialogContent className="sm:max-w-2xl w-full max-h-[85vh] flex flex-col p-0 overflow-hidden">
                {/* Header */}
                <div className="px-5 py-3 border-b border-divider shrink-0 flex items-center justify-between">
                    <div>
                        <DialogTitle className="text-base font-bold text-foreground flex items-center gap-2">
                            <span>{t('manage_incorrect_options')}</span>
                            <span className="px-2 py-0.5 rounded-full bg-indigo-500/12 text-brand text-xs font-semibold">
                                {t('options_form.variants_count', { count: currentCount })}
                            </span>
                        </DialogTitle>
                        <DialogDescription className="text-xs text-muted-foreground mt-0.5">
                            {t('options_form.description')}
                        </DialogDescription>
                    </div>
                </div>

                {/* Mode Selector Tabs */}
                <div className="px-5 pt-3 pb-1 border-b border-divider flex items-center justify-between gap-2 shrink-0">
                    <div className="glass-pill flex items-center gap-1 p-1">
                        <button
                            type="button"
                            onClick={handleSwitchToList}
                            className={`flex items-center gap-1.5 px-3 py-1 text-xs font-semibold rounded-full transition-colors ${
                                mode === 'list'
                                    ? 'bg-glass-thumb border border-glass-edge text-brand shadow-glass-pill'
                                    : 'border border-transparent text-muted-foreground hover:text-foreground'
                            }`}
                        >
                            <List className="w-3.5 h-3.5" />
                            <span>{t('list_mode')}</span>
                        </button>
                        <button
                            type="button"
                            onClick={handleSwitchToBulk}
                            className={`flex items-center gap-1.5 px-3 py-1 text-xs font-semibold rounded-full transition-colors ${
                                mode === 'bulk'
                                    ? 'bg-glass-thumb border border-glass-edge text-brand shadow-glass-pill'
                                    : 'border border-transparent text-muted-foreground hover:text-foreground'
                            }`}
                        >
                            <AlignLeft className="w-3.5 h-3.5" />
                            <span>{t('bulk_text_mode')}</span>
                        </button>
                    </div>

                    <button
                        type="button"
                        onClick={handleClearAll}
                        className="text-[11px] font-semibold text-rose-700 dark:text-rose-300 hover:text-rose-800 dark:hover:text-rose-200 px-2 py-1 hover:bg-rose-500/12 rounded-full transition-colors"
                    >
                        {t('clear_all_options')}
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
                                        className="flex items-center gap-2 p-1.5 rounded-xl bg-glass-subtle border border-glass-edge transition-all hover:border-ring"
                                    >
                                        {/* Letter badge */}
                                        <span className="w-6 h-6 shrink-0 rounded-lg bg-primary text-primary-foreground font-bold font-mono text-xs flex items-center justify-center">
                                            {letter}
                                        </span>

                                        {/* Input */}
                                        <Input
                                            type="text"
                                            value={optionText}
                                            onChange={(e) => handleRowChange(idx, e.target.value)}
                                            placeholder={`${t('option_row_placeholder')} (Masalan: vast range)`}
                                            className="h-8 text-xs flex-1"
                                            autoFocus={idx === optionsList.length - 1 && optionText === ''}
                                        />

                                        {/* Reorder Up/Down */}
                                        <div className="flex items-center gap-0.5 shrink-0">
                                            <button
                                                type="button"
                                                disabled={idx === 0}
                                                onClick={() => handleMoveRow(idx, 'up')}
                                                className="p-1 rounded-full text-muted-foreground hover:text-foreground disabled:opacity-30 disabled:pointer-events-none hover:bg-accent"
                                                title={t('options_form.move_up')}
                                                aria-label={t('options_form.move_up')}
                                            >
                                                <ArrowUp className="w-3.5 h-3.5" />
                                            </button>
                                            <button
                                                type="button"
                                                disabled={idx === optionsList.length - 1}
                                                onClick={() => handleMoveRow(idx, 'down')}
                                                className="p-1 rounded-full text-muted-foreground hover:text-foreground disabled:opacity-30 disabled:pointer-events-none hover:bg-accent"
                                                title={t('options_form.move_down')}
                                                aria-label={t('options_form.move_down')}
                                            >
                                                <ArrowDown className="w-3.5 h-3.5" />
                                            </button>
                                        </div>

                                        {/* Delete button */}
                                        <button
                                            type="button"
                                            onClick={() => handleRemoveRow(idx)}
                                            className="p-1 rounded-full text-rose-700 dark:text-rose-300 hover:text-rose-800 dark:hover:text-rose-200 hover:bg-rose-500/12 shrink-0 transition-colors"
                                            title={t('delete')}
                                            aria-label={t('delete')}
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
                                    className="w-full h-8 text-xs border-dashed border-glass-dash hover:border-ring hover:text-brand flex items-center justify-center gap-1.5"
                                >
                                    <Plus className="w-3.5 h-3.5" />
                                    <span>{t('add_option')}</span>
                                </Button>
                            </div>
                        </div>
                    ) : (
                        <div className="space-y-2">
                            <div className="text-xs text-muted-foreground flex items-center justify-between">
                                <span>{t('options_form.bulk_hint')}</span>
                                <span className="font-semibold text-brand">{t('options_form.lines_count', { count: currentCount })}</span>
                            </div>
                            <textarea
                                rows={9}
                                value={bulkText}
                                onChange={(e) => setBulkText(e.target.value)}
                                placeholder={t('options_bulk_placeholder')}
                                className="w-full rounded-xl border border-input bg-glass-subtle text-foreground focus:border-ring focus:ring-2 focus:ring-ring/40 p-3 font-mono text-xs leading-relaxed min-h-[220px] outline-none"
                            />
                            <p className="text-[11px] text-muted-foreground">
                                {t('options_form.tip')}
                            </p>
                        </div>
                    )}
                </form>

                {/* Footer */}
                <DialogFooter className="px-5 py-2.5 border-t border-divider shrink-0 flex items-center justify-end gap-2.5">
                    <DialogClose asChild>
                        <Button
                            type="button"
                            variant="outline"
                            className="h-8 text-xs"
                            onClick={() => setOpen(false)}
                        >
                            {t('cancel')}
                        </Button>
                    </DialogClose>

                    <Button
                        type="submit"
                        form="manage-options-form"
                        disabled={processing}
                        className="h-8 text-xs font-semibold flex items-center gap-1.5"
                    >
                        {processing ? (t('saving')) : (t('save_options'))}
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
