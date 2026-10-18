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

export default function TestTypeShow() {
    const { testType, question_types } = usePage<{
        testType: TestType;
        question_types: QuestionType[];
    }>().props;
    const { t } = useTranslation();

    const folder = testType.test?.folder;
    const test = testType.test;
    const type = testType.type;
    const folderName = folder?.name || t('folder') || 'Jild';
    const testName = test?.name || t('test') || 'Test';
    const typeName = type?.name || 'Module';

    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: t('folders') || 'Jildlar',
            href: route('folder.index'),
        },
        ...(folder?.id
            ? [
                  {
                      title: folderName,
                      href: route('folder.show', folder.id),
                  },
              ]
            : []),
        ...(test?.id
            ? [
                  {
                      title: testName,
                      href: folder?.id ? route('folder.show', folder.id) : route('folder.index'),
                  },
              ]
            : []),
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
            <div className="flex flex-col overflow-hidden" style={{ height: 'calc(100vh - 112px)' }}>

                {/* ══════════ STICKY SUBHEADER ══════════ */}
                <div className="flex-none flex items-center justify-between gap-3 px-4 py-2 bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700 z-30">
                    {/* Part pills */}
                    <div className="flex items-center gap-1.5 overflow-x-auto hide-scrollbar flex-1">
                        {parts.map((part: Part, idx: number) => (
                            <button
                                key={part.id}
                                onClick={() => setSelectedPartId(part.id)}
                                className={`px-4 py-1 rounded-full text-sm font-medium transition-all whitespace-nowrap border ${
                                    selectedPartId === part.id
                                        ? 'bg-blue-600 text-white border-blue-600 shadow-sm'
                                        : 'bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 border-gray-200 dark:border-gray-700 hover:border-blue-300 hover:text-blue-600'
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
                        className="shrink-0 flex items-center gap-1.5 px-3 py-1.5 bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-lg hover:bg-blue-600 hover:text-white transition-all font-semibold text-xs border border-blue-200 dark:border-blue-700 hover:border-blue-600 shadow-sm active:scale-95 cursor-pointer"
                    >
                        <Plus className="w-3.5 h-3.5" />
                        {t('add_part') ?? 'Add Part'}
                    </button>
                </div>

                {/* ══════════ MAIN PANELS ══════════ */}
                {selectedPart && (
                    <div className="flex flex-1 min-h-0 overflow-hidden">

                        {/* ── LEFT PANEL: Passage ── */}
                        {!isListening && (
                            <>
                                <div
                                    className="flex flex-col h-full bg-white dark:bg-gray-900 border-r border-gray-200 dark:border-gray-700 overflow-hidden"
                                    style={{ width: `${leftWidth}%` }}
                                >
                                    {/* Part header */}
                                    <div className="flex items-center justify-between px-4 py-2.5 border-b border-gray-100 dark:border-gray-800 bg-gray-50 dark:bg-gray-800 shrink-0">
                                        <h2 className="font-bold text-sm text-gray-800 dark:text-gray-100 truncate">
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
                                            <div className="flex flex-col items-center justify-center h-full text-gray-300 dark:text-gray-600 gap-2">
                                                <p className="text-sm">{t('no_passage') ?? 'No passage text yet.'}</p>
                                                <button
                                                    type="button"
                                                    onClick={() => setOpenEditPartModal(true)}
                                                    className="text-xs text-blue-500 hover:underline cursor-pointer"
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
                                    className="w-1.5 shrink-0 cursor-col-resize bg-gray-200 dark:bg-gray-700 hover:bg-blue-400 dark:hover:bg-blue-500 transition-colors z-10 flex items-center justify-center group"
                                >
                                    <div className="w-0.5 h-8 bg-gray-400 dark:bg-gray-500 rounded-full group-hover:bg-blue-500 transition-colors" />
                                </div>
                            </>
                        )}

                        {/* ── RIGHT PANEL: Sections ── */}
                        <div
                            className="flex flex-col h-full overflow-hidden bg-gray-50 dark:bg-gray-950"
                            style={{ width: isListening ? '100%' : `${100 - leftWidth - 0.4}%` }}
                        >
                            {/* Listening: part actions in right panel header */}
                            {isListening && (
                                <div className="flex items-center justify-between px-4 py-2.5 border-b border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 shrink-0">
                                    <h2 className="font-bold text-sm text-gray-800 dark:text-gray-100">
                                        {selectedPart.name}
                                    </h2>
                                    <PartComponent part={selectedPart} partIndex={ci} />
                                </div>
                            )}

                            {/* Section list */}
                            <div className="flex-1 overflow-y-auto p-4 space-y-3">
                                {selectedPart.sections.length === 0 ? (
                                    <div className="flex flex-col items-center justify-center h-48 text-gray-400 dark:text-gray-600 gap-2">
                                        <Plus className="w-10 h-10 opacity-20" />
                                        <p className="text-sm text-center">
                                            {t('no_sections') ?? 'No sections yet. Add a section below.'}
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
                            <div className="shrink-0 flex items-center gap-3 px-4 py-3 border-t border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900">
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
