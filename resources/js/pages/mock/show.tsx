import React, { useState } from 'react';
import AppLayout from '@/layouts/app-layout';
import { Head, Link, useForm, usePage } from '@inertiajs/react';
import { type BreadcrumbItem } from '@/types';
import { useTranslation } from 'react-i18next';
import { Users, Calendar, CheckCircle2, Clock, Activity, FileText, ArrowLeft, FileSpreadsheet, Eye, FileDown, Award, Trash2 } from 'lucide-react';
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
                            className="p-2 rounded-xl bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                        >
                            <ArrowLeft className="w-5 h-5" />
                        </Link>
                        <div>
                            <div className="flex items-center gap-2">
                                <h1 className="text-2xl font-black text-gray-900 dark:text-white">
                                    {mock.name}
                                </h1>
                                <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold ${
                                    isActive
                                        ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-800/40'
                                        : 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400'
                                }`}>
                                    {isActive ? '● Faol' : '○ Nofaol'}
                                </span>
                            </div>
                            <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5 flex items-center gap-1.5">
                                <span className="font-semibold text-indigo-600 dark:text-indigo-400">{mock.test?.folder?.name}</span>
                                <span>/</span>
                                <span>{mock.test?.name}</span>
                            </p>
                        </div>
                    </div>

                    {attempts.length > 0 && (
                        <div className="flex items-center gap-2">
                            <Button
                                onClick={() => exportAttemptsToExcel(attempts, `Mock_${mock.name}_Results`)}
                                variant="outline"
                                className="h-10 px-4 rounded-xl border-green-200 bg-green-50/50 text-green-700 hover:bg-green-100 dark:border-green-900/30 dark:bg-green-900/20 dark:text-green-400 gap-2 font-bold text-xs shadow-xs"
                            >
                                <FileSpreadsheet className="w-4 h-4 text-green-600" />
                                Natijalarni Excelga Yuklash
                            </Button>
                        </div>
                    )}
                </div>

                {/* Quick Stats Grid */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                    <div className="rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-4 shadow-xs flex items-center gap-3.5">
                        <div className="p-3 rounded-xl bg-indigo-50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400">
                            <Users className="w-5 h-5" />
                        </div>
                        <div>
                            <p className="text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Jami O'quvchilar</p>
                            <h3 className="text-xl font-black text-gray-900 dark:text-white mt-0.5">{totalStudents} ta</h3>
                        </div>
                    </div>

                    <div className="rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-4 shadow-xs flex items-center gap-3.5">
                        <div className="p-3 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400">
                            <CheckCircle2 className="w-5 h-5" />
                        </div>
                        <div>
                            <p className="text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Qatnashganlar</p>
                            <h3 className="text-xl font-black text-emerald-600 dark:text-emerald-400 mt-0.5">
                                {attendedStudents} ta <span className="text-xs text-gray-400 font-normal">({totalStudents > 0 ? Math.round((attendedStudents/totalStudents)*100) : 0}%)</span>
                            </h3>
                        </div>
                    </div>

                    <div className="rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-4 shadow-xs flex items-center gap-3.5">
                        <div className="p-3 rounded-xl bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400">
                            <Clock className="w-5 h-5" />
                        </div>
                        <div>
                            <p className="text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Kutilayotganlar</p>
                            <h3 className="text-xl font-black text-amber-600 dark:text-amber-400 mt-0.5">{pendingStudents} ta</h3>
                        </div>
                    </div>

                    <div className="rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-4 shadow-xs flex items-center gap-3.5">
                        <div className="p-3 rounded-xl bg-blue-50 dark:bg-blue-950/40 text-blue-600 dark:text-blue-400">
                            <Activity className="w-5 h-5" />
                        </div>
                        <div>
                            <p className="text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Topshirilgan Urinishlar</p>
                            <h3 className="text-xl font-black text-gray-900 dark:text-white mt-0.5">{attempts.length} ta</h3>
                        </div>
                    </div>
                </div>

                {/* Tabs Navigation */}
                <div className="flex border-b border-gray-200 dark:border-gray-800">
                    <button
                        onClick={() => setActiveTab('students')}
                        className={`px-5 py-3 font-bold text-xs flex items-center gap-2 border-b-2 transition-all cursor-pointer ${
                            activeTab === 'students'
                                ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400'
                                : 'border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300'
                        }`}
                    >
                        <Users className="w-4 h-4" />
                        <span>Mock O'quvchilari va Natijalar ({totalStudents})</span>
                    </button>

                    <button
                        onClick={() => setActiveTab('attempts')}
                        className={`px-5 py-3 font-bold text-xs flex items-center gap-2 border-b-2 transition-all cursor-pointer ${
                            activeTab === 'attempts'
                                ? 'border-indigo-600 text-indigo-600 dark:text-indigo-400'
                                : 'border-transparent text-gray-500 hover:text-gray-700 dark:hover:text-gray-300'
                        }`}
                    >
                        <FileText className="w-4 h-4" />
                        <span>Imtihon Urinishlari Batafsil ({attempts.length})</span>
                    </button>
                </div>

                {/* Tab Content */}
                {activeTab === 'students' && (
                    <div className="rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 shadow-xs">
                        <div className="flex items-center justify-between mb-4">
                            <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                                O'quvchilar Ro'yxati va Imtihon Kodlari
                            </h3>
                            <MockStudentManager
                                mockId={mock.id}
                                mockName={mock.name}
                                students={students}
                            />
                        </div>

                        {students.length === 0 ? (
                            <div className="text-center py-12 border border-dashed border-gray-200 dark:border-gray-800 rounded-xl text-xs text-gray-400 space-y-3">
                                <Users className="w-8 h-8 mx-auto text-gray-300 dark:text-gray-600" />
                                <p>Hali o'quvchilar biriktirilmagan.</p>
                                <p className="text-[11px]">"O'quvchilar" tugmasini bosib, yangi nomzodlarni qo'shing.</p>
                            </div>
                        ) : (
                            <div className="overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-800">
                                <table className="w-full text-xs text-left">
                                    <thead className="bg-gray-50 dark:bg-gray-800/80 text-gray-500 dark:text-gray-400 font-bold uppercase text-[10px]">
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
                                    <tbody className="divide-y divide-gray-100 dark:divide-gray-800 bg-white dark:bg-gray-900">
                                        {students.map((st: any, idx: number) => {
                                            const attempt = st.attempt;
                                            const scores = extractAttemptScores(attempt);
                                            const isFinished = !!attempt?.finished_at;

                                            return (
                                                <tr key={st.id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/40">
                                                    <td className="px-4 py-3 font-mono text-gray-400">{idx + 1}</td>
                                                    <td className="px-4 py-3 font-bold text-gray-900 dark:text-gray-100">{st.name}</td>
                                                    <td className="px-4 py-3 font-mono font-bold text-indigo-600 dark:text-indigo-400">
                                                        <span className="px-2 py-0.5 rounded-lg bg-indigo-50 dark:bg-indigo-950/40 border border-indigo-200 dark:border-indigo-800/40 text-[11px]">
                                                            {st.code}
                                                        </span>
                                                    </td>
                                                    <td className="px-4 py-3 text-center">
                                                        <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                                                            st.attended
                                                                ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-400'
                                                                : 'bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-400'
                                                        }`}>
                                                            {st.attended ? <CheckCircle2 className="w-3 h-3" /> : <Clock className="w-3 h-3" />}
                                                            {st.attended ? 'Qatnashdi' : 'Kutilmoqda'}
                                                        </span>
                                                    </td>

                                                    {/* Listening Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.listening !== null ? (
                                                            <div className="inline-flex flex-col items-center">
                                                                <span className="font-bold text-gray-900 dark:text-gray-100">{scores.listeningBand?.toFixed(1)}</span>
                                                                <span className="text-[9px] text-gray-400 font-mono">({scores.listening}/40)</span>
                                                            </div>
                                                        ) : (
                                                            <span className="text-gray-300 dark:text-gray-600 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Reading Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.reading !== null ? (
                                                            <div className="inline-flex flex-col items-center">
                                                                <span className="font-bold text-gray-900 dark:text-gray-100">{scores.readingBand?.toFixed(1)}</span>
                                                                <span className="text-[9px] text-gray-400 font-mono">({scores.reading}/40)</span>
                                                            </div>
                                                        ) : (
                                                            <span className="text-gray-300 dark:text-gray-600 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Writing Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.writingBand !== null ? (
                                                            <span className="font-bold text-gray-900 dark:text-gray-100">{scores.writingBand.toFixed(1)}</span>
                                                        ) : (
                                                            <span className="text-gray-300 dark:text-gray-600 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Speaking Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.speakingBand !== null ? (
                                                            <span className="font-bold text-gray-900 dark:text-gray-100">{scores.speakingBand.toFixed(1)}</span>
                                                        ) : (
                                                            <span className="text-gray-300 dark:text-gray-600 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Overall Band Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.overallBand !== null ? (
                                                            <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-black bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-400 border border-amber-300 dark:border-amber-700">
                                                                <Award className="w-3.5 h-3.5 text-amber-500" />
                                                                {scores.overallBand.toFixed(1)}
                                                            </span>
                                                        ) : isFinished ? (
                                                            <span className="text-emerald-600 font-bold text-[10px]">Baholanmoqda</span>
                                                        ) : (
                                                            <span className="text-gray-300 dark:text-gray-600 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Actions */}
                                                    <td className="px-4 py-3 text-right">
                                                        {attempt ? (
                                                            <div className="inline-flex items-center gap-1.5">
                                                                <Link
                                                                    href={route('attempt.show', attempt.id)}
                                                                    className="p-1.5 rounded-lg bg-indigo-50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 hover:bg-indigo-100 transition-colors"
                                                                    title="Natijani Ko'rish (View Result)"
                                                                >
                                                                    <Eye className="w-4 h-4" />
                                                                </Link>
                                                                <button
                                                                    onClick={() => window.open(route('attempt.pdf', attempt.id), '_blank')}
                                                                    className="p-1.5 rounded-lg bg-red-50 dark:bg-red-950/40 text-red-600 dark:text-red-400 hover:bg-red-100 transition-colors"
                                                                    title="PDF Yuklab Olish (Download PDF)"
                                                                >
                                                                    <FileDown className="w-4 h-4" />
                                                                </button>
                                                            </div>
                                                        ) : (
                                                            <span className="text-gray-400 italic text-[11px]">Boshlanmagan</span>
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
                    <div className="rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 shadow-xs">
                        <div className="flex items-center justify-between mb-4">
                            <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                                Imtihon Urinishlari Ro'yxati
                            </h3>
                            {attempts.length > 0 && (
                                <Button
                                    onClick={() => exportAttemptsToExcel(attempts, `Mock_${mock.name}_Attempts`)}
                                    variant="outline"
                                    className="h-8 px-3 rounded-xl border-green-200 bg-green-50/50 text-green-700 hover:bg-green-100 dark:border-green-900/30 dark:bg-green-900/20 dark:text-green-400 gap-1.5 font-bold text-xs shadow-xs"
                                >
                                    <FileSpreadsheet className="w-3.5 h-3.5 text-green-600" />
                                    Excelga Yuklash
                                </Button>
                            )}
                        </div>

                        {attempts.length === 0 ? (
                            <div className="text-center py-12 border border-dashed border-gray-200 dark:border-gray-800 rounded-xl text-xs text-gray-400 space-y-3">
                                <FileText className="w-8 h-8 mx-auto text-gray-300 dark:text-gray-600" />
                                <p>Hali imtihon topshirganlar yo'q.</p>
                                <p className="text-[11px]">O'quvchilar imtihonni topshirgandan so'ng natijalar bu yerda ko'rinadi.</p>
                            </div>
                        ) : (
                            <div className="overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-800">
                                <table className="w-full text-xs text-left">
                                    <thead className="bg-gray-50 dark:bg-gray-800/80 text-gray-500 dark:text-gray-400 font-bold uppercase text-[10px]">
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
                                    <tbody className="divide-y divide-gray-100 dark:divide-gray-800 bg-white dark:bg-gray-900">
                                        {attempts.map((item: any, idx: number) => {
                                            const scores = extractAttemptScores(item);
                                            const isFinished = !!item.finished_at;
                                            const studentName = item.mock_student?.name || item.mockStudent?.name || item.name || item.user?.name || "---";
                                            const studentCode = item.mock_student?.code || item.mockStudent?.code;

                                            return (
                                                <tr key={item.id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/40">
                                                    <td className="px-4 py-3 font-mono text-gray-400">{idx + 1}</td>
                                                    <td className="px-4 py-3 font-bold text-gray-900 dark:text-gray-100">
                                                        <div>{studentName}</div>
                                                        {item.user?.email && (
                                                            <span className="text-[10px] text-gray-400 font-normal">{item.user.email}</span>
                                                        )}
                                                    </td>
                                                    <td className="px-4 py-3 font-mono font-bold text-indigo-600 dark:text-indigo-400">
                                                        {studentCode ? (
                                                            <span className="px-2 py-0.5 rounded-lg bg-indigo-50 dark:bg-indigo-950/40 border border-indigo-200 dark:border-indigo-800/40 text-[11px]">
                                                                {studentCode}
                                                            </span>
                                                        ) : (
                                                            <span className="text-gray-300 dark:text-gray-600 font-mono text-[11px]">-</span>
                                                        )}
                                                    </td>
                                                    <td className="px-4 py-3 text-center">
                                                        <div className="inline-flex flex-col items-center gap-0.5">
                                                            <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                                                                isFinished
                                                                    ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-400'
                                                                    : 'bg-blue-50 text-blue-700 dark:bg-blue-950/40 dark:text-blue-400'
                                                            }`}>
                                                                {isFinished ? <CheckCircle2 className="w-3 h-3" /> : <Clock className="w-3 h-3" />}
                                                                {isFinished ? 'Tugatildi' : 'Jarayonda'}
                                                            </span>
                                                            {item.finished_at ? (
                                                                <span className="text-[9px] text-gray-400 font-mono">
                                                                    {format(new Date(item.finished_at), 'dd.MM.yyyy HH:mm')}
                                                                </span>
                                                            ) : item.started_at ? (
                                                                <span className="text-[9px] text-gray-400 font-mono">
                                                                    {format(new Date(item.started_at), 'dd.MM.yyyy HH:mm')}
                                                                </span>
                                                            ) : null}
                                                        </div>
                                                    </td>

                                                    {/* Listening Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.listening !== null ? (
                                                            <div className="inline-flex flex-col items-center">
                                                                <span className="font-bold text-gray-900 dark:text-gray-100">{scores.listeningBand?.toFixed(1)}</span>
                                                                <span className="text-[9px] text-gray-400 font-mono">({scores.listening}/40)</span>
                                                            </div>
                                                        ) : (
                                                            <span className="text-gray-300 dark:text-gray-600 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Reading Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.reading !== null ? (
                                                            <div className="inline-flex flex-col items-center">
                                                                <span className="font-bold text-gray-900 dark:text-gray-100">{scores.readingBand?.toFixed(1)}</span>
                                                                <span className="text-[9px] text-gray-400 font-mono">({scores.reading}/40)</span>
                                                            </div>
                                                        ) : (
                                                            <span className="text-gray-300 dark:text-gray-600 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Writing Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.writingBand !== null ? (
                                                            <span className="font-bold text-gray-900 dark:text-gray-100">{scores.writingBand.toFixed(1)}</span>
                                                        ) : (
                                                            <span className="text-gray-300 dark:text-gray-600 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Speaking Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.speakingBand !== null ? (
                                                            <span className="font-bold text-gray-900 dark:text-gray-100">{scores.speakingBand.toFixed(1)}</span>
                                                        ) : (
                                                            <span className="text-gray-300 dark:text-gray-600 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Overall Band Score */}
                                                    <td className="px-4 py-3 text-center">
                                                        {scores.overallBand !== null ? (
                                                            <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-black bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-400 border border-amber-300 dark:border-amber-700">
                                                                <Award className="w-3.5 h-3.5 text-amber-500" />
                                                                {scores.overallBand.toFixed(1)}
                                                            </span>
                                                        ) : isFinished ? (
                                                            <span className="text-emerald-600 font-bold text-[10px]">Baholanmoqda</span>
                                                        ) : (
                                                            <span className="text-gray-300 dark:text-gray-600 font-mono">-</span>
                                                        )}
                                                    </td>

                                                    {/* Actions */}
                                                    <td className="px-4 py-3 text-right">
                                                        <div className="inline-flex items-center gap-1.5">
                                                            {isFinished ? (
                                                                <>
                                                                    <Link
                                                                        href={route('attempt.show', item.id)}
                                                                        className="p-1.5 rounded-lg bg-indigo-50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 hover:bg-indigo-100 transition-colors"
                                                                        title="Natijani Ko'rish (View Result)"
                                                                    >
                                                                        <Eye className="w-4 h-4" />
                                                                    </Link>
                                                                    <button
                                                                        onClick={() => window.open(route('attempt.pdf', item.id), '_blank')}
                                                                        className="p-1.5 rounded-lg bg-red-50 dark:bg-red-950/40 text-red-600 dark:text-red-400 hover:bg-red-100 transition-colors"
                                                                        title="PDF Yuklab Olish (Download PDF)"
                                                                    >
                                                                        <FileDown className="w-4 h-4" />
                                                                    </button>
                                                                </>
                                                            ) : (
                                                                <Link
                                                                    href={`/practice?attempt_id=${item.id}`}
                                                                    className="px-2.5 py-1 bg-indigo-600 text-white text-[11px] font-bold rounded-lg hover:bg-indigo-700 transition shadow-xs"
                                                                >
                                                                    Davom etish
                                                                </Link>
                                                            )}
                                                            {isAdmin && (
                                                                <button
                                                                    onClick={() => handleDeleteAttemptClick(item)}
                                                                    className="p-1.5 rounded-lg bg-gray-50 dark:bg-gray-800 text-gray-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-950/40 dark:hover:text-red-400 transition-colors"
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
