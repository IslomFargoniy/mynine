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
        <div className="glass rounded-[22px] p-5 space-y-4">
            {/* Header */}
            <div className="flex items-center justify-between border-b border-divider pb-3">
                <div className="flex items-center gap-2.5">
                    <div className="p-2 rounded-xl bg-indigo-500/12 text-brand">
                        <Target className="w-4 h-4" />
                    </div>
                    <div>
                        <h3 className="text-sm font-bold text-foreground">
                            Savol Turlari Diagnostikasi & Kuchsiz Nuqtalar
                        </h3>
                        <p className="text-[11px] text-muted-foreground">
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
                            : 'bg-primary';

                    const badgeStyle = isStrong
                        ? 'bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200 border-emerald-500/25'
                        : isWeak
                            ? 'bg-rose-500/12 text-rose-800 dark:bg-rose-400/15 dark:text-rose-200 border-rose-500/25'
                            : 'bg-indigo-500/12 text-brand border-indigo-500/25';

                    return (
                        <div key={idx} className="space-y-1.5">
                            <div className="flex items-center justify-between text-xs font-semibold">
                                <span className="text-foreground flex items-center gap-1.5">
                                    {isWeak && <AlertTriangle className="w-3.5 h-3.5 text-rose-500" />}
                                    {isStrong && <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />}
                                    {stat.typeName}
                                </span>
                                <div className="flex items-center gap-2">
                                    <span className="text-muted-foreground text-[11px]">
                                        {stat.correctQuestions}/{stat.totalQuestions} to'g'ri
                                    </span>
                                    <span className={`px-2 py-0.5 rounded-full text-[11px] font-bold border ${badgeStyle}`}>
                                        {stat.accuracyPercentage}%
                                    </span>
                                </div>
                            </div>

                            {/* Progress bar */}
                            <div className="w-full h-2 rounded-full bg-muted overflow-hidden">
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
                <div className="mt-4 p-3 rounded-[18px] bg-amber-500/15 border border-amber-500/25 text-xs text-amber-800 dark:text-amber-200 flex items-start gap-2.5">
                    <BookOpen className="w-4 h-4 text-amber-700 dark:text-amber-300 shrink-0 mt-0.5" />
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
