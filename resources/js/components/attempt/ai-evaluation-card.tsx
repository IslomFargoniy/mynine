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
        <div className="rounded-[22px] border border-indigo-500/25 bg-indigo-500/[0.06] dark:bg-indigo-400/[0.08] p-5 space-y-4 my-3">
            {/* Header */}
            <div className="flex items-center justify-between border-b border-indigo-500/25 pb-3">
                <div className="flex items-center gap-2">
                    <div className="p-2 rounded-xl btn-glass-primary">
                        <Sparkles className="w-4 h-4 animate-pulse" />
                    </div>
                    <div>
                        <h4 className="text-sm font-bold text-foreground flex items-center gap-2">
                            AI Examiner Evaluation
                            <span className="px-2 py-0.5 rounded-full bg-indigo-500/12 text-brand text-[10px] font-bold">
                                Automated IELTS
                            </span>
                        </h4>
                        <p className="text-[11px] text-muted-foreground">
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
                            className="inline-flex items-center gap-1 px-3 py-1.5 rounded-full border border-indigo-500/25 bg-glass-subtle text-brand hover:bg-indigo-500/12 text-xs font-semibold transition-all cursor-pointer"
                            title="Qayta baholash"
                        >
                            <RefreshCw className={`w-3.5 h-3.5 ${isReEvaluating ? 'animate-spin' : ''}`} />
                            <span className="hidden sm:inline">Qayta AI tekshiruv</span>
                        </button>
                    )}

                    {score !== null && score !== undefined && (
                        <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full btn-glass-primary font-extrabold text-sm">
                            <Award className="w-4 h-4" />
                            <span>Band {score}</span>
                        </div>
                    )}
                </div>
            </div>

            {/* Individual Criteria Grid */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
                <div className="glass-subtle p-3 rounded-[18px] text-center">
                    <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Task Response</p>
                    <p className="text-base font-extrabold text-brand mt-0.5">{taskResponse}</p>
                </div>
                <div className="glass-subtle p-3 rounded-[18px] text-center">
                    <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Coherence</p>
                    <p className="text-base font-extrabold text-brand mt-0.5">{coherence}</p>
                </div>
                <div className="glass-subtle p-3 rounded-[18px] text-center">
                    <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Lexical Resource</p>
                    <p className="text-base font-extrabold text-brand mt-0.5">{lexical}</p>
                </div>
                <div className="glass-subtle p-3 rounded-[18px] text-center">
                    <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Grammar</p>
                    <p className="text-base font-extrabold text-brand mt-0.5">{grammar}</p>
                </div>
            </div>

            {/* Detailed Feedback Text */}
            <div className="glass-subtle rounded-[18px] p-3.5 text-xs leading-relaxed text-foreground space-y-2">
                <div className="flex items-center gap-1.5 font-bold text-foreground">
                    <FileText className="w-3.5 h-3.5 text-brand" />
                    <span>Examiner Feedback & Suggestions:</span>
                </div>
                <p className="whitespace-pre-wrap text-foreground font-normal">
                    {feedbackText}
                </p>
            </div>
        </div>
    );
}
