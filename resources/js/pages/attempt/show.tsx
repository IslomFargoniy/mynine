import AppLayout from '@/layouts/app-layout';
import { Head, usePage, useForm } from '@inertiajs/react';
import { type BreadcrumbItem, SearchData, Attempt, Auth } from '@/types';
import React, { useEffect } from 'react';
import { router } from '@inertiajs/react';
import PremiumFilters from '@/components/premium-filters';
import { useTranslation } from 'react-i18next';
import MobileSearchModal from '@/components/MobileSearchModal';
import AttemptTypeComponent from '@/components/attempt/attempt-type-component';
import EvaluateSpeaking from '@/components/attempt/evaluate-speaking';

export default function AttemptShow() {
    const { attempt } = usePage<{ attempt: Attempt }>().props;
    const { t } = useTranslation();  // Using the translation hook

    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: t('attempts') || 'Urinishlar',
            href: route('attempt.index')
        },
        {
            title: `#${attempt.id} - ${attempt.name || (attempt as any).mock_student?.name || (attempt as any).mockStudent?.name || attempt.user?.name || t('attempt')}`,
            href: route('attempt.show', attempt.id)
        }
    ];

    // Form handling for search and per_page
    const { data, setData } = useForm<SearchData>({
        search: ''
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        router.get(route('attempt.show', attempt.id), data);
    };


    useEffect(() => {
        const urlParams = new URLSearchParams(location.search);
        const searchQuery = urlParams.get('search') || ''; // Get 'search' query from the URL
        setData('search', searchQuery); // Set it to the form state
    }, [location.search]);


    const { auth } = usePage().props as unknown as { auth?: Auth };

    const isAdmin = auth?.user?.roles?.some(role => role.name === 'Admin');

    const getListeningBand = (correct: number): number => {
        if (correct >= 39) return 9.0;
        if (correct >= 37) return 8.5;
        if (correct >= 35) return 8.0;
        if (correct >= 32) return 7.5;
        if (correct >= 30) return 7.0;
        if (correct >= 26) return 6.5;
        if (correct >= 23) return 6.0;
        if (correct >= 18) return 5.5;
        if (correct >= 16) return 5.0;
        if (correct >= 13) return 4.5;
        if (correct >= 10) return 4.0;
        if (correct >= 8)  return 3.5;
        if (correct >= 6)  return 3.0;
        if (correct >= 4)  return 2.5;
        if (correct === 3) return 2.0;
        if (correct === 2) return 1.5;
        if (correct === 1) return 1.0;
        return 0.0;
    };

    const getReadingBand = (correct: number): number => {
        if (correct >= 39) return 9.0;
        if (correct >= 37) return 8.5;
        if (correct >= 35) return 8.0;
        if (correct >= 33) return 7.5;
        if (correct >= 30) return 7.0;
        if (correct >= 27) return 6.5;
        if (correct >= 23) return 6.0;
        if (correct >= 19) return 5.5;
        if (correct >= 15) return 5.0;
        if (correct >= 13) return 4.5;
        if (correct >= 10) return 4.0;
        if (correct >= 8)  return 3.5;
        if (correct >= 6)  return 3.0;
        if (correct >= 4)  return 2.5;
        if (correct === 3) return 2.0;
        if (correct === 2) return 1.5;
        if (correct === 1) return 1.0;
        return 0.0;
    };

    const calculateModuleBand = (type: any): number => {
        const name = type.type?.name;
        if (name === 'Listening') {
            return getListeningBand(Number(type.is_correct_count ?? 0));
        }
        if (name === 'Reading') {
            return getReadingBand(Number(type.is_correct_count ?? 0));
        }
        if (name === 'Writing') {
            return Number(type.is_correct_count ?? 0) > 0 ? Number(type.is_correct_count) / 2 : (Number(type.score) || 0);
        }
        if (name === 'Speaking') {
            return Number(type.score ?? 0) || Number(type.is_correct_count ?? 0) || 0;
        }
        return Number(type.score ?? 0) || 0;
    };

    // Overall Band Calculation (Official IELTS rounding rule)
    const overallBand = (() => {
        const bands = attempt.attempt_types
            .map(t => calculateModuleBand(t))
            .filter(b => b > 0);

        if (bands.length === 0) return 0.0;
        const avg = bands.reduce((acc, b) => acc + b, 0) / bands.length;
        const whole = Math.floor(avg);
        const fraction = avg - whole;

        if (fraction < 0.25) return whole;
        if (fraction < 0.75) return whole + 0.5;
        return whole + 1.0;
    })();

    const cefr = (() => {
        if (overallBand >= 8.5) return { level: 'C2', title: 'Proficient / Mastery', color: 'bg-violet-500/12 text-violet-800 border-violet-500/25 dark:bg-violet-400/15 dark:text-violet-200 dark:border-violet-300/25' };
        if (overallBand >= 7.0) return { level: 'C1', title: 'Advanced / Fluent', color: 'bg-emerald-500/12 text-emerald-800 border-emerald-500/25 dark:bg-emerald-400/15 dark:text-emerald-200 dark:border-emerald-300/25' };
        if (overallBand >= 5.5) return { level: 'B2', title: 'Upper-Intermediate', color: 'bg-indigo-500/12 text-brand border-indigo-500/25' };
        if (overallBand >= 4.0) return { level: 'B1', title: 'Intermediate', color: 'bg-amber-500/15 text-amber-800 border-amber-500/25 dark:bg-amber-400/15 dark:text-amber-200 dark:border-amber-300/25' };
        return { level: 'A2 / B0', title: 'Basic User', color: 'bg-muted text-foreground border-glass-edge' };
    })();

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={`Attempt #${attempt.id} Results`} />
            <div className="flex h-full flex-1 flex-col gap-6 rounded-xl p-4 md:p-6 max-w-7xl mx-auto w-full">
                {/* Search and Per-Page Selection */}
                <div className="flex justify-end items-center">
                    <MobileSearchModal
                        data={data}
                        setData={setData}
                        handleSubmit={handleSubmit}
                    />
                    <div className="hidden lg:block w-full">
                        <PremiumFilters handleSubmit={handleSubmit} setData={setData} data={data} />
                    </div>
                </div>

                {/* Executive Result Hero Card */}
                <div className="glass-strong rounded-[28px] p-6 space-y-6">
                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-6 pb-6 border-b border-divider">
                        <div>
                            <div className="flex items-center gap-2 mb-1">
                                <span className="text-xs font-bold uppercase tracking-wider text-muted-foreground">
                                    IELTS Practice Test Result
                                </span>
                                {attempt.tab_switch_count !== undefined && (
                                    <span className={`inline-flex items-center gap-1 text-[11px] font-bold px-2 py-0.5 rounded-full border ${
                                        attempt.tab_switch_count > 0
                                            ? 'bg-amber-500/15 text-amber-800 border-amber-500/25 dark:bg-amber-400/15 dark:text-amber-200 dark:border-amber-300/25'
                                            : 'bg-emerald-500/12 text-emerald-800 border-emerald-500/25 dark:bg-emerald-400/15 dark:text-emerald-200 dark:border-emerald-300/25'
                                    }`}>
                                        {attempt.tab_switch_count > 0
                                            ? `⚠️ ${attempt.tab_switch_count} ta tab almashtirish`
                                            : '🛡️ Qoidabuzarliksiz (Clean)'}
                                    </span>
                                )}
                            </div>
                            <h1 className="text-2xl md:text-3xl font-extrabold text-foreground">
                                {attempt.user?.name}
                            </h1>
                            <p className="text-sm text-muted-foreground mt-1">
                                {attempt?.mock?.name} • {attempt?.test?.folder?.name} {attempt?.test?.name}
                            </p>
                        </div>

                        {/* Overall Band & CEFR Badge */}
                        <div className="flex items-center gap-4 glass-subtle p-4 rounded-[18px] shrink-0">
                            <div className="text-center pr-4 border-r border-divider">
                                <span className="text-xs font-bold text-muted-foreground uppercase tracking-widest block">
                                    Overall Band
                                </span>
                                <span className="text-4xl font-black text-brand font-mono">
                                    {overallBand > 0 ? overallBand.toFixed(1) : '—'}
                                </span>
                            </div>
                            <div className="flex flex-col items-start">
                                <span className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
                                    CEFR Level
                                </span>
                                <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-sm font-extrabold border mt-0.5 ${cefr.color}`}>
                                    {cefr.level}
                                </span>
                                <span className="text-[11px] text-muted-foreground font-medium mt-0.5">
                                    {cefr.title}
                                </span>
                            </div>
                        </div>
                    </div>

                    {/* Module Score Cards */}
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                        {attempt.attempt_types.map((type) => {
                            const band = calculateModuleBand(type);
                            const isListening = type.type?.name === 'Listening';
                            const isReading = type.type?.name === 'Reading';
                            const isWriting = type.type?.name === 'Writing';
                            const isSpeaking = type.type?.name === 'Speaking';

                            return (
                                <div
                                    key={type.id}
                                    className="glass-subtle p-5 rounded-[18px] hover:bg-accent transition-all flex flex-col justify-between"
                                >
                                    <div>
                                        <div className="flex items-center justify-between">
                                            <span className="font-bold text-foreground text-base">
                                                {type.type?.name}
                                            </span>
                                            <span className="text-xs font-mono font-bold px-2 py-0.5 bg-indigo-500/12 text-brand rounded-full">
                                                Band {band > 0 ? band.toFixed(1) : '—'}
                                            </span>
                                        </div>

                                        <div className="mt-3 text-sm text-foreground/80">
                                            {isListening || isReading ? (
                                                <div className="flex items-center justify-between text-xs">
                                                    <span>{t('correct_answers') || 'Toʻgʻri javoblar'}:</span>
                                                    <strong className="font-mono text-sm text-foreground">
                                                        {type.is_correct_count ?? 0} / 40
                                                    </strong>
                                                </div>
                                            ) : isWriting ? (
                                                <div className="text-xs text-muted-foreground">
                                                    AI & Examiner Evaluation
                                                </div>
                                            ) : isSpeaking ? (
                                                <div className="text-xs text-muted-foreground">
                                                    Examiner / AI Assessment
                                                </div>
                                            ) : null}
                                        </div>
                                    </div>

                                    {type.comment && (
                                        <p className="text-xs text-muted-foreground italic mt-3 pt-3 border-t border-divider line-clamp-2">
                                            "{type.comment}"
                                        </p>
                                    )}
                                </div>
                            );
                        })}
                    </div>

                    {isAdmin && (
                        <div className="pt-2 flex justify-end">
                            <EvaluateSpeaking attempt={attempt} />
                        </div>
                    )}
                </div>

                {/* Detailed Module Breakdown */}
                <div className="space-y-6">
                    {attempt.attempt_types.map((attemptType) => (
                        <div
                            key={attemptType.id}
                            className="glass-strong rounded-[28px] p-6"
                        >
                            <div className="flex items-center justify-between mb-4 pb-3 border-b border-divider">
                                <h3 className="text-lg font-bold text-foreground flex items-center gap-2">
                                    <span>{attemptType.type?.name}</span>
                                    <span className="text-xs font-normal text-muted-foreground">
                                        ({t('detailed_breakdown') || 'Batafsil tahlil'})
                                    </span>
                                </h3>
                            </div>
                            <AttemptTypeComponent
                                attempt_type={attemptType}
                            />
                        </div>
                    ))}
                </div>
            </div>
        </AppLayout>
    );
}
