import AppLayout from '@/layouts/app-layout';
import { Head, usePage } from '@inertiajs/react';
import { type BreadcrumbItem, type Attempt, type AttemptType as AttemptTypeModel, type Auth } from '@/types';
import { useTranslation } from 'react-i18next';
import AttemptTypeComponent from '@/components/attempt/attempt-type-component';
import EvaluateSpeaking from '@/components/attempt/evaluate-speaking';
import { Button } from '@/components/ui/button';
import { Clock, FileDown, ShieldAlert, ShieldCheck } from 'lucide-react';

type AttemptBands = {
    listening: number | null;
    reading: number | null;
    writing: number | null;
    speaking: number | null;
    overall: number | null;
};

export default function AttemptShow() {
    const { attempt, bands, results_visible: resultsVisible } = usePage<{
        attempt: Attempt;
        bands: AttemptBands | null;
        results_visible?: boolean;
        writing_band?: number | null;
    }>().props;
    const { t } = useTranslation();  // Using the translation hook

    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: t('attempts'),
            href: route('attempt.index')
        },
        {
            title: `#${attempt.id} - ${attempt.name || attempt.mock_student?.name || attempt.mockStudent?.name || attempt.user?.name || t('attempt')}`,
            href: route('attempt.show', attempt.id)
        }
    ];

    const { auth } = usePage().props as unknown as { auth?: Auth };

    const isAdmin = auth?.user?.roles?.some(role => role.name === 'Admin');

    // Bands are computed on the server (MockResultService::attemptBands): Reading by the test variant
    // (Academic / General Training), Writing = Admin-confirmed band or (Task 1 + 2 × Task 2) / 3.
    const moduleKey = (name?: string) => (name ?? '').toLowerCase() as keyof Omit<AttemptBands, 'overall'>;
    const calculateModuleBand = (type: AttemptTypeModel): number => {
        const value = bands?.[moduleKey(type.type?.name)];
        return typeof value === 'number' ? value : 0;
    };

    const overallBand = bands?.overall ?? 0;

    const cefr = (() => {
        if (overallBand >= 8.5) return { level: 'C2', title: t('attempt_result.cefr.c2'), color: 'bg-violet-500/12 text-violet-800 border-violet-500/25 dark:bg-violet-400/15 dark:text-violet-200 dark:border-violet-300/25' };
        if (overallBand >= 7.0) return { level: 'C1', title: t('attempt_result.cefr.c1'), color: 'bg-emerald-500/12 text-emerald-800 border-emerald-500/25 dark:bg-emerald-400/15 dark:text-emerald-200 dark:border-emerald-300/25' };
        if (overallBand >= 5.5) return { level: 'B2', title: t('attempt_result.cefr.b2'), color: 'bg-indigo-500/12 text-brand border-indigo-500/25' };
        if (overallBand >= 4.0) return { level: 'B1', title: t('attempt_result.cefr.b1'), color: 'bg-amber-500/15 text-amber-800 border-amber-500/25 dark:bg-amber-400/15 dark:text-amber-200 dark:border-amber-300/25' };
        return { level: 'A2', title: t('attempt_result.cefr.a2'), color: 'bg-muted text-foreground border-glass-edge' };
    })();

    const byModule = (name: string) => attempt.attempt_types.find((type) => type.type?.name === name);
    const listening = byModule('Listening');
    const reading = byModule('Reading');
    const writing = byModule('Writing');
    const speaking = byModule('Speaking');
    const objective = [listening, reading].filter((type): type is AttemptTypeModel => !!type);
    const written = [writing, speaking].filter((type): type is AttemptTypeModel => !!type);
    const candidateName = attempt.name || attempt.mock_student?.name || attempt.mockStudent?.name || attempt.user?.name || t('attempt');
    const subtitle = [attempt.mock?.name, attempt.test?.folder?.name, attempt.test?.name].filter(Boolean).join(' · ');

    const moduleSection = (attemptType: AttemptTypeModel) => (
        <section key={attemptType.id} className="glass-strong min-w-0 rounded-[28px] p-4 sm:p-5" aria-labelledby={`module-${attemptType.id}`}>
            <div className="mb-4 flex items-center justify-between gap-2 border-b border-divider pb-3">
                <h3 id={`module-${attemptType.id}`} className="flex items-baseline gap-2 text-lg font-bold text-foreground">
                    {attemptType.type?.name}
                    <span className="text-xs font-normal text-muted-foreground">{t('detailed_breakdown')}</span>
                </h3>
                {(attemptType.type?.name === 'Listening' || attemptType.type?.name === 'Reading') && (
                    <span className="shrink-0 rounded-full bg-indigo-500/12 px-2.5 py-0.5 font-mono text-xs font-bold text-brand">
                        {attemptType.is_correct_count ?? 0}/40 · {calculateModuleBand(attemptType).toFixed(1)}
                    </span>
                )}
            </div>
            <AttemptTypeComponent attempt_type={attemptType} />
        </section>
    );

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('attempt_result.title', { id: attempt.id })} />
            <div className="mx-auto w-full max-w-7xl p-4 md:p-6 flex h-full flex-1 flex-col gap-5">
                {/* Header + actions */}
                <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                    <div className="min-w-0">
                        <div className="mb-1 flex flex-wrap items-center gap-2">
                            <span className="text-xs font-bold tracking-wider text-muted-foreground uppercase">{t('attempt_result.kicker')}</span>
                            {attempt.tab_switch_count !== undefined && (
                                <span
                                    className={`inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[11px] font-bold ${
                                        attempt.tab_switch_count > 0
                                            ? 'border-amber-500/25 bg-amber-500/15 text-amber-800 dark:border-amber-300/25 dark:bg-amber-400/15 dark:text-amber-200'
                                            : 'border-emerald-500/25 bg-emerald-500/12 text-emerald-800 dark:border-emerald-300/25 dark:bg-emerald-400/15 dark:text-emerald-200'
                                    }`}
                                >
                                    {attempt.tab_switch_count > 0 ? <ShieldAlert className="h-3 w-3" /> : <ShieldCheck className="h-3 w-3" />}
                                    {attempt.tab_switch_count > 0 ? t('attempt_result.tab_switches', { count: attempt.tab_switch_count }) : t('attempt_result.clean')}
                                </span>
                            )}
                        </div>
                        <h1 className="text-2xl font-extrabold break-words text-foreground md:text-3xl">{candidateName}</h1>
                        {subtitle && <p className="mt-1 text-sm text-muted-foreground">{subtitle}</p>}
                    </div>
                    <div className="flex shrink-0 flex-wrap items-center gap-2">
                        {isAdmin && <EvaluateSpeaking attempt={attempt} />}
                        {attempt.finished_at && resultsVisible !== false && (
                            <Button asChild variant="outline" size="sm">
                                <a href={route('attempt.pdf', attempt.id)} target="_blank" rel="noreferrer">
                                    <FileDown className="h-4 w-4" />
                                    {t('download_pdf')}
                                </a>
                            </Button>
                        )}
                    </div>
                </div>

                {resultsVisible === false && (
                    <div className="glass-subtle flex items-center gap-3 rounded-[22px] p-4 text-sm text-muted-foreground">
                        <Clock className="h-4 w-4 shrink-0" />
                        {t('attempt_result.hidden_until_finished')}
                    </div>
                )}

                {/* Summary: overall band + four modules in one row */}
                {resultsVisible !== false && (
                <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
                    <div className="glass-strong col-span-2 flex items-center gap-4 rounded-[22px] p-4 sm:col-span-3 lg:col-span-1 lg:flex-col lg:items-start lg:gap-2">
                        <div>
                            <span className="block text-[10px] font-bold tracking-widest text-muted-foreground uppercase">{t('attempt_result.overall')}</span>
                            <span className="font-mono text-4xl font-black text-brand">{overallBand > 0 ? overallBand.toFixed(1) : '—'}</span>
                        </div>
                        {overallBand > 0 && (
                            <div className="flex flex-col items-start">
                                <span className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-sm font-extrabold ${cefr.color}`}>{cefr.level}</span>
                                <span className="mt-0.5 text-[11px] font-medium text-muted-foreground">{cefr.title}</span>
                            </div>
                        )}
                    </div>

                    {(
                        [
                            ['Listening', listening],
                            ['Reading', reading],
                            ['Writing', writing],
                            ['Speaking', speaking],
                        ] as const
                    ).map(([name, type]) => {
                        const band = type ? calculateModuleBand(type) : 0;
                        const objectiveModule = name === 'Listening' || name === 'Reading';
                        return (
                            <div key={name} className={`glass-subtle flex min-w-0 flex-col justify-between rounded-[22px] p-4 ${type ? '' : 'opacity-60'}`}>
                                <span className="text-xs font-bold text-foreground">{name}</span>
                                <span className="mt-1 font-mono text-2xl font-black text-foreground">{type && band > 0 ? band.toFixed(1) : '—'}</span>
                                <span className="text-[11px] text-muted-foreground">
                                    {!type
                                        ? t('attempt_result.not_taken')
                                        : objectiveModule
                                          ? t('attempt_result.correct_of', { count: Number(type.is_correct_count ?? 0) })
                                          : band > 0
                                            ? t('attempt_result.graded')
                                            : t('attempt_result.pending')}
                                </span>
                            </div>
                        );
                    })}
                </div>

                )}

                {/* Listening + Reading side by side, Writing / Speaking below */}
                {resultsVisible !== false && objective.length > 0 && (
                    <div className={`grid gap-5 ${objective.length > 1 ? 'lg:grid-cols-2' : ''}`}>{objective.map(moduleSection)}</div>
                )}
                {resultsVisible !== false && written.map(moduleSection)}
            </div>
        </AppLayout>
    );
}
