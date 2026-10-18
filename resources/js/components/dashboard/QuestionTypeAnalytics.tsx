import React from 'react';
import { Target, AlertTriangle, CheckCircle2, BookOpen } from 'lucide-react';

export interface QuestionTypeStat {
    typeName: string;
    totalQuestions: number;
    correctQuestions: number;
    accuracyPercentage: number;
}

interface QuestionTypeAnalyticsProps {
    stats?: QuestionTypeStat[];
}

export default function QuestionTypeAnalytics({ stats }: QuestionTypeAnalyticsProps) {

    // Default demo stats if none provided yet
    const data: QuestionTypeStat[] = stats && stats.length > 0 ? stats : [
        { typeName: 'Multiple Choice', totalQuestions: 40, correctQuestions: 32, accuracyPercentage: 80 },
        { typeName: 'True / False / Not Given', totalQuestions: 35, correctQuestions: 21, accuracyPercentage: 60 },
        { typeName: 'Matching Headings', totalQuestions: 25, correctQuestions: 13, accuracyPercentage: 52 },
        { typeName: 'Fill in the Blanks', totalQuestions: 50, correctQuestions: 44, accuracyPercentage: 88 },
    ];

    const weakPoints = data.filter(d => d.accuracyPercentage < 65);

    return (
        <div className="rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 shadow-xs space-y-4">
            {/* Header */}
            <div className="flex items-center justify-between border-b border-gray-100 dark:border-gray-800 pb-3">
                <div className="flex items-center gap-2.5">
                    <div className="p-2 rounded-xl bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400">
                        <Target className="w-4 h-4" />
                    </div>
                    <div>
                        <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                            Savol Turlari Diagnostikasi & Kuchsiz Nuqtalar
                        </h3>
                        <p className="text-[11px] text-gray-500 dark:text-gray-400">
                            Imtihonlarda har bir savol turi bo'yicha aniqlik foizi va tavsiyalar
                        </p>
                    </div>
                </div>
            </div>

            {/* Performance Bars Grid */}
            <div className="space-y-3">
                {data.map((stat, idx) => {
                    const isWeak = stat.accuracyPercentage < 65;
                    const isStrong = stat.accuracyPercentage >= 80;

                    const barColor = isStrong
                        ? 'bg-emerald-500'
                        : isWeak
                            ? 'bg-rose-500'
                            : 'bg-blue-500';

                    const badgeStyle = isStrong
                        ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800/40'
                        : isWeak
                            ? 'bg-rose-50 text-rose-700 dark:bg-rose-950/40 dark:text-rose-400 border-rose-200 dark:border-rose-800/40'
                            : 'bg-blue-50 text-blue-700 dark:bg-blue-950/40 dark:text-blue-400 border-blue-200 dark:border-blue-800/40';

                    return (
                        <div key={idx} className="space-y-1.5">
                            <div className="flex items-center justify-between text-xs font-semibold">
                                <span className="text-gray-800 dark:text-gray-200 flex items-center gap-1.5">
                                    {isWeak && <AlertTriangle className="w-3.5 h-3.5 text-rose-500" />}
                                    {isStrong && <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />}
                                    {stat.typeName}
                                </span>
                                <div className="flex items-center gap-2">
                                    <span className="text-gray-500 dark:text-gray-400 text-[11px]">
                                        {stat.correctQuestions}/{stat.totalQuestions} to'g'ri
                                    </span>
                                    <span className={`px-2 py-0.5 rounded-full text-[11px] font-bold border ${badgeStyle}`}>
                                        {stat.accuracyPercentage}%
                                    </span>
                                </div>
                            </div>

                            {/* Progress bar */}
                            <div className="w-full h-2 rounded-full bg-gray-100 dark:bg-gray-800 overflow-hidden">
                                <div
                                    className={`h-full rounded-full transition-all duration-500 ${barColor}`}
                                    style={{ width: `${stat.accuracyPercentage}%` }}
                                />
                            </div>
                        </div>
                    );
                })}
            </div>

            {/* Smart Advice Box */}
            {weakPoints.length > 0 && (
                <div className="mt-4 p-3 rounded-xl bg-amber-50/60 dark:bg-amber-950/20 border border-amber-200/60 dark:border-amber-900/40 text-xs text-amber-900 dark:text-amber-200 flex items-start gap-2.5">
                    <BookOpen className="w-4 h-4 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
                    <div>
                        <span className="font-bold">Tavsiya: </span>
                        <span>
                            Natijalarga ko'ra, sizga <strong>{weakPoints.map(w => w.typeName).join(', ')}</strong> turlarida ko'proq amaliyot qilish tavsiya etiladi.
                        </span>
                    </div>
                </div>
            )}
        </div>
    );
}
