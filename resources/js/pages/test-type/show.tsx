import AppLayout from '@/layouts/app-layout';
import { Head, usePage } from '@inertiajs/react';
import { type BreadcrumbItem, Part, QuestionType, Section, TestType } from '@/types';
import { Plus } from 'lucide-react';
import { useState } from 'react';
import React from 'react';
import { useTranslation } from 'react-i18next';
import CreateSectionModal from '@/components/section/create-section-modal';
import PartSection from '@/components/section/part-section';
import PartComponent from '@/components/part/part';
import ImportAiModal from '@/components/part/import-ai-modal';
import PartModal from '@/components/part/part-modal';
import { cleanTinyMce } from '@/utils/util';
import { contentBreadcrumbs } from '@/lib/content-breadcrumbs';

export default function TestTypeShow() {
    const { testType, question_types } = usePage<{
        testType: TestType;
        question_types: QuestionType[];
    }>().props;
    const { t } = useTranslation();

    const test = testType.test;
    const type = testType.type;
    const testName = test?.name || t('test');
    const typeName = type?.name || 'Module';

    const breadcrumbs: BreadcrumbItem[] = [
        ...contentBreadcrumbs(test, t),
        {
            title: typeName,
            href: route('test-type.show', testType.id),
        },
    ];

    const [selectedPartId, setSelectedPartId] = useState<number>(
        testType.parts?.[0]?.id ?? 0
    );
    const [leftWidth, setLeftWidth] = useState<number>(50);
    const [openCreatePartModal, setOpenCreatePartModal] = useState<boolean>(false);
    const [openEditPartModal, setOpenEditPartModal] = useState<boolean>(false);

    const startResize = (mouseDownEvent: React.MouseEvent) => {
        mouseDownEvent.preventDefault();
        const startX = mouseDownEvent.clientX;
        const startWidth = leftWidth;
        const container = mouseDownEvent.currentTarget.parentElement;
        if (!container) return;
        const containerWidth = container.getBoundingClientRect().width || window.innerWidth;

        const doDrag = (mouseMoveEvent: MouseEvent) => {
            const deltaX = mouseMoveEvent.clientX - startX;
            const newPct = startWidth + (deltaX / containerWidth) * 100;
            setLeftWidth(Math.max(25, Math.min(75, newPct)));
        };
        const stopDrag = () => {
            document.removeEventListener('mousemove', doDrag);
            document.removeEventListener('mouseup', stopDrag);
        };
        document.addEventListener('mousemove', doDrag);
        document.addEventListener('mouseup', stopDrag);
    };

    const parts: Part[] = testType.parts ?? [];
    const ci = parts.findIndex(p => p.id === selectedPartId);
    const selectedPart: Part | null = parts[ci] ?? parts[0] ?? null;
    const isListening = testType.type?.name === 'Listening';

    let order = Number(selectedPart?.order ?? 0);

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={`${testName} - ${typeName}`} />

            {/* Full-height flex column inside AppLayout content */}
            <div className="glass-strong flex flex-col overflow-hidden rounded-[22px]" style={{ height: 'calc(100vh - 112px)' }}>

                {/* ══════════ STICKY SUBHEADER ══════════ */}
                <div className="flex-none flex items-center justify-between gap-3 px-4 py-2 border-b border-divider z-30">
                    {/* Part pills */}
                    <div className="flex items-center gap-1.5 overflow-x-auto hide-scrollbar flex-1">
                        {parts.map((part: Part, idx: number) => (
                            <button
                                key={part.id}
                                onClick={() => setSelectedPartId(part.id)}
                                className={`px-4 py-1 rounded-full text-sm font-medium transition-all whitespace-nowrap border ${
                                    selectedPartId === part.id
                                        ? 'bg-primary text-primary-foreground border-transparent shadow-glass-pill font-semibold'
                                        : 'bg-glass-subtle text-foreground border-glass-edge hover:bg-accent hover:text-brand'
                                }`}
                            >
                                {part.name || `Part ${idx + 1}`}
                            </button>
                        ))}
                    </div>

                    {/* Add Part Button (Opens Full-Screen PartModal) */}
                    <button
                        type="button"
                        onClick={() => setOpenCreatePartModal(true)}
                        className="shrink-0 flex items-center gap-1.5 px-3 py-1.5 bg-indigo-500/12 text-brand rounded-full hover:bg-primary hover:text-primary-foreground transition-all font-semibold text-xs border border-indigo-500/25 hover:border-ring active:scale-95 cursor-pointer"
                    >
                        <Plus className="w-3.5 h-3.5" />
                        {t('add_part')}
                    </button>
                </div>

                {/* ══════════ MAIN PANELS ══════════ */}
                {selectedPart && (
                    <div className="flex flex-1 min-h-0 overflow-hidden">

                        {/* ── LEFT PANEL: Passage ── */}
                        {!isListening && (
                            <>
                                <div
                                    className="flex flex-col h-full border-r border-divider overflow-hidden"
                                    style={{ width: `${leftWidth}%` }}
                                >
                                    {/* Part header */}
                                    <div className="flex items-center justify-between px-4 py-2.5 border-b border-divider bg-muted shrink-0">
                                        <h2 className="font-bold text-sm text-foreground truncate">
                                            {selectedPart.name}
                                        </h2>
                                        <PartComponent part={selectedPart} partIndex={ci} testType={testType} />
                                    </div>
                                    {/* Passage HTML */}
                                    <div className="flex-1 overflow-y-auto p-4">
                                        {selectedPart.textarea ? (
                                            <div
                                                className="prose dark:prose-invert text-base/8 max-w-full ielts-passage"
                                                dangerouslySetInnerHTML={{ __html: cleanTinyMce(selectedPart.textarea) }}
                                            />
                                        ) : (
                                            <div className="flex flex-col items-center justify-center h-full text-muted-foreground gap-2">
                                                <p className="text-sm">{t('no_passage')}</p>
                                                <button
                                                    type="button"
                                                    onClick={() => setOpenEditPartModal(true)}
                                                    className="text-xs text-brand hover:underline cursor-pointer"
                                                >
                                                    {t('edit')} {t('part')}
                                                </button>
                                            </div>
                                        )}
                                    </div>
                                </div>

                                {/* Drag handle */}
                                <div
                                    onMouseDown={startResize}
                                    className="w-1.5 shrink-0 cursor-col-resize bg-foreground/10 hover:bg-primary/60 transition-colors z-10 flex items-center justify-center group"
                                >
                                    <div className="w-0.5 h-8 bg-muted-foreground/50 rounded-full group-hover:bg-primary transition-colors" />
                                </div>
                            </>
                        )}

                        {/* ── RIGHT PANEL: Sections ── */}
                        <div
                            className="flex flex-col h-full overflow-hidden"
                            style={{ width: isListening ? '100%' : `${100 - leftWidth - 0.4}%` }}
                        >
                            {/* Listening: part actions in right panel header */}
                            {isListening && (
                                <div className="flex items-center justify-between px-4 py-2.5 border-b border-divider bg-muted shrink-0">
                                    <h2 className="font-bold text-sm text-foreground">
                                        {selectedPart.name}
                                    </h2>
                                    <PartComponent part={selectedPart} partIndex={ci} />
                                </div>
                            )}

                            {/* Section list */}
                            <div className="flex-1 overflow-y-auto p-4 space-y-3">
                                {selectedPart.sections.length === 0 ? (
                                    <div className="flex flex-col items-center justify-center h-48 text-muted-foreground gap-2">
                                        <Plus className="w-10 h-10 opacity-20" />
                                        <p className="text-sm text-center">
                                            {t('no_sections')}
                                        </p>
                                    </div>
                                ) : (
                                    selectedPart.sections.map((section: Section, sectionIndex: number) => {
                                        const sectionCount = section.questions.reduce(
                                            (acc, q) => acc + (Number(q.is_correct_count) || 1),
                                            0
                                        );
                                        const globalIndex = order;
                                        const element = (
                                            <PartSection
                                                key={section.id}
                                                globalIndex={globalIndex}
                                                section={section}
                                                partIndex={ci}
                                                sectionIndex={sectionIndex}
                                            />
                                        );
                                        order += sectionCount;
                                        return element;
                                    })
                                )}
                            </div>

                            {/* Sticky bottom toolbar */}
                            <div className="shrink-0 flex items-center gap-3 px-4 py-3 border-t border-divider">
                                <CreateSectionModal part={selectedPart} question_types={question_types} />
                                <ImportAiModal part={selectedPart} />
                            </div>
                        </div>
                    </div>
                )}

                {/* Full-Screen Modals for Create Part & Edit Part */}
                {openCreatePartModal && (
                    <PartModal
                        testType={testType}
                        open={openCreatePartModal}
                        setOpen={setOpenCreatePartModal}
                    />
                )}

                {openEditPartModal && selectedPart && (
                    <PartModal
                        testType={testType}
                        part={selectedPart}
                        open={openEditPartModal}
                        setOpen={setOpenEditPartModal}
                    />
                )}

            </div>
        </AppLayout>
    );
}
