import { Head, router, usePage } from '@inertiajs/react';
import { Attempt, Part, Question, Section, TestType } from '@/types';
import { useTranslation } from 'react-i18next';
import React, { ReactElement, useEffect, useState, useMemo, useCallback } from 'react';
import PracticePart from '@/components/practice/practice-part';
import PracticeSection from '@/components/practice/practice-section';
import PracticeEssay from '@/components/practice/practice-essay';
import PracticeNumberBar from '@/components/practice/practice-number-bar';
import InsperaHeader from '@/components/practice/inspera-header';

import { CheckIcon } from 'lucide-react';





import FinishConfirmationModal from '@/components/practice/finish-confirmation-modal';
import SoundCheckModal from '@/components/practice/sound-check-modal';
import { useExamIntegrity } from '@/hooks/use-exam-integrity';
import { useExamHotkeys } from '@/hooks/use-exam-hotkeys';
import { syncQueue } from '@/services/sync-queue';

export default function Practice() {
    const { attempt } = usePage<{ attempt: Attempt }>().props;
    const { t } = useTranslation();

    const [resAttempt, setResAttempt] = useState<Attempt | null>(null);
    const [testType, setTestType] = useState<TestType | null>(null);
    const [selectedPart, setSelectedPart] = useState<Part | null>(null);
    const [isTimeUp, setIsTimeUp] = useState<boolean>(false);
    const [flaggedIds, setFlaggedIds] = useState<Set<number>>(new Set());
    const [serverTimeOffset, setServerTimeOffset] = useState<number>(0);
    const [isLoading, setIsLoading] = useState<boolean>(false);
    const [leftWidth, setLeftWidth] = useState<number>(50); // percentage
    const [mobileTab, setMobileTab] = useState<'passage' | 'questions'>('questions');
    const [activeQuestionId, setActiveQuestionId] = useState<number | null>(null);

    // Sound Check Modal State
    const [isSoundCheckOpen, setIsSoundCheckOpen] = useState<boolean>(false);
    const [pendingTypeId, setPendingTypeId] = useState<number | null>(null);

    // Finish Confirmation Modal State
    const [isFinishModalOpen, setIsFinishModalOpen] = useState<boolean>(false);
    const [isFullExamSubmit, setIsFullExamSubmit] = useState<boolean>(false);
    const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

    // Anti-Cheat & Exam Integrity Hook
    const {
        violationsCount,
        isFullscreen,
        showWarningModal,
        closeWarningModal,
        toggleFullscreen,
    } = useExamIntegrity({
        attemptId: attempt.id,
        initialViolations: attempt.tab_switch_count || 0,
        enabled: !!selectedPart,
    });

    // Disable global dark mode on practice page so site theme doesn't ruin practice contrast
    useEffect(() => {
        const root = document.documentElement;
        const hadDarkClass = root.classList.contains('dark');

        root.classList.remove('dark');

        const observer = new MutationObserver(() => {
            if (root.classList.contains('dark')) {
                root.classList.remove('dark');
            }
        });

        observer.observe(root, { attributes: true, attributeFilter: ['class'] });

        return () => {
            observer.disconnect();
            if (hadDarkClass) {
                root.classList.add('dark');
            }
        };
    }, []);

    // Accessibility States (localStorage backed)
    const [textSize, setTextSizeState] = useState<'normal' | 'large' | 'xlarge'>(() => {
        return (localStorage.getItem('ielts_player_text_size') as any) || 'normal';
    });
    const [colorScheme, setColorSchemeState] = useState<'standard' | 'yellow-black' | 'blue-white'>(() => {
        return (localStorage.getItem('ielts_player_color_scheme') as any) || 'standard';
    });

    const setTextSize = (size: 'normal' | 'large' | 'xlarge') => {
        setTextSizeState(size);
        localStorage.setItem('ielts_player_text_size', size);
    };

    const setColorScheme = (scheme: 'standard' | 'yellow-black' | 'blue-white') => {
        setColorSchemeState(scheme);
        localStorage.setItem('ielts_player_color_scheme', scheme);
    };

    const startResize = (mouseDownEvent: React.MouseEvent) => {
        mouseDownEvent.preventDefault();

        const startX = mouseDownEvent.clientX;
        const startWidth = leftWidth;
        const container = mouseDownEvent.currentTarget.parentElement;
        if (!container) return;
        const containerWidth = container.getBoundingClientRect().width || window.innerWidth;

        const doDrag = (mouseMoveEvent: MouseEvent) => {
            const deltaX = mouseMoveEvent.clientX - startX;
            const newWidthPercent = startWidth + (deltaX / containerWidth) * 100;
            setLeftWidth(Math.max(25, Math.min(75, newWidthPercent)));
        };

        const stopDrag = () => {
            document.removeEventListener('mousemove', doDrag);
            document.removeEventListener('mouseup', stopDrag);
        };

        document.addEventListener('mousemove', doDrag);
        document.addEventListener('mouseup', stopDrag);
    };

    const toggleFlag = useCallback((id: number) => {
        setFlaggedIds((prev) => {
            const next = new Set(prev);
            if (next.has(id)) next.delete(id);
            else next.add(id);
            return next;
        });
    }, []);

    // Flatten all questions in the current part for keyboard navigation
    const allQuestions = useMemo(() => {
        const list: Question[] = [];
        selectedPart?.sections?.forEach((sec) => {
            sec.questions?.forEach((q) => list.push(q));
        });
        return list;
    }, [selectedPart]);

    const navigateToQuestion = useCallback((qId: number) => {
        setActiveQuestionId(qId);
        const el = document.getElementById(`question-${qId}`);
        if (el) {
            el.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
    }, []);

    const handleNextQuestion = useCallback(() => {
        if (allQuestions.length === 0) return;
        if (!activeQuestionId) {
            navigateToQuestion(allQuestions[0].id);
            return;
        }
        const currentIndex = allQuestions.findIndex((q) => q.id === activeQuestionId);
        if (currentIndex !== -1 && currentIndex < allQuestions.length - 1) {
            navigateToQuestion(allQuestions[currentIndex + 1].id);
        } else if (currentIndex === allQuestions.length - 1 && testType?.parts) {
            const ci = testType.parts.findIndex((p) => p.id === selectedPart?.id);
            if (ci !== -1 && ci < testType.parts.length - 1) {
                handlePart(testType.parts[ci + 1].id);
            }
        }
    }, [allQuestions, activeQuestionId, navigateToQuestion, testType, selectedPart]);

    const handlePrevQuestion = useCallback(() => {
        if (allQuestions.length === 0) return;
        if (!activeQuestionId) {
            navigateToQuestion(allQuestions[0].id);
            return;
        }
        const currentIndex = allQuestions.findIndex((q) => q.id === activeQuestionId);
        if (currentIndex > 0) {
            navigateToQuestion(allQuestions[currentIndex - 1].id);
        } else if (currentIndex === 0 && testType?.parts) {
            const ci = testType.parts.findIndex((p) => p.id === selectedPart?.id);
            if (ci > 0) {
                handlePart(testType.parts[ci - 1].id);
            }
        }
    }, [allQuestions, activeQuestionId, navigateToQuestion, testType, selectedPart]);

    const handleToggleCurrentFlag = useCallback(() => {
        if (activeQuestionId) {
            toggleFlag(activeQuestionId);
        } else if (allQuestions.length > 0) {
            toggleFlag(allQuestions[0].id);
        }
    }, [activeQuestionId, allQuestions, toggleFlag]);

    // Keyboard Shortcuts Hook
    useExamHotkeys({
        onNextQuestion: handleNextQuestion,
        onPrevQuestion: handlePrevQuestion,
        onToggleFlag: handleToggleCurrentFlag,
        enabled: !!selectedPart,
    });

    const startTestType = (typeId: number, isListening: boolean) => {
        if (isListening) {
            setPendingTypeId(typeId);
            setIsSoundCheckOpen(true);
        } else {
            handleTestType(typeId, true);
        }
    };

    const getStatus = () => {

        // finishedAt comes from selectedPart only if Listening, else from resAttempt.attempt_types
        const finishedAt = resAttempt?.attempt_types.find((t) => t.type_id === testType?.type_id)?.finished_at ?? null;

        // Timer check
        const isTimeUp = finishedAt ? new Date(finishedAt).getTime() <= (Date.now() + serverTimeOffset) : false;
        setIsTimeUp(isTimeUp);
    };

    const csrfToken = () =>
        (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement | null)?.content ?? '';

    /** Remove per-question drafts of this attempt once it has been handed in. */
    const clearLocalDrafts = () => {
        try {
            const prefixes = [`unsaved-q-${attempt.id}-`, `unsaved-opt-${attempt.id}-`, `mynine_attempt_draft_${attempt.id}`];
            Object.keys(localStorage)
                .filter((key) => prefixes.some((prefix) => key.startsWith(prefix)))
                .forEach((key) => localStorage.removeItem(key));
        } catch {
            /* storage unavailable */
        }
    };

    const handleTestType = (test_type_id: number, autoStart: boolean = false) => {
        setIsLoading(true);
        fetch(route('practice-test-type', {
            test_type: test_type_id,
            attempt_id: attempt.id
        }))
            .then((res) => res.json())
            .then((res: any) => {
                if (res.server_time) {
                    setServerTimeOffset(new Date(res.server_time).getTime() - Date.now());
                }
                const data = res.data ?? res;
                setTestType(data);

                // If autoStart is true and there are parts, automatically load the first part
                if (autoStart && data.parts && data.parts.length > 0) {
                    handlePart(data.parts[0].id);
                } else {
                    setSelectedPart(null);
                    setIsLoading(false);
                }
            })
            .catch((err) => {
                console.error('handleTestType error:', err);
                setIsLoading(false);
            });
    };

    const handlePart = (part_id: number) => {
        setIsLoading(true);
        fetch(route('practice-part', {
            part: part_id,
            attempt_id: attempt.id
        }))
            .then((res) => res.json())
            .then((res: any) => {
                if (res.server_time) {
                    setServerTimeOffset(new Date(res.server_time).getTime() - Date.now());
                }
                setSelectedPart(res.data ?? res);
                setIsLoading(false);
            })
            .catch((err) => {
                console.error('handlePart error:', err);
                setIsLoading(false);
            });
    };

    const getQuestionStats = () => {
        let answered = 0;
        let total = 0;

        if (testType?.parts) {
            testType.parts.forEach((part) => {
                const currentPartObj = selectedPart?.id === part.id ? selectedPart : part;
                currentPartObj.sections?.forEach((section) => {
                    section.questions?.forEach((question) => {
                        const count = question.is_correct_count ? Number(question.is_correct_count) : 1;
                        total += count;
                        const isAns = question.attempt_answer && (
                            (question.attempt_answer.attempt_answer_options?.length ?? 0) > 0 ||
                            (question.attempt_answer.answer_text && question.attempt_answer.answer_text.trim() !== '')
                        );
                        if (isAns) answered += count;
                    });
                });
            });
        }

        return { answered, total };
    };

    const handleOpenFinishModal = (fullExam: boolean = false) => {
        setIsFullExamSubmit(fullExam);
        setIsFinishModalOpen(true);
    };

    const handleConfirmFinish = async () => {
        if (isFullExamSubmit) {
            setIsSubmitting(true);
            await syncQueue.flushAttempt(attempt.id);
            clearLocalDrafts();
            // Submitting is a state change, so it goes through POST (CSRF-protected); Inertia follows the redirect.
            router.post(route('practice-attempt-submit', attempt.id), {}, {
                onError: () => setIsSubmitting(false),
            });
            return;
        }

        if (!testType) return;
        setIsSubmitting(true);
        await syncQueue.flushAttempt(attempt.id);
        fetch(route('practice-test-type-submit', {
            attempt: attempt.id,
            type_id: testType.type_id
        }), {
            method: 'POST',
            headers: {
                Accept: 'application/json',
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRF-TOKEN': csrfToken()
            }
        })
            .then((res) => res.json())
            .then((res) => {
                setIsSubmitting(false);
                setIsFinishModalOpen(false);
                if (res.success) {
                    setTestType(null);
                    setSelectedPart(null);
                    // Refresh attempt data
                    fetch(route('practice-attempt', attempt.id))
                        .then((res) => res.json())
                        .then((res: any) => {
                            if (res.server_time) {
                                setServerTimeOffset(new Date(res.server_time).getTime() - Date.now());
                            }
                            setResAttempt(res.data ?? res);
                        });
                }
            })
            .catch((err) => {
                console.error('handleSubmitTestType error:', err);
                setIsSubmitting(false);
                setIsFinishModalOpen(false);
            });
    };

    useEffect(() => {
        fetch(route('practice-attempt', attempt.id))
            .then((res) => res.json())
            .then((res: any) => {
                if (res.server_time) {
                    setServerTimeOffset(new Date(res.server_time).getTime() - Date.now());
                }
                setResAttempt(res.data ?? res);
            })
            .catch((err) => console.error('fetch attempt error:', err));
        getStatus();
    }, [attempt.id, selectedPart]);

    if (!resAttempt) {
        return (
            <div className="flex flex-col justify-center items-center h-screen bg-white dark:bg-gray-950">
                <div className="w-12 h-12 border-4 border-black dark:border-white border-t-transparent rounded-full animate-spin mb-4"></div>
                <p className="text-lg font-medium animate-pulse uppercase tracking-widest">{t('loading') ?? 'Loading...'}</p>
            </div>
        );
    }

    let order = selectedPart?.order ?? 0;

    return (
        <div className="relative h-screen overflow-hidden bg-[#e5e7eb] dark:bg-gray-900 flex flex-col font-sans text-gray-900 dark:text-gray-100">

            <Head title="IELTS Practice" />

            {/* Inspera IELTS Header */}
            <InsperaHeader
                testTypeName={testType?.type?.name}
                candidateName={resAttempt.user?.name}
                finishedAt={resAttempt.attempt_types.find(
                    (t) => t.type_id === (selectedPart?.test_type?.type_id ?? testType?.type_id)
                )?.finished_at ?? null}
                serverTimeOffset={serverTimeOffset}
                audioPath={testType?.test?.audio_path}
                isTimeUp={isTimeUp}
                onExpire={() => {
                    console.log('⏰ Time is up! Returning to menu...');
                    setIsTimeUp(true);
                    setTestType(null);
                    setSelectedPart(null);
                }}
                textSize={textSize}
                setTextSize={setTextSize}
                colorScheme={colorScheme}
                setColorScheme={setColorScheme}
                onFinish={testType ? () => handleOpenFinishModal(false) : undefined}
                isFullscreen={isFullscreen}
                toggleFullscreen={toggleFullscreen}
                violationsCount={violationsCount}
            />

            {/* Main Content Area */}
            <div className="flex-1 relative overflow-hidden flex flex-col">
                {isLoading ? (
                    <div className="absolute inset-0 z-40 flex flex-col justify-center items-center bg-[#e5e7eb]/50 dark:bg-gray-900/50 backdrop-blur-sm">
                        <div className="w-10 h-10 border-4 border-black dark:border-white border-t-transparent rounded-full animate-spin mb-4"></div>
                        <p className="text-sm font-bold animate-pulse uppercase tracking-[0.2em]">{t('loading') ?? 'Loading...'}</p>
                    </div>
                ) : null}

                {!testType && (
                <div className="flex flex-col items-center justify-center h-full flex-1 w-full bg-[#e5e7eb] dark:bg-gray-900 px-4 overflow-y-auto">
                    <div className="bg-white dark:bg-gray-800 p-8 md:p-10 max-w-3xl w-full border border-gray-300 dark:border-gray-700 shadow-md text-gray-900 dark:text-gray-100">
                        <div className="border-b-2 border-gray-200 dark:border-gray-700 pb-4 mb-6">
                            <h1 className="text-3xl font-bold tracking-tight">{t('ielts_practice_test')}</h1>
                            <p className="text-gray-600 dark:text-gray-400 mt-2 text-md">{t('confirm_details')}</p>
                        </div>

                        <div className="mb-8 p-4 bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-700 rounded">
                            <div className="grid grid-cols-1 sm:grid-cols-3 gap-y-3">
                                <span className="font-semibold text-gray-600 dark:text-gray-400 col-span-1">{t('candidate_name')}</span>
                                <span className="sm:col-span-2 font-medium">{resAttempt.user?.name}</span>
                                <span className="font-semibold text-gray-600 dark:text-gray-400 col-span-1">{t('test_title')}</span>
                                <span className="sm:col-span-2 font-medium">{resAttempt.test?.name || t('academic_general')}</span>
                            </div>
                        </div>

                        <h2 className="text-xl font-bold mb-4">{t('select_test_type') ?? 'Available Modules'}</h2>
                        <div className="flex flex-col gap-3">
                            {(() => {
                                const activeTypeId = resAttempt.test?.types?.find(item => {
                                    const at = resAttempt?.attempt_types?.find(a => a.type_id === item.type_id);
                                    return at && (!at.finished_at || new Date(at.finished_at).getTime() > (Date.now() + serverTimeOffset));
                                })?.type_id;

                                return resAttempt.test?.types?.map((item) => {
                                    const at = resAttempt?.attempt_types?.find(a => a.type_id === item.type_id);
                                    const finishedAt = at?.finished_at;
                                    const isExpired = finishedAt ? new Date(finishedAt).getTime() <= (Date.now() + serverTimeOffset) : false;
                                    const isLocked = !!(activeTypeId && activeTypeId !== item.type_id && !isExpired);
                                    const isListening = item.type?.name?.toLowerCase() === 'listening';

                                    return (
                                        <button
                                            key={item.id}
                                            disabled={isExpired || isLocked}
                                            onClick={() => startTestType(item.id, isListening && !at)}
                                            className={`flex justify-between items-center w-full p-4 border transition-colors text-left group cursor-pointer ${isExpired || isLocked
                                                ? 'bg-gray-50 dark:bg-gray-900 border-gray-200 dark:border-gray-800 opacity-60 cursor-not-allowed'
                                                : 'border-gray-400 dark:border-gray-600 hover:border-black dark:hover:border-white bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700'
                                                }`}
                                        >
                                            <div className="flex flex-col">
                                                <span className="text-lg font-bold">{item.type?.name}</span>
                                                {isExpired && <span className="text-[10px] text-red-500 font-bold uppercase tracking-widest mt-0.5">{t('test_finished')}</span>}
                                                {isLocked && <span className="text-[10px] text-orange-500 font-bold uppercase tracking-widest mt-0.5">{t('locked_active_test')}</span>}
                                            </div>

                                            {!(isExpired || isLocked) && (
                                                <span className="px-6 py-2 bg-black dark:bg-gray-700 group-hover:bg-gray-800 dark:group-hover:bg-gray-600 text-white font-semibold rounded-[2px] transition-colors uppercase tracking-wide text-sm flex items-center gap-2 pointer-events-none">
                                                    {at ? (t('continue') ?? 'Davom etish') : (t('start') ?? 'Start')} <span>➔</span>
                                                </span>
                                            )}
                                        </button>
                                    );
                                });
                            })()}
                        </div>

                        {/* Complete Test Submission Button (Shown when all tests are done) */}
                        {(() => {
                            const allFinished = resAttempt.test?.types?.every(item => {
                                const at = resAttempt?.attempt_types?.find(a => a.type_id === item.type_id);
                                return at?.finished_at ? new Date(at.finished_at).getTime() <= (Date.now() + serverTimeOffset) : false;
                            });

                            if (allFinished) {
                                return (
                                    <div className="mt-8 flex justify-end border-t border-gray-200 dark:border-gray-700 pt-6">
                                        <button
                                            className="bg-black dark:bg-gray-100 hover:bg-gray-800 dark:hover:bg-white text-white dark:text-gray-900 font-bold py-3 px-8 rounded transition-colors uppercase tracking-wide text-lg flex items-center gap-2 cursor-pointer"
                                            onClick={() => handleOpenFinishModal(true)}
                                        >
                                            {t('submit_test')} <CheckIcon className="w-6 h-6 ml-2 text-green-500" />
                                        </button>
                                    </div>
                                );
                            }
                            return null;
                        })()}
                    </div>
                </div>
            )}


            {selectedPart && (() => {
                const isSplit = selectedPart.test_type.type.name === 'Reading' || selectedPart.test_type.type.name === 'Writing';
                const themeClass = colorScheme === 'yellow-black'
                    ? 'theme-yellow-black bg-black text-yellow-300'
                    : colorScheme === 'blue-white'
                        ? 'theme-blue-white bg-[#002b49] text-white'
                        : 'bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100';

                const sizeClass = textSize === 'large'
                    ? 'text-size-large'
                    : textSize === 'xlarge'
                        ? 'text-size-xlarge'
                        : 'text-size-normal';

                return (
                    <div className={`flex-1 overflow-hidden flex flex-col ${themeClass} ${sizeClass}`}>
                        <style>{`
                            .text-size-large,
                            .text-size-large p,
                            .text-size-large span,
                            .text-size-large div,
                            .text-size-large label,
                            .text-size-large input,
                            .text-size-large button:not(.header-btn) {
                                font-size: 1.15rem !important;
                                line-height: 1.6 !important;
                            }
                            .text-size-xlarge,
                            .text-size-xlarge p,
                            .text-size-xlarge span,
                            .text-size-xlarge div,
                            .text-size-xlarge label,
                            .text-size-xlarge input,
                            .text-size-xlarge button:not(.header-btn) {
                                font-size: 1.3rem !important;
                                line-height: 1.7 !important;
                            }
                            .theme-yellow-black,
                            .theme-yellow-black *:not(mark):not(button):not(input):not(select):not(textarea) {
                                background-color: #000000 !important;
                                color: #fde047 !important;
                            }
                            .theme-yellow-black mark,
                            .theme-yellow-black mark * {
                                background-color: #84cc16 !important;
                                color: #000000 !important;
                            }
                            .theme-blue-white,
                            .theme-blue-white *:not(mark):not(button):not(input):not(select):not(textarea) {
                                background-color: #002b49 !important;
                                color: #ffffff !important;
                            }
                            .theme-blue-white mark,
                            .theme-blue-white mark * {
                                background-color: #fde047 !important;
                                color: #000000 !important;
                            }
                        `}</style>

                        {/* Mobile Tab Switcher (Visible only on small screens for split tests) */}
                        {isSplit && (
                            <div className="sm:hidden flex border-b border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-xs font-bold shrink-0">
                                <button
                                    type="button"
                                    onClick={() => setMobileTab('passage')}
                                    className={`flex-1 py-2.5 text-center border-b-2 transition-colors ${
                                        mobileTab === 'passage'
                                            ? 'border-blue-600 text-blue-600 bg-blue-50/50 dark:bg-blue-950/30'
                                            : 'border-transparent text-gray-500 hover:text-gray-900'
                                    }`}
                                >
                                    📖 {t('reading_passage') || 'Matn (Passage)'}
                                </button>
                                <button
                                    type="button"
                                    onClick={() => setMobileTab('questions')}
                                    className={`flex-1 py-2.5 text-center border-b-2 transition-colors ${
                                        mobileTab === 'questions'
                                            ? 'border-blue-600 text-blue-600 bg-blue-50/50 dark:bg-blue-950/30'
                                            : 'border-transparent text-gray-500 hover:text-gray-900'
                                    }`}
                                >
                                    📝 {t('questions') || 'Savollar (Questions)'}
                                </button>
                            </div>
                        )}

                        <div
                            className={`h-full flex flex-col sm:flex-row flex-1 overflow-hidden ${selectedPart.test_type.type.name === 'Listening'
                                ? 'justify-center items-start'
                                : ''
                                }`}
                        >
                            {/* Left side scroll */}
                            {selectedPart.test_type.type.name !== 'Listening' && (
                                <div 
                                    className={`h-full overflow-y-auto p-4 sm:p-6 border-r-2 border-gray-300 dark:border-gray-700 ${
                                        isSplit 
                                            ? `${mobileTab === 'passage' ? 'block' : 'hidden sm:block'} flex-none w-full sm:w-auto` 
                                            : 'flex-1 w-full sm:w-1/2'
                                    }`}
                                    style={{ width: isSplit && typeof window !== 'undefined' && window.innerWidth >= 640 ? `${leftWidth}%` : undefined }}
                                >
                                    <PracticePart
                                        attempt={attempt}
                                        part={selectedPart}
                                    />
                                </div>
                            )}

                            {/* Resizable Divider (Desktop only) */}
                            {isSplit && (
                                <div
                                    className="hidden sm:flex w-2.5 bg-gray-300 dark:bg-gray-700 hover:bg-blue-600 dark:hover:bg-blue-500 cursor-col-resize h-full transition-colors items-center justify-center select-none z-30 relative shrink-0"
                                    onMouseDown={startResize}
                                >
                                    <div className="w-5 h-8 bg-white dark:bg-gray-800 border border-gray-400 dark:border-gray-600 rounded-[3px] shadow-sm flex items-center justify-center text-[10px] font-mono text-gray-600 dark:text-gray-300">
                                        ⟷
                                    </div>
                                </div>
                            )}

                            {/* Right side scroll */}
                            {selectedPart.test_type.type.name !== 'Writing' && (
                                <div 
                                    className={`h-full overflow-y-auto p-4 sm:p-6 bg-gray-50 dark:bg-gray-900 ${
                                        isSplit 
                                            ? `${mobileTab === 'questions' ? 'block' : 'hidden sm:block'} flex-none w-full sm:w-auto` 
                                            : 'flex-1 w-full sm:w-1/2'
                                    }`}
                                    style={{ width: isSplit && typeof window !== 'undefined' && window.innerWidth >= 640 ? `${100 - leftWidth}%` : undefined }}
                                >
                                    <div className="max-w-3xl mx-auto">
                                        {selectedPart?.sections?.reduce((acc: ReactElement[], section: Section, sectionIndex: number) => {
                                            const sectionSum = section.questions.reduce(
                                                (sum: number, q: Question) => sum + Number(q.is_correct_count ?? 1),
                                                0
                                            );

                                            const currentOrder = Number(order);

                                            acc.push(
                                                <PracticeSection
                                                    key={section.id}
                                                    order={currentOrder}
                                                    section={section}
                                                    attempt={attempt}
                                                    partIndex={sectionIndex}
                                                    sectionIndex={sectionIndex}
                                                    setSelectedPart={setSelectedPart}
                                                    flaggedIds={flaggedIds}
                                                    toggleFlag={toggleFlag}
                                                />
                                            );

                                            order = currentOrder + sectionSum;

                                            return acc;
                                        }, [])}
                                    </div>
                                </div>
                            )}

                            {selectedPart.test_type.type.name === 'Writing' && (
                                <div 
                                    className={`h-full overflow-y-auto p-4 sm:p-6 bg-gray-50 dark:bg-gray-900 ${
                                        isSplit 
                                            ? `${mobileTab === 'questions' ? 'block' : 'hidden sm:block'} flex-none w-full sm:w-auto` 
                                            : 'flex-1 w-full sm:w-1/2'
                                    }`}
                                    style={{ width: isSplit && typeof window !== 'undefined' && window.innerWidth >= 640 ? `${100 - leftWidth}%` : undefined }}
                                >
                                    <PracticeEssay
                                        order={order}
                                        part={selectedPart}
                                        attempt={attempt}
                                        setSelectedPart={setSelectedPart}
                                        isFlagged={flaggedIds.has(selectedPart.sections[0]?.questions[0]?.id)}
                                        toggleFlag={toggleFlag}
                                    />
                                </div>
                            )}

                        </div>
                    </div>
                );
            })()}


            {testType && !selectedPart && !isLoading && (
                <div className="flex flex-col items-center justify-center h-full flex-1 w-full bg-[#e5e7eb] dark:bg-gray-900 px-4 overflow-y-auto">
                    <div className="bg-white dark:bg-gray-800 p-8 md:p-10 max-w-3xl w-full border border-gray-300 dark:border-gray-700 shadow-md text-gray-900 dark:text-gray-100">
                        <div className="border-b-2 border-gray-200 dark:border-gray-700 pb-4 mb-6">
                            <h1 className="text-3xl font-bold tracking-tight">{testType.type?.name}</h1>
                            <p className="text-gray-600 dark:text-gray-400 mt-2 text-md">Please ensure your sound is working (if applicable) and select a component.</p>
                        </div>

                        <h2 className="text-xl font-bold mb-4">{t('select_part') ?? 'Select a Part'}</h2>
                        <div className="flex flex-col gap-3">
                            {testType.parts?.map((item) => (
                                <button
                                    key={item.id}
                                    onClick={() => handlePart(item.id)}
                                    className="flex justify-between items-center w-full p-4 border border-gray-400 dark:border-gray-600 hover:border-black dark:hover:border-white bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors text-left group cursor-pointer"
                                >
                                    <span className="text-lg font-bold">{item.name}</span>
                                    <span className="px-6 py-2 bg-black dark:bg-gray-700 group-hover:bg-gray-800 dark:group-hover:bg-gray-600 text-white font-semibold rounded-[2px] transition-colors uppercase tracking-wide text-sm flex items-center gap-2">
                                        {t('start')} <span>➔</span>
                                    </span>
                                </button>
                            ))}
                        </div>
                    </div>
                </div>
            )}
            </div>

            {/* Bottom Footer Bar — all parts divided equally (100% / parts.length) */}
            <div
                className="flex-none bg-white border-t border-gray-200 shrink-0 z-40 text-gray-900 select-none flex w-full"
                style={{ height: '52px' }}
            >
                <div className="flex-1 flex h-full overflow-hidden">
                    {testType?.parts && (() => {
                        const parts = testType.parts;
                        const ci = parts.findIndex(p => p.id === selectedPart?.id);
                        const equalPct = parts.length > 0 ? 100 / parts.length : 100;

                        return parts.map((p, idx) => {
                            const isActive = idx === ci;
                            let answered = 0;
                            const total = p.sections?.reduce((s, sec) => {
                                sec.questions?.forEach(q => {
                                    if (q.attempt_answer && (
                                        (q.attempt_answer.attempt_answer_options?.length ?? 0) > 0 ||
                                        (q.attempt_answer.answer_text?.trim())
                                    )) answered++;
                                });
                                return s + (sec.questions?.length || 0);
                            }, 0) || 0;

                            if (isActive) {
                                return (
                                    <div
                                        key={p.id}
                                        className="flex items-center h-full border-r border-gray-300 px-3 gap-2 overflow-x-auto hide-scrollbar shrink-0 bg-white border-t-3 border-t-blue-600 shadow-2xs"
                                        style={{ width: `${equalPct}%` }}
                                    >
                                        <span className="text-sm font-extrabold text-blue-600 shrink-0 uppercase tracking-tight">
                                            {p.name}
                                        </span>
                                        <PracticeNumberBar
                                            part={selectedPart as Part}
                                            flaggedIds={flaggedIds}
                                            activeQuestionId={activeQuestionId}
                                            setActiveQuestionId={setActiveQuestionId}
                                        />
                                    </div>
                                );
                            }

                            return (
                                <button
                                    key={p.id}
                                    onClick={() => handlePart(p.id)}
                                    className="flex items-center justify-center gap-2 h-full bg-[#f3f4f6] hover:bg-gray-200/80 transition-colors whitespace-nowrap group shrink-0 border-r border-gray-300 border-t-3 border-t-transparent cursor-pointer"
                                    style={{ width: `${equalPct}%` }}
                                >
                                    <span className="text-sm font-bold text-gray-500 group-hover:text-gray-900 transition-colors">{p.name}</span>
                                    <span className="text-xs font-semibold text-gray-400 group-hover:text-gray-600 bg-gray-200/80 px-1.5 py-0.5 rounded-[2px] transition-colors">{t('answered_of_total', { answered, total }) || `${answered} / ${total}`}</span>
                                </button>
                            );
                        });
                    })()}
                </div>

                {/* Spacing for fixed right navigation arrows */}
                <div className="w-[88px] shrink-0" />

            </div>

            {/* ◄ ► Navigation arrows — fixed at bottom-right, exactly like Inspera */}
            {selectedPart && (
                <div className="fixed bottom-0 right-0 flex items-center h-[52px] z-50">
                    <button
                        className="w-11 h-full bg-gray-600 hover:bg-gray-500 disabled:opacity-40 disabled:cursor-not-allowed text-white flex items-center justify-center font-bold text-base transition-colors border-r border-gray-700 cursor-pointer"
                        disabled={!testType || !selectedPart || (testType.parts?.findIndex(p => p.id === selectedPart.id) ?? -1) <= 0}
                        onClick={() => {
                            if (!testType || !selectedPart) return;
                            const ci = testType.parts?.findIndex(p => p.id === selectedPart.id) ?? -1;
                            if (ci > 0 && testType.parts) handlePart(testType.parts[ci - 1].id);
                        }}
                        title="Previous Part"
                    >
                        ◄
                    </button>
                    <button
                        className="w-11 h-full bg-black hover:bg-gray-800 disabled:opacity-40 disabled:cursor-not-allowed text-white flex items-center justify-center font-bold text-base transition-colors cursor-pointer"
                        disabled={!testType || !selectedPart || (testType.parts?.findIndex(p => p.id === selectedPart.id) ?? -1) >= (testType.parts?.length ?? 0) - 1}
                        onClick={() => {
                            if (!testType || !selectedPart) return;
                            const ci = testType.parts?.findIndex(p => p.id === selectedPart.id) ?? -1;
                            if (ci !== -1 && testType.parts && ci < testType.parts.length - 1) handlePart(testType.parts[ci + 1].id);
                        }}
                        title="Next Part"
                    >
                        ►
                    </button>
                </div>
            )}

            {/* Sound Check Modal for Listening with Offline Audio Preloader */}
            <SoundCheckModal
                isOpen={isSoundCheckOpen}
                audioPath={resAttempt.test?.audio_path ? `/${resAttempt.test.audio_path}` : undefined}
                onStart={() => {
                    setIsSoundCheckOpen(false);
                    if (pendingTypeId) {
                        handleTestType(pendingTypeId, true);
                        setPendingTypeId(null);
                    }
                }}
                testName={resAttempt.test?.types?.find(t => t.id === pendingTypeId)?.type?.name || 'Listening'}
            />

            {/* Anti-Cheat Integrity Warning Dialog */}
            {showWarningModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs select-none">
                    <div className="bg-white dark:bg-gray-900 rounded-2xl shadow-2xl p-6 max-w-md w-full border border-amber-300 dark:border-amber-700 text-center animate-in zoom-in-95">
                        <div className="size-14 rounded-2xl bg-amber-100 dark:bg-amber-900/50 text-amber-600 dark:text-amber-300 mx-auto flex items-center justify-center mb-3">
                            <span className="text-2xl font-bold">⚠️</span>
                        </div>
                        <h3 className="text-lg font-bold text-gray-900 dark:text-white">
                            {t('exam_integrity_warning') || 'Qoidabuzarlik Qayd Etildi!'}
                        </h3>
                        <p className="text-xs text-gray-600 dark:text-gray-300 mt-2 leading-relaxed">
                            Siz imtihon oynasidan chiqib ketdingiz yoki boshqa dasturga oʻtdingiz. Bu holat qoidabuzarlik sifatida ({violationsCount}-marta) hisobotda qayd etiladi.
                        </p>
                        <button
                            type="button"
                            onClick={closeWarningModal}
                            className="mt-5 w-full py-2.5 bg-black dark:bg-gray-100 text-white dark:text-gray-900 font-bold text-xs rounded-xl hover:bg-gray-800 transition-colors cursor-pointer"
                        >
                            {t('understand_continue') || 'Tushundim, davom etish'}
                        </button>
                    </div>
                </div>
            )}

            {/* Early Finish Confirmation Modal */}
            {(() => {
                const stats = getQuestionStats();
                return (
                    <FinishConfirmationModal
                        isOpen={isFinishModalOpen}
                        onClose={() => setIsFinishModalOpen(false)}
                        onConfirm={handleConfirmFinish}
                        testTypeName={testType?.type?.name}
                        answeredCount={stats.answered}
                        totalCount={stats.total}
                        isLoading={isSubmitting}
                        isFullExam={isFullExamSubmit}
                    />
                );
            })()}

        </div>
    );
}
