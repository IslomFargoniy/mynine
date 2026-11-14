import CreateAttemptModal from '@/components/attempt/create-attempt-modal';
import AppLayout from '@/layouts/app-layout';
import { type BreadcrumbItem, type PracticeModule, type Test } from '@/types';
import { Head, Link, router, usePage } from '@inertiajs/react';
import { BookOpen, Headphones, PenLine, Search, Timer, Trophy } from 'lucide-react';
import { type FormEvent, useState } from 'react';
import { useTranslation } from 'react-i18next';

type ModuleTest = Test & { types: { id: number; type?: { name: string; minute?: number | null } }[] };

interface PageProps {
    [key: string]: unknown;
    module: PracticeModule;
    moduleName: string;
    folders: { id: number; name: string; comment?: string | null; tests: ModuleTest[] }[];
    byTest: Record<string, { count: number; best: number | null }>;
    stats: { count: number; best: number | null; average: number | null };
    recent: { id: number; test: string | null; finished_at: string; band: number | null }[];
    filters: { search?: string; folder_id?: string };
}

const ICONS = { listening: Headphones, reading: BookOpen, writing: PenLine } as const;
const DEFAULT_MINUTES = { listening: 30, reading: 60, writing: 60 } as const;

const band = (value: number | null | undefined) => (value === null || value === undefined ? '—' : Number(value).toFixed(1));

/**
 * Listening, Reading or Writing on its own: tests that have the module, each started for that module only,
 * with the student's bands in it.
 */
export default function PracticeModulePage() {
    const { t } = useTranslation();
    const { module, folders, byTest, stats, recent, filters } = usePage<PageProps>().props;
    const [search, setSearch] = useState(filters.search ?? '');
    const ModuleIcon = ICONS[module];
    const title = t(`practice_module.${module}`);

    const breadcrumbs: BreadcrumbItem[] = [{ title, href: route('practice-module.index', module) }];

    const submit = (e: FormEvent) => {
        e.preventDefault();
        router.get(route('practice-module.index', module), search ? { search } : {}, { preserveState: true, preserveScroll: true });
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={title} />
            <div className="mx-auto flex w-full max-w-7xl flex-col gap-6 p-4 md:p-6">
                {/* Header + the student's own numbers in this module */}
                <div className="glass grid gap-4 rounded-[28px] p-6 md:grid-cols-[1fr_auto] md:items-center">
                    <div className="flex items-center gap-4">
                        <span className="flex size-12 shrink-0 items-center justify-center rounded-2xl bg-indigo-500/12 text-brand">
                            <ModuleIcon className="size-6" />
                        </span>
                        <div className="min-w-0">
                            <h1 className="text-2xl font-black tracking-tight text-foreground">{title}</h1>
                            <p className="text-sm text-muted-foreground">{t('practice_module.subtitle', { module: title })}</p>
                        </div>
                    </div>
                    <dl className="grid grid-cols-3 gap-3 text-center">
                        {(
                            [
                                ['practice_module.attempts', String(stats.count)],
                                ['practice_module.best', band(stats.best)],
                                ['practice_module.average', band(stats.average)],
                            ] as const
                        ).map(([label, value]) => (
                            <div key={label} className="glass-subtle min-w-20 rounded-2xl px-3 py-2">
                                <dt className="text-[10px] font-bold tracking-widest text-muted-foreground uppercase">{t(label)}</dt>
                                <dd className="font-mono text-xl font-black text-foreground">{value}</dd>
                            </div>
                        ))}
                    </dl>
                </div>

                {recent.length > 0 && (
                    <div className="glass-subtle rounded-[22px] p-4">
                        <h2 className="mb-2 flex items-center gap-2 text-sm font-bold text-foreground">
                            <Trophy className="size-4 text-brand" /> {t('practice_module.recent')}
                        </h2>
                        <ul className="flex flex-wrap gap-2">
                            {recent.map((r) => (
                                <li key={r.id}>
                                    <Link
                                        href={route('attempt.show', r.id)}
                                        className="inline-flex items-center gap-2 rounded-full border border-glass-edge bg-card px-3 py-1 text-xs font-medium text-foreground hover:border-ring hover:text-brand"
                                    >
                                        <span className="truncate">{r.test}</span>
                                        <span className="font-mono font-black">{band(r.band)}</span>
                                    </Link>
                                </li>
                            ))}
                        </ul>
                    </div>
                )}

                <form onSubmit={submit} className="glass-subtle flex items-center gap-2 rounded-full px-4 py-2" role="search">
                    <Search className="size-4 shrink-0 text-muted-foreground" />
                    <input
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        placeholder={t('search')}
                        aria-label={t('search')}
                        className="min-w-0 flex-1 bg-transparent text-sm outline-none"
                    />
                </form>

                {folders.length === 0 && (
                    <p className="glass-subtle rounded-[22px] p-8 text-center text-sm text-muted-foreground">{t('practice_module.empty')}</p>
                )}

                {folders.map((folder) => (
                    <section key={folder.id} aria-labelledby={`pm-folder-${folder.id}`}>
                        <div className="mb-4 border-l-4 border-primary pl-4">
                            <h2 id={`pm-folder-${folder.id}`} className="text-2xl font-black tracking-tight break-words text-foreground uppercase">
                                {folder.name}
                            </h2>
                            {folder.comment && <p className="text-sm text-muted-foreground italic">{folder.comment}</p>}
                        </div>
                        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                            {folder.tests.map((test) => {
                                const mine = byTest[String(test.id)];
                                const minutes = test.types[0]?.type?.minute || DEFAULT_MINUTES[module];
                                return (
                                    <div
                                        key={test.id}
                                        className="flex min-w-0 flex-col justify-between gap-4 rounded-[22px] border border-glass-edge bg-card p-5 shadow-glass-pill transition-all duration-300 hover:-translate-y-1 hover:bg-accent"
                                    >
                                        <div className="flex items-start justify-between gap-2">
                                            <h3 className="line-clamp-2 min-w-0 text-lg font-bold break-words text-foreground">{test.name}</h3>
                                            <CreateAttemptModal test={test} module={module} />
                                        </div>
                                        <div className="flex items-center justify-between gap-2 border-t border-divider pt-3 text-xs font-bold text-muted-foreground">
                                            <span className="inline-flex items-center gap-1">
                                                <Timer className="size-3.5" /> {t('practice_module.minutes', { count: minutes })}
                                            </span>
                                            <span title={t('practice_module.best')}>
                                                {mine ? `${t('practice_module.best')}: ${band(mine.best)} · ${mine.count}×` : t('practice_module.not_tried')}
                                            </span>
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    </section>
                ))}
            </div>
        </AppLayout>
    );
}
