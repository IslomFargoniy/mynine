import React, { useState } from 'react';
import { Option, QuestionType } from '@/types';
import { CheckCircle2, Edit2, Trash2 } from 'lucide-react';
import UpdateOptionModal from '@/components/option/update-option-modal';
import DeleteItemModal from '@/components/delete-item-modal';
import { useForm } from '@inertiajs/react';
import { useTranslation } from 'react-i18next';
import { toast } from 'sonner';

interface QuestionOptionProps {
    option: Option;
    index: number;
    question_type?: QuestionType;
}

export default function QuestionOption({ option, index, question_type }: QuestionOptionProps) {
    const { t } = useTranslation();
    const letter = String.fromCharCode(65 + index);
    const [openEdit, setOpenEdit] = useState(false);
    const [openDelete, setOpenDelete] = useState(false);

    const { delete: deleteOption } = useForm();

    const handleDelete = () => {
        deleteOption(route('option.destroy', option.id), {
            preserveScroll: true,
            onSuccess: () => {
                setOpenDelete(false);
                toast.success(t('deleted_successfully'));
            },
            onError: (err: any) => {
                const errorMessage = err?.error || t('delete_failed');
                toast.error(errorMessage);
            },
        });
    };

    return (
        <div className="group flex items-center justify-between py-1.5 px-3 rounded-xl bg-muted border border-glass-edge text-sm hover:border-indigo-500/25 transition-colors">
            <div className="flex items-center gap-2 min-w-0 flex-1">
                <span className="w-5 h-5 rounded-md font-bold font-mono text-[11px] bg-foreground/10 text-foreground flex items-center justify-center shrink-0">
                    {letter}
                </span>
                <span className="text-foreground font-medium truncate text-xs">
                    {option.textarea}
                </span>
            </div>

            <div className="flex items-center gap-1.5 shrink-0">
                {Boolean(option.is_correct) && (
                    <span
                        className="inline-flex items-center justify-center p-1 rounded-full bg-emerald-500/12 dark:bg-emerald-400/15 text-emerald-800 dark:text-emerald-200 border border-emerald-500/25 shrink-0"
                        title={t('is_correct') || "To'g'ri"}
                    >
                        <CheckCircle2 className="w-3.5 h-3.5" />
                    </span>
                )}

                <div className="flex items-center gap-0.5 opacity-80 group-hover:opacity-100 transition-opacity">
                    <button
                        type="button"
                        onClick={() => setOpenEdit(true)}
                        className="p-1 rounded-full text-muted-foreground hover:text-brand hover:bg-indigo-500/12 transition-colors"
                        title={t('edit') || "Tahrirlash"}
                    >
                        <Edit2 className="w-3 h-3" />
                    </button>
                    <button
                        type="button"
                        onClick={() => setOpenDelete(true)}
                        className="p-1 rounded-full text-muted-foreground hover:text-rose-700 dark:hover:text-rose-300 hover:bg-rose-500/12 transition-colors"
                        title={t('delete') || "O'chirish"}
                    >
                        <Trash2 className="w-3 h-3" />
                    </button>
                </div>
            </div>

            {openEdit && (
                <UpdateOptionModal
                    option={option}
                    question_type={question_type}
                    open={openEdit}
                    setOpen={setOpenEdit}
                />
            )}

            {openDelete && (
                <DeleteItemModal
                    item={option}
                    open={openDelete}
                    setOpen={setOpenDelete}
                    onDelete={handleDelete}
                />
            )}
        </div>
    );
}
