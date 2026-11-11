import { useState } from 'react';
import AppLayout from '@/layouts/app-layout';
import { Head, Link, useForm, usePage } from '@inertiajs/react';
import { type BreadcrumbItem } from '@/types';
import { useTranslation } from 'react-i18next';
import { Users, CheckCircle2, Clock, Activity, FileText, ArrowLeft, FileSpreadsheet, Eye, FileDown, Award, Trash2, Pencil, ConciergeBell, Mic, Monitor } from 'lucide-react';
import { IconAction } from '@/components/ui/icon-action';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow, TruncatedText } from '@/components/ui/table';
import { ModuleBadge } from '@/components/exam-admin/shared';
import { format } from 'date-fns';
import { toast } from 'sonner';

import MockStudentManager from '@/components/mock/mock-student-manager';
import DeleteItemModal from '@/components/delete-item-modal';
import { Button } from '@/components/ui/button';
import { exportAttemptsToExcel } from '@/lib/excel-export';
import { extractAttemptScores } from '@/lib/ielts-score-converter';

type Scores = ReturnType<typeof extractAttemptScores>;

const dash = <span className="font-mono text-muted-foreground/60">—</span>;

/** L / R / W / S / Overall cells shared by both tabs. */
function ScoreCells({ scores, finished }: { scores: Scores; finished: boolean }) {
    const { t } = useTranslation();
    const raw = (band: number | null, correct: number | null) =>
        correct !== null && band !== null ? (
            <div className="inline-flex flex-col items-center leading-tight">
                <span className="font-bold text-foreground">{band.toFixed(1)}</span>
                <span className="font-mono text-[9px] text-muted-foreground">{correct}/40</span>
            </div>
        ) : (
            dash
        );
    const band = (value: number | null) => (value !== null ? <span className="font-bold text-foreground">{value.toFixed(1)}</span> : dash);

    return (
        <>
            <TableCell label="L" className="text-center">{raw(scores.listeningBand, scores.listening)}</TableCell>
            <TableCell label="R" className="text-center">{raw(scores.readingBand, scores.reading)}</TableCell>
            <TableCell label="W" className="text-center">{band(scores.writingBand)}</TableCell>
            <TableCell label="S" className="text-center">{band(scores.speakingBand)}</TableCell>
            <TableCell label={t('mock_show.overall')} className="text-center">
                {scores.overallBand !== null ? (
                    <span className="inline-flex items-center gap-1 rounded-full border border-amber-500/25 bg-amber-500/15 px-2 py-0.5 text-xs font-black text-amber-800 dark:bg-amber-400/15 dark:text-amber-200">
                        <Award className="h-3.5 w-3.5 text-amber-500" />
                        {scores.overallBand.toFixed(1)}
                    </span>
                ) : finished ? (
                    <span className="text-[10px] font-bold text-emerald-700 dark:text-emerald-300">{t('mock_show.grading')}</span>
                ) : (
                    dash
                )}
            </TableCell>
        </>
    );
}

function ScoreHeads() {
    const { t } = useTranslation();
    return (
        <>
            <TableHead className="w-12 text-center" title="Listening">L</TableHead>
            <TableHead className="w-12 text-center" title="Reading">R</TableHead>
            <TableHead className="w-12 text-center" title="Writing">W</TableHead>
            <TableHead className="w-12 text-center" title="Speaking">S</TableHead>
            <TableHead className="w-20 text-center">{t('mock_show.overall')}</TableHead>
        </>
    );
}

function CodeChip({ code }: { code?: string | null }) {
    if (!code) return null;
    return <span className="inline-block rounded-full border border-indigo-500/25 bg-indigo-500/12 px-2 py-0.5 font-mono text-[11px] font-bold whitespace-nowrap text-brand">{code}</span>;
}

export default function MockShow() {
    const { mock, isAdmin } = usePage<{
        mock: any;
        isAdmin: boolean;
    }>().props;

    const { t } = useTranslation();
    const [activeTab, setActiveTab] = useState<'students' | 'attempts'>('students');

    const [openDeleteModal, setOpenDeleteModal] = useState(false);
    const [selectedAttemptToDelete, setSelectedAttemptToDelete] = useState<any>(null);
    const { delete: deleteAttempt } = useForm();

    const handleDeleteAttemptClick = (attemptItem: any) => {
        setSelectedAttemptToDelete(attemptItem);
        setOpenDeleteModal(true);
    };

    const handleConfirmDelete = (id: number) => {
        deleteAttempt(route('attempt.destroy', id), {
            preserveScroll: true,
            onSuccess: () => {
                setOpenDeleteModal(false);
                toast.success(t('deleted_successfully'));
            },
            onError: (err) => {
                toast.error(err?.error || t('delete_failed'));
            }
        });
    };

    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: t('mock'),
            href: route('mock.index')
        },
        {
            title: mock.name,
            href: '#'
        }
    ];

    const students = mock.students ?? [];
    const attempts = mock.attempts ?? [];
    const totalStudents = students.length;
    const attendedStudents = students.filter((s: any) => s.attended).length;
    const pendingStudents = totalStudents - attendedStudents;
    const isActive = mock.active === 1;

    const attendanceBadge = (attended: boolean) => (
        <span
            className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-bold whitespace-nowrap ${
                attended
                    ? 'bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200'
                    : 'bg-amber-500/15 text-amber-800 dark:bg-amber-400/15 dark:text-amber-200'
            }`}
        >
            {attended ? <CheckCircle2 className="h-3 w-3" /> : <Clock className="h-3 w-3" />}
            {attended ? t('mock_show.attended') : t('mock_show.waiting')}
        </span>
    );

    const resultActions = (attemptId: number) => (
        <>
            <IconAction label={t('view_result')} tone="brand" asChild>
                <Link href={route('attempt.show', attemptId)}>
                    <Eye />
                </Link>
            </IconAction>
            <IconAction label={t('download_pdf')} asChild>
                <a href={route('attempt.pdf', attemptId)} target="_blank" rel="noreferrer">
                    <FileDown />
                </a>
            </IconAction>
        </>
    );

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={mock.name} />

            <div className="mx-auto max-w-7xl space-y-6 p-4 md:p-6">
                {/* Header */}
                <div className="flex flex-col justify-between gap-4 lg:flex-row lg:items-center">
                    <div className="flex min-w-0 items-center gap-3">
                        <Link
                            href={route('mock.index')}
                            aria-label={t('mock_show.back')}
                            className="shrink-0 rounded-full border border-glass-edge bg-glass-subtle p-2 text-foreground transition-colors hover:bg-accent"
                        >
                            <ArrowLeft className="h-5 w-5" />
                        </Link>
                        <div className="min-w-0">
                            <div className="flex flex-wrap items-center gap-2">
                                <h1 className="text-2xl font-black break-words text-foreground">{mock.name}</h1>
                                <span
                                    className={`rounded-full px-2.5 py-0.5 text-xs font-bold ${
                                        isActive
                                            ? 'border border-emerald-500/25 bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200'
                                            : 'bg-muted text-muted-foreground'
                                    }`}
                                >
                                    {isActive ? `● ${t('active')}` : `○ ${t('inactive')}`}
                                </span>
                            </div>
                            {mock.modules && mock.modules.length > 0 ? (
                                <div className="mt-1 flex flex-wrap items-center gap-1">
                                    {mock.modules.map((module: any) => (
                                        <ModuleBadge key={module.id} type={module.type?.name}>
                                            {module.type?.name} · {module.test_type?.test?.name}
                                        </ModuleBadge>
                                    ))}
                                    {mock.require_desktop && (
                                        <span className="inline-flex items-center gap-1 rounded-full border border-glass-edge bg-glass-subtle px-2 py-0.5 text-[10px] font-bold text-muted-foreground">
                                            <Monitor className="h-3 w-3" /> {t('exam_admin.mock_form.require_desktop')}
                                        </span>
                                    )}
                                </div>
                            ) : (
                                <p className="mt-0.5 flex items-center gap-1.5 text-xs text-muted-foreground">
                                    <span className="font-semibold text-brand">{mock.test?.folder?.name}</span>
                                    <span>/</span>
                                    <span>{mock.test?.name}</span>
                                </p>
                            )}
                        </div>
                    </div>

                    <div className="flex flex-wrap items-center gap-2">
                        <Link href={route('mock.edit', mock.id)} className="inline-flex h-9 items-center gap-1.5 rounded-full bg-indigo-500/12 px-4 text-xs font-bold text-brand hover:bg-indigo-500/20">
                            <Pencil className="h-4 w-4" /> {t('exam_admin.common.edit')}
                        </Link>
                        <Link
                            href={route('reception.index', { mock_id: mock.id, date: (mock.started_at ?? '').slice(0, 10) || undefined })}
                            className="inline-flex h-9 items-center gap-1.5 rounded-full border border-glass-edge bg-glass-subtle px-4 text-xs font-bold text-foreground hover:bg-accent"
                        >
                            <ConciergeBell className="h-4 w-4" /> {t('exam_admin.nav.reception')}
                        </Link>
                        <Link href={route('monitor.index', { mock_id: mock.id })} className="inline-flex h-9 items-center gap-1.5 rounded-full border border-glass-edge bg-glass-subtle px-4 text-xs font-bold text-foreground hover:bg-accent">
                            <Activity className="h-4 w-4" /> {t('exam_admin.nav.monitor')}
                        </Link>
                        <Link href={route('speaking.index', { mock_id: mock.id })} className="inline-flex h-9 items-center gap-1.5 rounded-full border border-glass-edge bg-glass-subtle px-4 text-xs font-bold text-foreground hover:bg-accent">
                            <Mic className="h-4 w-4" /> {t('exam_admin.nav.speaking')}
                        </Link>
                        {attempts.length > 0 && (
                            <Button
                                onClick={() => exportAttemptsToExcel(attempts, `Mock_${mock.name}_Results`)}
                                variant="outline"
                                className="h-9 gap-2 rounded-full border-emerald-500/25 bg-emerald-500/12 px-4 text-xs font-bold text-emerald-800 shadow-xs hover:bg-emerald-500/20 dark:bg-emerald-400/15 dark:text-emerald-200"
                            >
                                <FileSpreadsheet className="h-4 w-4 text-emerald-700 dark:text-emerald-300" />
                                {t('mock_show.export_results')}
                            </Button>
                        )}
                    </div>
                </div>

                {/* Quick stats */}
                <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
                    {[
                        { icon: <Users className="h-5 w-5" />, tone: 'bg-indigo-500/12 text-brand', label: t('mock_show.stats.total'), value: totalStudents, valueClass: 'text-foreground' },
                        {
                            icon: <CheckCircle2 className="h-5 w-5" />,
                            tone: 'bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200',
                            label: t('mock_show.stats.attended'),
                            value: attendedStudents,
                            extra: `(${totalStudents > 0 ? Math.round((attendedStudents / totalStudents) * 100) : 0}%)`,
                            valueClass: 'text-emerald-700 dark:text-emerald-300',
                        },
                        {
                            icon: <Clock className="h-5 w-5" />,
                            tone: 'bg-amber-500/15 text-amber-800 dark:bg-amber-400/15 dark:text-amber-200',
                            label: t('mock_show.stats.waiting'),
                            value: pendingStudents,
                            valueClass: 'text-amber-700 dark:text-amber-300',
                        },
                        { icon: <Activity className="h-5 w-5" />, tone: 'bg-indigo-500/12 text-brand', label: t('mock_show.stats.attempts'), value: attempts.length, valueClass: 'text-foreground' },
                    ].map((stat) => (
                        <div key={stat.label} className="glass flex items-center gap-3.5 rounded-[22px] p-4">
                            <div className={`rounded-[14px] p-3 ${stat.tone}`}>{stat.icon}</div>
                            <div className="min-w-0">
                                <p className="text-xs font-bold tracking-wider text-muted-foreground uppercase">{stat.label}</p>
                                <h3 className={`mt-0.5 text-xl font-black ${stat.valueClass}`}>
                                    {stat.value} {stat.extra && <span className="text-xs font-normal text-muted-foreground">{stat.extra}</span>}
                                </h3>
                            </div>
                        </div>
                    ))}
                </div>

                {/* Tabs */}
                <div className="flex border-b border-divider" role="tablist">
                    {(
                        [
                            ['students', <Users key="i" className="h-4 w-4" />, t('mock_show.tabs.students', { count: totalStudents })],
                            ['attempts', <FileText key="i" className="h-4 w-4" />, t('mock_show.tabs.attempts', { count: attempts.length })],
                        ] as const
                    ).map(([tab, icon, label]) => (
                        <button
                            key={tab}
                            role="tab"
                            aria-selected={activeTab === tab}
                            onClick={() => setActiveTab(tab)}
                            className={`flex cursor-pointer items-center gap-2 border-b-2 px-5 py-3 text-xs font-bold transition-all ${
                                activeTab === tab ? 'border-primary text-brand' : 'border-transparent text-muted-foreground hover:text-foreground'
                            }`}
                        >
                            {icon}
                            <span>{label}</span>
                        </button>
                    ))}
                </div>

                {activeTab === 'students' && (
                    <div className="glass-strong rounded-[22px] p-3 sm:p-5">
                        <div className="mb-4 flex flex-wrap items-center justify-between gap-2">
                            <h3 className="text-sm font-bold text-foreground">{t('mock_show.students_title')}</h3>
                            <MockStudentManager mockId={mock.id} mockName={mock.name} students={students} />
                        </div>

                        {students.length === 0 ? (
                            <div className="space-y-3 rounded-[18px] border border-dashed border-glass-dash py-12 text-center text-xs text-muted-foreground">
                                <Users className="mx-auto h-8 w-8 text-muted-foreground/60" />
                                <p>{t('mock_show.students_empty')}</p>
                                <p className="text-[11px]">{t('mock_show.students_empty_hint')}</p>
                            </div>
                        ) : (
                            <div className="overflow-hidden rounded-[18px] border border-divider">
                                <Table>
                                    <TableHeader>
                                        <TableRow>
                                            <TableHead className="w-10 text-right">#</TableHead>
                                            <TableHead>{t('mock_show.candidate')}</TableHead>
                                            <TableHead className="hidden lg:table-cell">{t('mock_show.attendance')}</TableHead>
                                            <ScoreHeads />
                                            <TableHead className="w-px">
                                                <span className="sr-only">{t('attempts_table.actions')}</span>
                                            </TableHead>
                                        </TableRow>
                                    </TableHeader>
                                    <TableBody>
                                        {students.map((st: any, idx: number) => {
                                            const attempt = st.attempt;
                                            return (
                                                <TableRow key={st.id}>
                                                    <TableCell className="text-right font-mono text-muted-foreground tabular-nums max-md:hidden">{idx + 1}</TableCell>
                                                    <TableCell>
                                                        <TruncatedText className="max-w-[14rem] font-bold text-foreground">{st.name}</TruncatedText>
                                                        <div className="mt-0.5 flex flex-wrap items-center gap-1">
                                                            <CodeChip code={st.code} />
                                                            <span className="lg:hidden">{attendanceBadge(!!st.attended)}</span>
                                                        </div>
                                                    </TableCell>
                                                    <TableCell className="hidden lg:table-cell">{attendanceBadge(!!st.attended)}</TableCell>
                                                    <ScoreCells scores={extractAttemptScores(attempt)} finished={!!attempt?.finished_at} />
                                                    <TableCell className="text-right max-md:border-t max-md:border-divider max-md:pt-2">
                                                        <div className="flex items-center justify-end gap-0.5">
                                                            {attempt ? (
                                                                resultActions(attempt.id)
                                                            ) : (
                                                                <span className="text-[11px] whitespace-nowrap text-muted-foreground italic">{t('mock_show.not_started')}</span>
                                                            )}
                                                        </div>
                                                    </TableCell>
                                                </TableRow>
                                            );
                                        })}
                                    </TableBody>
                                </Table>
                            </div>
                        )}
                    </div>
                )}

                {activeTab === 'attempts' && (
                    <div className="glass-strong rounded-[22px] p-3 sm:p-5">
                        <div className="mb-4 flex flex-wrap items-center justify-between gap-2">
                            <h3 className="text-sm font-bold text-foreground">{t('mock_show.attempts_title')}</h3>
                            {attempts.length > 0 && (
                                <Button
                                    onClick={() => exportAttemptsToExcel(attempts, `Mock_${mock.name}_Attempts`)}
                                    variant="outline"
                                    className="h-8 gap-1.5 rounded-full border-emerald-500/25 bg-emerald-500/12 px-3 text-xs font-bold text-emerald-800 shadow-xs hover:bg-emerald-500/20 dark:bg-emerald-400/15 dark:text-emerald-200"
                                >
                                    <FileSpreadsheet className="h-3.5 w-3.5 text-emerald-700 dark:text-emerald-300" />
                                    {t('mock_show.export')}
                                </Button>
                            )}
                        </div>

                        {attempts.length === 0 ? (
                            <div className="space-y-3 rounded-[18px] border border-dashed border-glass-dash py-12 text-center text-xs text-muted-foreground">
                                <FileText className="mx-auto h-8 w-8 text-muted-foreground/60" />
                                <p>{t('mock_show.attempts_empty')}</p>
                                <p className="text-[11px]">{t('mock_show.attempts_empty_hint')}</p>
                            </div>
                        ) : (
                            <div className="overflow-hidden rounded-[18px] border border-divider">
                                <Table>
                                    <TableHeader>
                                        <TableRow>
                                            <TableHead className="w-10 text-right">#</TableHead>
                                            <TableHead>{t('mock_show.candidate')}</TableHead>
                                            <TableHead className="hidden lg:table-cell">{t('mock_show.status_date')}</TableHead>
                                            <ScoreHeads />
                                            <TableHead className="w-px">
                                                <span className="sr-only">{t('attempts_table.actions')}</span>
                                            </TableHead>
                                        </TableRow>
                                    </TableHeader>
                                    <TableBody>
                                        {attempts.map((item: any, idx: number) => {
                                            const isFinished = !!item.finished_at;
                                            const studentName = item.mock_student?.name || item.mockStudent?.name || item.name || item.user?.name || '—';
                                            const studentCode = item.mock_student?.code || item.mockStudent?.code;
                                            const when = item.finished_at ?? item.started_at;
                                            const status = (
                                                <div className="flex flex-col items-start gap-0.5">
                                                    <span
                                                        className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-bold whitespace-nowrap ${
                                                            isFinished
                                                                ? 'bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200'
                                                                : 'bg-indigo-500/12 text-brand'
                                                        }`}
                                                    >
                                                        {isFinished ? <CheckCircle2 className="h-3 w-3" /> : <Clock className="h-3 w-3" />}
                                                        {isFinished ? t('finished') : t('in_progress')}
                                                    </span>
                                                    {when && <span className="font-mono text-[10px] text-muted-foreground">{format(new Date(when), 'dd.MM HH:mm')}</span>}
                                                </div>
                                            );

                                            return (
                                                <TableRow key={item.id}>
                                                    <TableCell className="text-right font-mono text-muted-foreground tabular-nums max-md:hidden">{idx + 1}</TableCell>
                                                    <TableCell>
                                                        <TruncatedText className="max-w-[14rem] font-bold text-foreground">{studentName}</TruncatedText>
                                                        {item.user?.email && <TruncatedText className="max-w-[14rem] text-[10px] text-muted-foreground">{item.user.email}</TruncatedText>}
                                                        <div className="mt-0.5 flex flex-wrap items-center gap-1">
                                                            <CodeChip code={studentCode} />
                                                        </div>
                                                        <div className="mt-1 lg:hidden">{status}</div>
                                                    </TableCell>
                                                    <TableCell className="hidden lg:table-cell">{status}</TableCell>
                                                    <ScoreCells scores={extractAttemptScores(item)} finished={isFinished} />
                                                    <TableCell className="text-right max-md:border-t max-md:border-divider max-md:pt-2">
                                                        <div className="flex items-center justify-end gap-0.5">
                                                            {isFinished ? (
                                                                resultActions(item.id)
                                                            ) : (
                                                                <Link
                                                                    href={`/practice?attempt_id=${item.id}`}
                                                                    className="btn-glass-primary rounded-full px-3 py-1 text-[11px] font-bold whitespace-nowrap transition hover:brightness-110"
                                                                >
                                                                    {t('continue')}
                                                                </Link>
                                                            )}
                                                            {isAdmin && (
                                                                <IconAction label={t('delete')} tone="danger" onClick={() => handleDeleteAttemptClick(item)}>
                                                                    <Trash2 />
                                                                </IconAction>
                                                            )}
                                                        </div>
                                                    </TableCell>
                                                </TableRow>
                                            );
                                        })}
                                    </TableBody>
                                </Table>
                            </div>
                        )}
                    </div>
                )}
            </div>

            {selectedAttemptToDelete && openDeleteModal && (
                <DeleteItemModal
                    item={{
                        id: selectedAttemptToDelete.id,
                        name:
                            selectedAttemptToDelete.mock_student?.name ||
                            selectedAttemptToDelete.mockStudent?.name ||
                            selectedAttemptToDelete.name ||
                            selectedAttemptToDelete.user?.name ||
                            t('mock_show.attempt_n', { id: selectedAttemptToDelete.id }),
                    }}
                    open={openDeleteModal}
                    setOpen={setOpenDeleteModal}
                    onDelete={handleConfirmDelete}
                />
            )}
        </AppLayout>
    );
}
