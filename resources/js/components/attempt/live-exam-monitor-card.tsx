import React from 'react';
import { Activity, Clock } from 'lucide-react';

export interface ActiveAttempt {
    id: number;
    userName: string;
    testTitle: string;
    startedAt: string;
    currentModule: string; // Listening, Reading, Writing, Speaking
    status: 'in_progress' | 'submitted' | 'paused';
}

interface LiveExamMonitorCardProps {
    activeAttempts?: ActiveAttempt[];
}

export default function LiveExamMonitorCard({ activeAttempts }: LiveExamMonitorCardProps) {

    const attempts: ActiveAttempt[] = activeAttempts && activeAttempts.length > 0 ? activeAttempts : [
        { id: 101, userName: 'Jasur Bek', testTitle: 'IELTS Mock Test 19', startedAt: '14:05', currentModule: 'Reading', status: 'in_progress' },
        { id: 102, userName: 'Malika Aliyeva', testTitle: 'IELTS Mock Test 20', startedAt: '14:15', currentModule: 'Writing', status: 'in_progress' },
        { id: 103, userName: 'Sardor Qodirov', testTitle: 'General IELTS Test 1', startedAt: '13:45', currentModule: 'Speaking', status: 'submitted' },
    ];

    const inProgressCount = attempts.filter(a => a.status === 'in_progress').length;

    return (
        <div className="rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 shadow-xs space-y-4">
            {/* Header */}
            <div className="flex items-center justify-between border-b border-gray-100 dark:border-gray-800 pb-3">
                <div className="flex items-center gap-2.5">
                    <div className="p-2 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400">
                        <Activity className="w-4 h-4 animate-pulse" />
                    </div>
                    <div>
                        <h3 className="text-sm font-bold text-gray-900 dark:text-white flex items-center gap-2">
                            Jonli Imtihon Monitoringi (Live Monitor)
                            <span className="px-2 py-0.5 rounded-full bg-emerald-100 dark:bg-emerald-900/60 text-emerald-700 dark:text-emerald-300 text-[10px] font-bold">
                                {inProgressCount} faol student
                            </span>
                        </h3>
                        <p className="text-[11px] text-gray-500 dark:text-gray-400">
                            Ayni vaqtda imtihon topshirayotgan o'quvchilar va ularning bosqichlari
                        </p>
                    </div>
                </div>
            </div>

            {/* List */}
            <div className="space-y-2.5">
                {attempts.map(item => (
                    <div key={item.id} className="p-3 rounded-xl border border-gray-100 dark:border-gray-800/80 bg-gray-50/50 dark:bg-gray-800/40 flex items-center justify-between text-xs">
                        <div className="flex items-center gap-3">
                            <div className="w-8 h-8 rounded-full bg-blue-100 dark:bg-blue-900/40 text-blue-600 dark:text-blue-400 flex items-center justify-center font-bold text-xs">
                                {item.userName.charAt(0)}
                            </div>
                            <div>
                                <p className="font-bold text-gray-900 dark:text-gray-100">{item.userName}</p>
                                <p className="text-[11px] text-gray-500 dark:text-gray-400">{item.testTitle}</p>
                            </div>
                        </div>

                        <div className="flex items-center gap-3">
                            <span className="px-2.5 py-1 rounded-lg bg-blue-50 dark:bg-blue-950/40 text-blue-700 dark:text-blue-300 font-semibold text-[11px]">
                                📍 {item.currentModule}
                            </span>
                            <span className="text-gray-400 text-[11px] flex items-center gap-1">
                                <Clock className="w-3 h-3" />
                                {item.startedAt}
                            </span>
                            <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold ${
                                item.status === 'in_progress'
                                    ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-400'
                                    : 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400'
                            }`}>
                                {item.status === 'in_progress' ? '● Jonli' : '✓ Topshirildi'}
                            </span>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}
