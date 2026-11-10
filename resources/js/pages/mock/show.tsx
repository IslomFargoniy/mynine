import React, { useState } from 'react';
import AppLayout from '@/layouts/app-layout';
import { Head, Link, useForm, usePage } from '@inertiajs/react';
import { type BreadcrumbItem } from '@/types';
import { useTranslation } from 'react-i18next';
import { Users, CheckCircle2, Clock, Activity, FileText, ArrowLeft, FileSpreadsheet, Eye, FileDown, Award, Trash2, Pencil, ConciergeBell, Mic, Monitor } from 'lucide-react';
import { ModuleBadge } from '@/components/exam-admin/shared';
import { format } from 'date-fns';
import { toast } from 'sonner';

import MockStudentManager from '@/components/mock/mock-student-manager';
import DeleteItemModal from '@/components/delete-item-modal';
import { Button } from '@/components/ui/button';
import { exportAttemptsToExcel } from '@/lib/excel-export';
import { extractAttemptScores } from '@/lib/ielts-score-converter';

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
                toast.success(t('deleted_successfully') || "Urinish o'chirildi");
            },
            onError: (err) => {
                toast.error(err?.error || t('delete_failed') || "O'chirishda xatolik yuz berdi");
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

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={mock.name} />

            <div className="space-y-6 p-4 md:p-6 max-w-7xl mx-auto">
                {/* Top Navigation & Header */}
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div className="flex items-center gap-3">
                        <Link
                            href={route('mock.index')}
                            className="p-2 rounded-full border border-glass-edge bg-glass-subtle text-foreground hover:bg-accent transition-colors"
                        >
                            <ArrowLeft className="w-5 h-5" />
                        </Link>
                        <div>
                            <div className="flex items-center gap-2">
                                <h1 className="text-2xl font-black text-foreground">
                                    {mock.name}
                                </h1>
                                <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold ${
                                    isActive
                                        ? 'bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200 border border-emerald-500/25'
                                        : 'bg-muted text-muted-foreground'
                                }`}>
                                    {isActive ? '● Faol' : '○ Nofaol'}
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
                                <p className="text-xs text-muted-foreground mt-0.5 flex items-center gap-1.5">
                                    <span className="font-semibold text-brand">{mock.test?.folder?.name}</span>
                                    <span>/</span>
                                    <span>{mock.test?.name}</span>
                                </p>
                            )}
                        </div>
                    </div>

                    <div className="flex flex-wrap items-center gap-2">
                        <Link href={route('mock.edit', mock.id)} className="inline-flex h-10 items-center gap-1.5 rounded-full bg-indigo-500/12 px-4 text-xs font-bold text-brand hover:bg-indigo-500/20">
                            <Pencil className="h-4 w-4" /> {t('exam_admin.common.edit')}
                        </Link>
                        <Link href={route('reception.index', { mock_id: mock.id, date: (mock.started_at ?? '').slice(0, 10) || undefined })} className="inline-flex h-10 items-center gap-1.5 rounded-full border border-glass-edge bg-glass-subtle px-4 text-xs font-bold text-foreground hover:bg-accent">
                            <ConciergeBell className="h-4 w-4" /> {t('exam_admin.nav.reception')}
                        </Link>
                        <Link href={route('monitor.index', { mock_id: mock.id })} className="inline-flex h-10 items-center gap-1.5 rounded-full border border-glass-edge bg-glass-subtle px-4 text-xs font-bold text-foreground hover:bg-accent">
                            <Activity className="h-4 w-4" /> {t('exam_admin.nav.monitor')}
                        </Link>
                        <Link href={route('speaking.index', { mock_id: mock.id })} className="inline-flex h-10 items-center gap-1.5 rounded-full border border-glass-edge bg-glass-subtle px-4 text-xs font-bold text-foreground hover:bg-accent">
                            <Mic className="h-4 w-4" /> {t('exam_admin.nav.speaking')}
                        </Link>
                    </div>

                    {attempts.length > 0 && (
                        <div className="flex items-center gap-2">
                            <Button
                                onClick={() => exportAttemptsToExcel(attempts, `Mock_${mock.name}_Results`)}
                                variant="outline"
                                className="h-10 px-4 rounded-full border-emerald-500/25 bg-emerald-500/12 text-emerald-800 hover:bg-emerald-500/20 dark:bg-emerald-400/15 dark:text-emerald-200 gap-2 font-bold text-xs shadow-xs"
                            >
                                <FileSpreadsheet className="w-4 h-4 text-emerald-700 dark:text-emerald-300" />
                                Natijalarni Excelga Yuklash
                            </Button>
                        </div>
                    )}
                </div>

                {/* Quick Stats Grid */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                    <div className="glass rounded-[22px] p-4 flex items-center gap-3.5">
                        <div className="p-3 rounded-[14px] bg-indigo-500/12 text-brand">
                            <Users className="w-5 h-5" />
                        </div>
                        <div>
                            <p className="text-xs font-bold text-muted-foreground uppercase tracking-wider">Jami O'quvchilar</p>
                            <h3 className="text-xl font-black text-foreground mt-0.5">{totalStudents} ta</h3>
                        </div>
                    </div>

                    <div className="glass rounded-[22px] p-4 flex items-center gap-3.5">
                        <div className="p-3 rounded-[14px] bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200">
                            <CheckCircle2 className="w-5 h-5" />
                        </div>
                        <div>
                            <p className="text-xs font-bold text-muted-foreground uppercase tracking-wider">Qatnashganlar</p>
                            <h3 className="text-xl font-black text-emerald-700 dark:text-emerald-300 mt-0.5">
                                {attendedStudents} ta <span className="text-xs text-muted-foreground font-normal">({totalStudents > 0 ? Math.round((attendedStudents/totalStudents)*100) : 0}%)</span>
                            </h3>
                        </div>
                    </div>

                    <div className="glass rounded-[22px] p-4 flex items-center gap-3.5">
                        <div className="p-3 rounded-[14px] bg-amber-500/15 text-amber-800 dark:bg-amber-400/15 dark:text-amber-200">
                            <Clock className="w-5 h-5" />
                        </div>
                        <div>
                            <p className="text-xs font-bold text-muted-foreground uppercase tracking-wider">Kutilayotganlar</p>
                            <h3 className="text-xl font-black text-amber-700 dark:text-amber-300 mt-0.5">{pendingStudents} ta</h3>
                        </div>
                    </div>

                    <div className="glass rounded-[22px] p-4 flex items-center gap-3.5">
                        <div className="p-3 rounded-[14px] bg-indigo-500/12 text-brand">
                            <Activity className="w-5 h-5" />
                        </div>
                        <div>
                            <p className="text-xs font-bold text-muted-foreground uppercase tracking-wider">Topshirilgan Urinishlar</p>
                            <h3 className="text-xl font-black text-foreground mt-0.5">{attempts.length} ta</h3>
                        </div>
                    </div>
                </div>

                {/* Tabs Navigation */}
                <div className="flex border-b border-divider">
                    <button
                        onClick={() => setActiveTab('students')}
                        className={`px-5 py-3 font-bold text-xs flex items-center gap-2 border-b-2 transition-all cursor-pointer ${
                            activeTab === 'students'
                                ? 'border-primary text-brand'
                                : 'border-transparent text-muted-foreground hover:text-foreground'
                        }`}
                    >
                        <Users className="w-4 h-4" />
                        <span>Mock O'quvchilari va Natijalar ({totalStudents})</span>
                    </button>

                    <button
                        onClick={() => setActiveTab('attempts')}
                        className={`px-5 py-3 font-bold text-xs flex items-center gap-2 border-b-2 transition-all cursor-pointer ${
                            activeTab === 'attempts'
                                ? 'border-primary text-brand'
                                : 'border-transparent text-muted-foreground hover:text-foreground'
                        }`}
                    >
                        <FileText className="w-4 h-4" />
                        <span>Imtihon Urinishlari Batafsil ({attempts.length})</span>
                    </button>
                </div>

                {/* Tab Content */}
                {activeTab === 'students' && (
                    <div className="glass-strong rounded-[22px] p-5">
                        <div className="flex items-center justify-between mb-4">
                            <h3 className="text-sm font-bold text-foreground">
                                O'quvchilar Ro'yxati va Imtihon Kodlari
                            </h3>
                            <MockStudentManager
                                mockId={mock.id}
                                mockName={mock.name}
                                students={students}
                            />
                        </div>

                        {students.length === 0 ? (
                            <div className="text-center py-12 border border-dashed border-glass-dash rounded-[18px] text-xs text-muted-foreground space-y-3">
                                <Users className="w-8 h-8 mx-auto text-muted-foreground/60" />
                                <p>Hali o'quvchilar biriktirilmagan.</p>
                                <p className="text-[11px]">"O'quvchilar" tugmasini bosib, yangi nomzodlarni qo'shing.</p>
                            </div>
                        ) : (
                            <div className="overflow-x-auto rounded-[18px] border border-divider">
                                <table className="w-full text-xs text-left">
                                    <thead className="bg-muted text-muted-foreground font-bold uppercase text-[10px] tracking-wide">
                                        <tr>
                                            <th className="px-4 py-3">#</th>
                                            <th className="px-4 py-3">O'quvchi Ismi</th>
                                            <th className="px-4 py-3">Nomzod Kodi</th>
                                            <th className="px-4 py-3 text-center">Davomat</th>
                                            <th className="px-4 py-3 text-center">Listening</th>
                                            <th className="px-4 py-3 text-center">Reading</th>
                                            <th className="px-4 py-3 text-center">Writing</th>
                                            <th className="px-4 py-3 text-center">Speaking</th>
                                            <th className="px-4 py-3 text-center">Overall Band</th>
                                            <th className="px-4 py-3 text-right">Amallar</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-divider">
                                        {students.map((st: any, idx: number) => {
                                            const attempt = st.attempt;
                                            const scores = extractAttemptScores(attempt);
                                            const isFinished = !!attempt?.finished_at;

                                            return (
                                                <tr key={st.id} className="hover:bg-accent/60">
                                                    <td className="px-4 py-3 font-mono text-muted-foreground">{idx + 1}</td>
                                                    <td className="px-4 py-3 font-bold text-foreground">{st.name}</td>
                                                    <td className="px-4 py-3 font-mono font-bold text-brand">
                                                        <span className="px-2 py-0.5 rounded-full bg-indigo-500/12 border border-indigo-500/25 text-[11px]">
                                                            {st.code}
                                                        </span>
                                                    </td>
                                                    <td className="px-4 py-3 text-center">
                                                        <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                                                            st.attended
                                                                ? 'bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200'
                                                                : 'bg-amber-500/15 text-amber-800 dark:bg-amber-400/15 dark:text-amber-200'
                                                        }`}>
                                                            {st.attended ? <CheckCircle2 className="w-3 h-3" /> : <Clock className="w-3 h-3" />}
                                                            {st.attended ? 'Qatnashdi' : 'Kutilmoqda'}
                                                        </span>
                                                    </td>

                                                    {/* Listening Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.listening !== null ? (
                                                            <div className="inline-flex flex-col items-center">
                                                                <span className="font-bold text-foreground">{scores.listeningBand?.toFixed(1)}</span>
                                                                <span className="text-[9px] text-muted-foreground font-mono">({scores.listening}/40)</span>
                                                            </div>
                                                        ) : (
                                                            <span className="text-muted-foreground/60 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Reading Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.reading !== null ? (
                                                            <div className="inline-flex flex-col items-center">
                                                                <span className="font-bold text-foreground">{scores.readingBand?.toFixed(1)}</span>
                                                                <span className="text-[9px] text-muted-foreground font-mono">({scores.reading}/40)</span>
                                                            </div>
                                                        ) : (
                                                            <span className="text-muted-foreground/60 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Writing Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.writingBand !== null ? (
                                                            <span className="font-bold text-foreground">{scores.writingBand.toFixed(1)}</span>
                                                        ) : (
                                                            <span className="text-muted-foreground/60 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Speaking Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.speakingBand !== null ? (
                                                            <span className="font-bold text-foreground">{scores.speakingBand.toFixed(1)}</span>
                                                        ) : (
                                                            <span className="text-muted-foreground/60 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Overall Band Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.overallBand !== null ? (
                                                            <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-black bg-amber-500/15 text-amber-800 dark:bg-amber-400/15 dark:text-amber-200 border border-amber-500/25">
                                                                <Award className="w-3.5 h-3.5 text-amber-500" />
                                                                {scores.overallBand.toFixed(1)}
                                                            </span>
                                                        ) : isFinished ? (
                                                            <span className="text-emerald-700 font-bold text-[10px] dark:text-emerald-300">Baholanmoqda</span>
                                                        ) : (
                                                            <span className="text-muted-foreground/60 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Actions */}
                                                    <td className="px-4 py-3 text-right">
                                                        {attempt ? (
                                                            <div className="inline-flex items-center gap-1.5">
                                                                <Link
                                                                    href={route('attempt.show', attempt.id)}
                                                                    className="p-1.5 rounded-full bg-indigo-500/12 text-brand hover:bg-indigo-500/20 transition-colors"
                                                                    title="Natijani Ko'rish (View Result)"
                                                                >
                                                                    <Eye className="w-4 h-4" />
                                                                </Link>
                                                                <button
                                                                    onClick={() => window.open(route('attempt.pdf', attempt.id), '_blank')}
                                                                    className="p-1.5 rounded-full bg-rose-500/12 text-rose-800 dark:bg-rose-400/15 dark:text-rose-200 hover:bg-rose-500/20 transition-colors"
                                                                    title="PDF Yuklab Olish (Download PDF)"
                                                                >
                                                                    <FileDown className="w-4 h-4" />
                                                                </button>
                                                            </div>
                                                        ) : (
                                                            <span className="text-muted-foreground italic text-[11px]">Boshlanmagan</span>
                                                        )}
                                                    </td>
                                                </tr>
                                            );
                                        })}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </div>
                )}

                {activeTab === 'attempts' && (
                    <div className="glass-strong rounded-[22px] p-5">
                        <div className="flex items-center justify-between mb-4">
                            <h3 className="text-sm font-bold text-foreground">
                                Imtihon Urinishlari Ro'yxati
                            </h3>
                            {attempts.length > 0 && (
                                <Button
                                    onClick={() => exportAttemptsToExcel(attempts, `Mock_${mock.name}_Attempts`)}
                                    variant="outline"
                                    className="h-8 px-3 rounded-full border-emerald-500/25 bg-emerald-500/12 text-emerald-800 hover:bg-emerald-500/20 dark:bg-emerald-400/15 dark:text-emerald-200 gap-1.5 font-bold text-xs shadow-xs"
                                >
                                    <FileSpreadsheet className="w-3.5 h-3.5 text-emerald-700 dark:text-emerald-300" />
                                    Excelga Yuklash
                                </Button>
                            )}
                        </div>

                        {attempts.length === 0 ? (
                            <div className="text-center py-12 border border-dashed border-glass-dash rounded-[18px] text-xs text-muted-foreground space-y-3">
                                <FileText className="w-8 h-8 mx-auto text-muted-foreground/60" />
                                <p>Hali imtihon topshirganlar yo'q.</p>
                                <p className="text-[11px]">O'quvchilar imtihonni topshirgandan so'ng natijalar bu yerda ko'rinadi.</p>
                            </div>
                        ) : (
                            <div className="overflow-x-auto rounded-[18px] border border-divider">
                                <table className="w-full text-xs text-left">
                                    <thead className="bg-muted text-muted-foreground font-bold uppercase text-[10px] tracking-wide">
                                        <tr>
                                            <th className="px-4 py-3">#</th>
                                            <th className="px-4 py-3">O'quvchi Ismi</th>
                                            <th className="px-4 py-3">Nomzod Kodi</th>
                                            <th className="px-4 py-3 text-center">Holat / Sana</th>
                                            <th className="px-4 py-3 text-center">Listening</th>
                                            <th className="px-4 py-3 text-center">Reading</th>
                                            <th className="px-4 py-3 text-center">Writing</th>
                                            <th className="px-4 py-3 text-center">Speaking</th>
                                            <th className="px-4 py-3 text-center">Overall Band</th>
                                            <th className="px-4 py-3 text-right">Amallar</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-divider">
                                        {attempts.map((item: any, idx: number) => {
                                            const scores = extractAttemptScores(item);
                                            const isFinished = !!item.finished_at;
                                            const studentName = item.mock_student?.name || item.mockStudent?.name || item.name || item.user?.name || "---";
                                            const studentCode = item.mock_student?.code || item.mockStudent?.code;

                                            return (
                                                <tr key={item.id} className="hover:bg-accent/60">
                                                    <td className="px-4 py-3 font-mono text-muted-foreground">{idx + 1}</td>
                                                    <td className="px-4 py-3 font-bold text-foreground">
                                                        <div>{studentName}</div>
                                                        {item.user?.email && (
                                                            <span className="text-[10px] text-muted-foreground font-normal">{item.user.email}</span>
                                                        )}
                                                    </td>
                                                    <td className="px-4 py-3 font-mono font-bold text-brand">
                                                        {studentCode ? (
                                                            <span className="px-2 py-0.5 rounded-full bg-indigo-500/12 border border-indigo-500/25 text-[11px]">
                                                                {studentCode}
                                                            </span>
                                                        ) : (
                                                            <span className="text-muted-foreground/60 font-mono text-[11px]">-</span>
                                                        )}
                                                    </td>
                                                    <td className="px-4 py-3 text-center">
                                                        <div className="inline-flex flex-col items-center gap-0.5">
                                                            <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                                                                isFinished
                                                                    ? 'bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200'
                                                                    : 'bg-indigo-500/12 text-brand'
                                                            }`}>
                                                                {isFinished ? <CheckCircle2 className="w-3 h-3" /> : <Clock className="w-3 h-3" />}
                                                                {isFinished ? 'Tugatildi' : 'Jarayonda'}
                                                            </span>
                                                            {item.finished_at ? (
                                                                <span className="text-[9px] text-muted-foreground font-mono">
                                                                    {format(new Date(item.finished_at), 'dd.MM.yyyy HH:mm')}
                                                                </span>
                                                            ) : item.started_at ? (
                                                                <span className="text-[9px] text-muted-foreground font-mono">
                                                                    {format(new Date(item.started_at), 'dd.MM.yyyy HH:mm')}
                                                                </span>
                                                            ) : null}
                                                        </div>
                                                    </td>

                                                    {/* Listening Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.listening !== null ? (
                                                            <div className="inline-flex flex-col items-center">
                                                                <span className="font-bold text-foreground">{scores.listeningBand?.toFixed(1)}</span>
                                                                <span className="text-[9px] text-muted-foreground font-mono">({scores.listening}/40)</span>
                                                            </div>
                                                        ) : (
                                                            <span className="text-muted-foreground/60 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Reading Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.reading !== null ? (
                                                            <div className="inline-flex flex-col items-center">
                                                                <span className="font-bold text-foreground">{scores.readingBand?.toFixed(1)}</span>
                                                                <span className="text-[9px] text-muted-foreground font-mono">({scores.reading}/40)</span>
                                                            </div>
                                                        ) : (
                                                            <span className="text-muted-foreground/60 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Writing Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.writingBand !== null ? (
                                                            <span className="font-bold text-foreground">{scores.writingBand.toFixed(1)}</span>
                                                        ) : (
                                                            <span className="text-muted-foreground/60 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Speaking Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.speakingBand !== null ? (
                                                            <span className="font-bold text-foreground">{scores.speakingBand.toFixed(1)}</span>
                                                        ) : (
                                                            <span className="text-muted-foreground/60 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Overall Band Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.overallBand !== null ? (
                                                            <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-black bg-amber-500/15 text-amber-800 dark:bg-amber-400/15 dark:text-amber-200 border border-amber-500/25">
                                                                <Award className="w-3.5 h-3.5 text-amber-500" />
                                                                {scores.overallBand.toFixed(1)}
                                                            </span>
                                                        ) : isFinished ? (
                                                            <span className="text-emerald-700 font-bold text-[10px] dark:text-emerald-300">Baholanmoqda</span>
                                                        ) : (
                                                            <span className="text-muted-foreground/60 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Actions */}
                                                    <td className="px-4 py-3 text-right">
                                                        <div className="inline-flex items-center gap-1.5">
                                                            {isFinished ? (
                                                                <>
                                                                    <Link
                                                                        href={route('attempt.show', item.id)}
                                                                        className="p-1.5 rounded-full bg-indigo-500/12 text-brand hover:bg-indigo-500/20 transition-colors"
                                                                        title="Natijani Ko'rish (View Result)"
                                                                    >
                                                                        <Eye className="w-4 h-4" />
                                                                    </Link>
                                                                    <button
                                                                        onClick={() => window.open(route('attempt.pdf', item.id), '_blank')}
                                                                        className="p-1.5 rounded-full bg-rose-500/12 text-rose-800 dark:bg-rose-400/15 dark:text-rose-200 hover:bg-rose-500/20 transition-colors"
                                                                        title="PDF Yuklab Olish (Download PDF)"
                                                                    >
                                                                        <FileDown className="w-4 h-4" />
                                                                    </button>
                                                                </>
                                                            ) : (
                                                                <Link
                                                                    href={`/practice?attempt_id=${item.id}`}
                                                                    className="px-3 py-1 btn-glass-primary text-[11px] font-bold rounded-full hover:brightness-110 transition"
                                                                >
                                                                    Davom etish
                                                                </Link>
                                                            )}
                                                            {isAdmin && (
                                                                <button
                                                                    onClick={() => handleDeleteAttemptClick(item)}
                                                                    className="p-1.5 rounded-full bg-muted text-muted-foreground hover:text-rose-700 hover:bg-rose-500/12 dark:hover:text-rose-200 transition-colors"
                                                                    title="O'chirish"
                                                                >
                                                                    <Trash2 className="w-4 h-4" />
                                                                </button>
                                                            )}
                                                        </div>
                                                    </td>
                                                </tr>
                                            );
                                        })}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </div>
                )}
            </div>

            {/* Delete Attempt Modal */}
            {selectedAttemptToDelete && openDeleteModal && (
                <DeleteItemModal
                    item={{
                        id: selectedAttemptToDelete.id,
                        name: selectedAttemptToDelete.mock_student?.name || selectedAttemptToDelete.mockStudent?.name || selectedAttemptToDelete.name || selectedAttemptToDelete.user?.name || `Urinish #${selectedAttemptToDelete.id}`
                    }}
                    open={openDeleteModal}
                    setOpen={setOpenDeleteModal}
                    onDelete={handleConfirmDelete}
                />
            )}
        </AppLayout>
    );
}
