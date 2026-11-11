import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { CheckCircle2, AlertTriangle, HelpCircle, Layers } from 'lucide-react';

interface LiveGapDetectorProps {
    textarea: string;
    startIndex?: number; // Optional starting question number (e.g., 8)
    onInsertGap?: (gapText?: string) => void;
}

export interface DetectedGap {
    index: number;
    questionNumber: number;
    rawText: string;
    cleanText: string;
    alternatives: string[];
}

export default function LiveGapDetector({
    textarea = '',
    startIndex = 1,
    onInsertGap: _onInsertGap
}: LiveGapDetectorProps) {
    const { t } = useTranslation();

    const { gaps, hasUnclosedBracket, hasEmptyBracket } = useMemo(() => {
        const raw = textarea || '';

        // Strip HTML attributes that might contain curly braces or data attributes
        const cleanedHtml = raw.replace(/\s*data-v-[a-z0-9-]+="[^"]*"/gi, '');

        // Check for unclosed brackets: count of '{' vs '}'
        const openCount = (cleanedHtml.match(/\{/g) || []).length;
        const closeCount = (cleanedHtml.match(/\}/g) || []).length;
        const hasUnclosed = openCount !== closeCount;

        const regex = /\{([^}]*)\}/g;
        const list: DetectedGap[] = [];
        let match: RegExpExecArray | null;
        let emptyFound = false;

        let idx = 0;
        while ((match = regex.exec(cleanedHtml)) !== null) {
            const rawInside = match[1];
            // Strip any internal HTML tags (e.g. <span>caves</span>)
            const cleanInside = rawInside.replace(/<[^>]*>/g, '').trim();

            if (!cleanInside) {
                emptyFound = true;
                continue;
            }

            // Split by alternative delimiters: /, ;, |
            const alternatives = cleanInside
                .split(/[/;|]/)
                .map((alt) => alt.trim())
                .filter((alt) => alt.length > 0);

            list.push({
                index: idx,
                questionNumber: startIndex + idx,
                rawText: rawInside,
                cleanText: cleanInside,
                alternatives: alternatives.length > 0 ? alternatives : [cleanInside]
            });
            idx++;
        }

        return {
            gaps: list,
            hasUnclosedBracket: hasUnclosed,
            hasEmptyBracket: emptyFound
        };
    }, [textarea, startIndex]);

    return (
        <div className="rounded-[18px] border border-indigo-500/25 bg-indigo-500/12 p-2.5 space-y-2 transition-all duration-200">
            {/* Header info */}
            <div className="flex items-center justify-between gap-2 flex-wrap">
                <div className="flex items-center gap-1.5">
                    <Layers className="w-3.5 h-3.5 text-brand shrink-0" />
                    <h4 className="text-[11px] font-bold uppercase tracking-wider text-brand">
                        {t('live_gap_detector_title')}
                    </h4>
                    <span className="text-[11px] text-brand">
                        • {gaps.length > 0
                            ? (t('gaps_detected_count', { count: gaps.length }) || `${gaps.length} ta savol aniqlandi`)
                            : (t('no_gaps_detected'))}
                    </span>
                </div>

                {/* Question count badge */}
                {gaps.length > 0 && (
                    <div className="px-2 py-0.5 rounded-full bg-indigo-500/12 border border-indigo-500/25 text-brand text-[10px] font-bold flex items-center gap-1">
                        <CheckCircle2 className="w-3 h-3 text-brand" />
                        <span>
                            {t('questions_count', { count: gaps.length })}
                        </span>
                    </div>
                )}
            </div>

            {/* Warnings if any */}
            {hasUnclosedBracket && (
                <div className="flex items-center gap-1.5 p-2 rounded-xl bg-amber-500/15 dark:bg-amber-400/15 border border-amber-500/30 text-amber-800 dark:text-amber-200 text-xs font-semibold animate-pulse">
                    <AlertTriangle className="w-3.5 h-3.5 text-amber-700 shrink-0 dark:text-amber-300" />
                    <span>
                        {t('unclosed_bracket_warning')}
                    </span>
                </div>
            )}

            {hasEmptyBracket && (
                <div className="flex items-center gap-1.5 p-2 rounded-xl bg-amber-500/12 dark:bg-amber-400/12 border border-amber-500/25 text-amber-800 dark:text-amber-200 text-xs font-medium">
                    <AlertTriangle className="w-3.5 h-3.5 text-amber-700 shrink-0 dark:text-amber-300" />
                    <span>
                        {t('empty_bracket_warning')}
                    </span>
                </div>
            )}

            {/* Gaps List / Badges */}
            {gaps.length > 0 ? (
                <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-1.5">
                    {gaps.map((gap) => {
                        const isMulti = gap.alternatives.length > 1;
                        return (
                            <div
                                key={gap.index}
                                className={`p-1.5 rounded-lg border flex items-center gap-1.5 text-xs transition-all ${
                                    isMulti
                                        ? 'bg-violet-500/12 border-violet-500/25 text-violet-800 dark:bg-violet-400/15 dark:text-violet-200'
                                        : 'bg-glass-subtle border-glass-edge text-foreground'
                                }`}
                            >
                                <span className="shrink-0 px-1 py-0.2 rounded font-mono font-bold bg-primary text-primary-foreground text-[10px]">
                                    Q{gap.questionNumber}
                                </span>
                                <div className="min-w-0 flex-1 truncate">
                                    {isMulti ? (
                                        <div className="font-semibold text-[10px] flex items-center gap-1 truncate">
                                            {gap.alternatives.map((alt, ai) => (
                                                <React.Fragment key={ai}>
                                                    <span className="font-mono font-bold truncate">
                                                        {alt}
                                                    </span>
                                                    {ai < gap.alternatives.length - 1 && (
                                                        <span className="text-[9px] text-violet-700 dark:text-violet-300 font-normal">
                                                            /
                                                        </span>
                                                    )}
                                                </React.Fragment>
                                            ))}
                                        </div>
                                    ) : (
                                        <span className="font-mono font-bold text-[11px] truncate block">
                                            {gap.cleanText}
                                        </span>
                                    )}
                                </div>
                            </div>
                        );
                    })}
                </div>
            ) : (
                <div className="p-2 bg-glass-subtle rounded-xl border border-dashed border-indigo-500/25 text-xs text-muted-foreground space-y-0.5">
                    <div className="flex items-center gap-1 font-semibold text-brand text-[11px]">
                        <HelpCircle className="w-3 h-3 text-brand shrink-0" />
                        <span>{t('how_to_create_gaps')}</span>
                    </div>
                    <p className="text-[11px] leading-snug text-muted-foreground">
                        {t('gaps_instructions_hint')}
                    </p>
                </div>
            )}
        </div>
    );
}
