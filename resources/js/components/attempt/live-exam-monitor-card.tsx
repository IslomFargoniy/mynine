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
        <div className="glass-strong rounded-[22px] p-5 space-y-4">
            {/* Header */}
            <div className="flex items-center justify-between border-b border-divider pb-3">
                <div className="flex items-center gap-2.5">
                    <div className="p-2 rounded-[14px] bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200">
                        <Activity className="w-4 h-4 animate-pulse" />
                    </div>
                    <div>
                        <h3 className="text-sm font-bold text-foreground flex items-center gap-2">
                            Jonli Imtihon Monitoringi (Live Monitor)
                            <span className="px-2 py-0.5 rounded-full bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200 text-[10px] font-bold">
                                {inProgressCount} faol student
                            </span>
                        </h3>
                        <p className="text-[11px] text-muted-foreground">
                            Ayni vaqtda imtihon topshirayotgan o'quvchilar va ularning bosqichlari
                        </p>
                    </div>
                </div>
            </div>

            {/* List */}
            <div className="space-y-2.5">
                {attempts.map(item => (
                    <div key={item.id} className="glass-subtle p-3 rounded-[18px] flex items-center justify-between text-xs">
                        <div className="flex items-center gap-3">
                            <div className="w-8 h-8 rounded-full bg-indigo-500/12 text-brand flex items-center justify-center font-bold text-xs">
                                {item.userName.charAt(0)}
                            </div>
                            <div>
                                <p className="font-bold text-foreground">{item.userName}</p>
                                <p className="text-[11px] text-muted-foreground">{item.testTitle}</p>
                            </div>
                        </div>

                        <div className="flex items-center gap-3">
                            <span className="px-2.5 py-1 rounded-full bg-indigo-500/12 text-brand font-semibold text-[11px]">
                                📍 {item.currentModule}
                            </span>
                            <span className="text-muted-foreground text-[11px] flex items-center gap-1">
                                <Clock className="w-3 h-3" />
                                {item.startedAt}
                            </span>
                            <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold ${
                                item.status === 'in_progress'
                                    ? 'bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200'
                                    : 'bg-muted text-muted-foreground'
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
