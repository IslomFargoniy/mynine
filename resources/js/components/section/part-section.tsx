import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Section } from '@/types';
import { useForm } from '@inertiajs/react';
import { toast } from 'sonner';
import { Edit, TrashIcon, ChevronDown, ChevronUp } from 'lucide-react';
import DeleteItemModal from '@/components/delete-item-modal';
import CreateQuestionModal from '@/components/question/create-question-modal';
import SectionQuestion from '@/components/question/section-question';
import UpdateSectionModal from '@/components/section/update-section-modal';
import { cleanTinyMce } from '@/utils/util';
import ManageSectionOptionsModal from '@/components/option/manage-section-options-modal';
import QuestionOpton from '@/components/option/question-option';

interface SectionUpdateProps {
    section: Section;
    partIndex: number;
    globalIndex: number;
    sectionIndex: number;
}

export default function PartSection({ section, globalIndex }: SectionUpdateProps) {
    const { t } = useTranslation();
    const [isOpen, setIsOpen] = useState(true);
    const [openDelete, setOpenDelete] = useState(false);
    const [openUpdate, setOpenUpdate] = useState(false);

    const { delete: deleteSection, reset, clearErrors } = useForm();

    const handleDelete = () => {
        deleteSection(route('section.destroy', section.id), {
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
            },
        });
    };

    const questionCount = section.questions?.length ?? 0;
    const questionRange = questionCount > 0
        ? `Q${globalIndex + 1}–${globalIndex + questionCount}`
        : t('no_questions') ?? 'No questions';

    const typeName = section.question_type?.name ?? section.question_type?.type ?? 'Section';

    return (
        <div className="glass-subtle rounded-[18px] overflow-hidden">

            {/* Section Header */}
            <div
                className="flex items-center gap-2 px-4 py-3 cursor-pointer select-none hover:bg-accent transition-colors"
                onClick={() => setIsOpen(!isOpen)}
            >
                {/* Section info */}
                <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                        <span className="inline-block px-2 py-0.5 text-[11px] font-semibold bg-indigo-500/12 text-brand rounded-full border border-indigo-500/25 whitespace-nowrap">
                            {typeName}
                        </span>
                        <span className="text-xs text-muted-foreground whitespace-nowrap">
                            {questionRange} · {questionCount} {t('question') ?? 'questions'}
                        </span>
                    </div>
                    {section.textarea && (
                        <p className="text-xs text-muted-foreground mt-0.5 truncate">
                            {section.textarea.replace(/<[^>]*>/g, '').trim().slice(0, 80)}
                        </p>
                    )}
                </div>

                {/* Actions */}
                <div className="flex items-center gap-1 shrink-0" onClick={e => e.stopPropagation()}>
                    <button
                        onClick={() => setOpenUpdate(true)}
                        className="p-1.5 rounded-full hover:bg-indigo-500/12 text-brand transition-colors"
                        title={t('edit') ?? 'Edit'}
                    >
                        <Edit className="w-3.5 h-3.5" />
                    </button>
                    <button
                        onClick={() => setOpenDelete(true)}
                        className="p-1.5 rounded-full hover:bg-rose-500/12 text-rose-700 dark:text-rose-300 transition-colors"
                        title={t('delete') ?? 'Delete'}
                    >
                        <TrashIcon className="w-3.5 h-3.5" />
                    </button>
                </div>

                {/* Chevron */}
                <div className="shrink-0 text-muted-foreground">
                    {isOpen ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                </div>
            </div>

            {/* Section Body */}
            {isOpen && (
                <div className="border-t border-divider px-4 py-3 space-y-3">
                    {/* Section instruction text */}
                    {section.textarea && (
                        <div
                            className="prose dark:prose-invert text-sm max-w-full leading-relaxed"
                            dangerouslySetInnerHTML={{ __html: cleanTinyMce(section.textarea) }}
                        />
                    )}

                    {/* Options (drag_and_drop) */}
                    {section.question_type?.type === 'drag_and_drop' && (
                        <div className="p-3 rounded-[18px] bg-muted border border-glass-edge space-y-2.5">
                            <div className="flex items-center justify-between flex-wrap gap-2">
                                <div className="flex items-center gap-2">
                                    <span className="text-xs font-bold uppercase tracking-wider text-foreground/80">
                                        {t('incorrect_options')}
                                    </span>
                                    <span className="px-2 py-0.5 rounded-full text-[11px] font-bold bg-glass-subtle border border-glass-edge text-foreground">
                                        {section.options?.length ?? 0} {t('option')}
                                    </span>
                                </div>

                                <ManageSectionOptionsModal section={section} />
                            </div>

                            {(section.options?.length ?? 0) > 0 ? (
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-1.5">
                                    {section.options?.map((option, oIndex) => (
                                        <QuestionOpton key={oIndex} option={option} index={oIndex} />
                                    ))}
                                </div>
                            ) : (
                                <div className="p-3 text-center rounded-[18px] border border-dashed border-glass-dash text-xs text-muted-foreground">
                                    {t('no_incorrect_options') || "Hozircha noto'g'ri variantlar qo'shilmagan"}
                                </div>
                            )}
                        </div>
                    )}

                    {/* Questions */}
                    {section.questions?.length > 0 && (
                        <div className="space-y-4">
                            {section.questions.map((question, qIndex) => {
                                globalIndex += (Number(question.is_correct_count) || 1);
                                return (
                                    <SectionQuestion
                                        key={qIndex}
                                        globalIndex={globalIndex}
                                        section={section}
                                        question={question}
                                        question_type={section.question_type}
                                        index={qIndex}
                                    />
                                );
                            })}
                        </div>
                    )}

                    {/* Add Question button */}
                    {section.question_type?.type !== 'complete_section' &&
                        section.question_type?.type !== 'drag_and_drop' && (
                            <div className="pt-1">
                                <CreateQuestionModal section={section} />
                            </div>
                        )}
                </div>
            )}

            {/* Modals */}
            {openUpdate && (
                <UpdateSectionModal section={section} open={openUpdate} setOpen={setOpenUpdate} />
            )}
            {openDelete && (
                <DeleteItemModal
                    item={section}
                    open={openDelete}
                    setOpen={setOpenDelete}
                    onDelete={handleDelete}
                />
            )}
        </div>
    );
}
