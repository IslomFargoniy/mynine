import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Question, QuestionType, Section } from '@/types';
import { useForm } from '@inertiajs/react';
import { toast } from 'sonner';
import { Edit, TrashIcon } from 'lucide-react';
import DeleteItemModal from '@/components/delete-item-modal';
import QuestionOption from '@/components/option/question-option';
import UpdateQuestionModal from '@/components/question/update-question-modal';

interface SectionUpdateProps {
    question: Question;
    section: Section;
    question_type: QuestionType;
    index: number;
    globalIndex: number;
}

export default function SectionQuestion({
    question,
    section,
    question_type,
    globalIndex
}: SectionUpdateProps) {
    const { t } = useTranslation();
    const [openDelete, setOpenDelete] = useState(false);
    const [openUpdate, setOpenUpdate] = useState(false);

    const { delete: deleteQuestion, reset, clearErrors } = useForm();

    const handleDelete = () => {
        deleteQuestion(route('question.destroy', question.id), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpenDelete(false);
                toast.success(t('deleted_successfully'));
            },
            onError: (err) => {
                const errorMessage = err?.error || t('delete_failed');
                toast.error(errorMessage);
            }
        });
    };

    const questionNumberStr = (() => {
        const count = Number(question.is_correct_count) || 1;
        const numIndex = Number(globalIndex) || 1;
        return count > 1
            ? Array.from({ length: count }, (_, i) => numIndex - count + 1 + i).join('-')
            : numIndex;
    })();

    return (
        <div className="p-4 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 shadow-2xs space-y-3">
            {/* Header: Question Number, Prompt & Action Buttons */}
            <div className="flex items-start justify-between gap-3">
                <div className="flex-1 min-w-0">
                    <h3 className="font-bold text-sm text-gray-900 dark:text-gray-100 leading-snug">
                        <span className="text-blue-600 dark:text-blue-400 mr-1.5">{questionNumberStr}.</span>
                        {question.textarea}
                    </h3>

                    {question.answer_text && (
                        <div className="mt-1.5 inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-md bg-blue-50 dark:bg-blue-950/60 text-blue-700 dark:text-blue-300 text-xs font-semibold border border-blue-100 dark:border-blue-800">
                            <span>Javob:</span>
                            <span className="font-mono">{question.answer_text}</span>
                        </div>
                    )}
                </div>

                {/* Question Actions (Edit, Delete) */}
                <div className="flex items-center gap-1 shrink-0">
                    <button
                        onClick={() => setOpenUpdate(true)}
                        className="p-1.5 rounded-lg hover:bg-blue-50 dark:hover:bg-blue-900/30 text-blue-600 dark:text-blue-400 transition-colors"
                        title={t('edit') ?? 'Tahrirlash'}
                    >
                        <Edit className="w-4 h-4" />
                    </button>
                    <button
                        onClick={() => setOpenDelete(true)}
                        className="p-1.5 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/30 text-red-500 dark:text-red-400 transition-colors"
                        title={t('delete') ?? "O'chirish"}
                    >
                        <TrashIcon className="w-4 h-4" />
                    </button>
                </div>
            </div>

            {/* Options List (Clean, no individual buttons) */}
            {question.options && question.options.length > 0 && (
                <div className="space-y-1.5 pt-1">
                    {question.options.map((option, oIndex) => (
                        <QuestionOption
                            key={option.id ?? oIndex}
                            option={option}
                            index={oIndex}
                            question_type={question_type}
                        />
                    ))}
                </div>
            )}

            {/* Modals */}
            {openUpdate && (
                <UpdateQuestionModal
                    question={question}
                    section={section}
                    open={openUpdate}
                    setOpen={setOpenUpdate}
                />
            )}
            {openDelete && (
                <DeleteItemModal
                    item={question}
                    open={openDelete}
                    setOpen={setOpenDelete}
                    onDelete={handleDelete}
                />
            )}
        </div>
    );
}
