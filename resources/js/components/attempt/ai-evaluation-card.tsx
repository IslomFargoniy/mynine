import React, { useState } from 'react';
import { Sparkles, Award, FileText, RefreshCw } from 'lucide-react';
import { router } from '@inertiajs/react';
import { toast } from 'sonner';

interface AIEvaluationCardProps {
    rawNote?: string | null;
    score?: number | null;
    essayText?: string | null;
    answerId?: number;
}

export default function AIEvaluationCard({ rawNote, score, essayText, answerId }: AIEvaluationCardProps) {
    const [isReEvaluating, setIsReEvaluating] = useState(false);
    if (!rawNote && !answerId) return null;

    const handleReEvaluate = () => {
        if (!answerId) return;
        setIsReEvaluating(true);
        router.post(route('attempt-answer.re-evaluate-ai', answerId), {}, {
            preserveScroll: true,
            onSuccess: () => {
                toast.success("AI qayta baholash jarayoni boshlandi!");
                setIsReEvaluating(false);
            },
            onError: () => {
                toast.error("Xatolik yuz berdi.");
                setIsReEvaluating(false);
            }
        });
    };

    // Parse scores and criteria from markdown text
    const extractCriteriaScore = (criterion: string): string => {
        if (!rawNote) return '-';
        const regex = new RegExp(`- \\*\\*${criterion}:\\*\\*\\s*([0-9.]+)`, 'i');
        const match = rawNote.match(regex);
        return match ? match[1] : '-';
    };

    const taskResponse = extractCriteriaScore('Task Response');
    const coherence = extractCriteriaScore('Coherence & Cohesion');
    const lexical = extractCriteriaScore('Lexical Resource');
    const grammar = extractCriteriaScore('Grammatical Range & Accuracy');

    // Extract feedback body
    const feedbackMatch = rawNote ? rawNote.match(/#### Detailed Feedback:\s*([\s\S]*)/i) : null;
    const feedbackText = feedbackMatch ? feedbackMatch[1].trim() : (rawNote || "AI baholash kutilmoqda...");

    const wordCount = essayText ? essayText.trim().split(/\s+/).filter(Boolean).length : 0;

    return (
        <div className="rounded-2xl border border-indigo-100 dark:border-indigo-900/40 bg-gradient-to-br from-indigo-50/40 via-white to-purple-50/30 dark:from-gray-900 dark:via-gray-900 dark:to-indigo-950/20 p-5 shadow-xs space-y-4 my-3">
            {/* Header */}
            <div className="flex items-center justify-between border-b border-indigo-100 dark:border-gray-800 pb-3">
                <div className="flex items-center gap-2">
                    <div className="p-2 rounded-xl bg-indigo-600 text-white shadow-xs">
                        <Sparkles className="w-4 h-4 animate-pulse" />
                    </div>
                    <div>
                        <h4 className="text-sm font-bold text-gray-900 dark:text-white flex items-center gap-2">
                            AI Examiner Evaluation
                            <span className="px-2 py-0.5 rounded-full bg-indigo-100 dark:bg-indigo-900/60 text-indigo-700 dark:text-indigo-300 text-[10px] font-bold">
                                Automated IELTS
                            </span>
                        </h4>
                        <p className="text-[11px] text-gray-500 dark:text-gray-400">
                            {wordCount > 0 ? `Word Count: ${wordCount} words` : 'Essay Assessment'}
                        </p>
                    </div>
                </div>

                <div className="flex items-center gap-2">
                    {answerId && (
                        <button
                            type="button"
                            onClick={handleReEvaluate}
                            disabled={isReEvaluating}
                            className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-xl border border-indigo-200 dark:border-indigo-800 text-indigo-600 dark:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-950 text-xs font-semibold transition-all cursor-pointer"
                            title="Qayta baholash"
                        >
                            <RefreshCw className={`w-3.5 h-3.5 ${isReEvaluating ? 'animate-spin' : ''}`} />
                            <span className="hidden sm:inline">Qayta AI tekshiruv</span>
                        </button>
                    )}

                    {score !== null && score !== undefined && (
                        <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-indigo-600 text-white font-extrabold text-sm shadow-xs">
                            <Award className="w-4 h-4" />
                            <span>Band {score}</span>
                        </div>
                    )}
                </div>
            </div>

            {/* Individual Criteria Grid */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
                <div className="p-3 rounded-xl bg-white dark:bg-gray-800/80 border border-gray-100 dark:border-gray-800 text-center">
                    <p className="text-[10px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Task Response</p>
                    <p className="text-base font-extrabold text-indigo-600 dark:text-indigo-400 mt-0.5">{taskResponse}</p>
                </div>
                <div className="p-3 rounded-xl bg-white dark:bg-gray-800/80 border border-gray-100 dark:border-gray-800 text-center">
                    <p className="text-[10px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Coherence</p>
                    <p className="text-base font-extrabold text-indigo-600 dark:text-indigo-400 mt-0.5">{coherence}</p>
                </div>
                <div className="p-3 rounded-xl bg-white dark:bg-gray-800/80 border border-gray-100 dark:border-gray-800 text-center">
                    <p className="text-[10px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Lexical Resource</p>
                    <p className="text-base font-extrabold text-indigo-600 dark:text-indigo-400 mt-0.5">{lexical}</p>
                </div>
                <div className="p-3 rounded-xl bg-white dark:bg-gray-800/80 border border-gray-100 dark:border-gray-800 text-center">
                    <p className="text-[10px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Grammar</p>
                    <p className="text-base font-extrabold text-indigo-600 dark:text-indigo-400 mt-0.5">{grammar}</p>
                </div>
            </div>

            {/* Detailed Feedback Text */}
            <div className="bg-white/80 dark:bg-gray-800/60 rounded-xl p-3.5 border border-gray-100 dark:border-gray-800 text-xs leading-relaxed text-gray-700 dark:text-gray-300 space-y-2">
                <div className="flex items-center gap-1.5 font-bold text-gray-900 dark:text-white">
                    <FileText className="w-3.5 h-3.5 text-indigo-500" />
                    <span>Examiner Feedback & Suggestions:</span>
                </div>
                <p className="whitespace-pre-wrap text-gray-600 dark:text-gray-300 font-normal">
                    {feedbackText}
                </p>
            </div>
        </div>
    );
}
