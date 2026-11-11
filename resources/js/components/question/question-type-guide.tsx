import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { AlertTriangle, X } from 'lucide-react';

interface QuestionTypeGuideProps {
    type?: string; // e.g., 'multiple_choice', 'true_false', 'matching', etc.
    defaultOpen?: boolean;
}

export default function QuestionTypeGuide({ type, defaultOpen = false }: QuestionTypeGuideProps) {
    const { t } = useTranslation();
    const [isOpen, setIsOpen] = useState(defaultOpen);

    if (!type) return null;

    // Check if translation exists for this question type
    const title = t(`guide.${type}.title`);
    const desc = t(`guide.${type}.desc`);
    if (!title || title === `guide.${type}.title`) {
        return null;
    }

    const step1 = t(`guide.${type}.step1`);
    const step2 = t(`guide.${type}.step2`);
    const step3 = t(`guide.${type}.step3`);
    const steps = [step1, step2, step3].filter(
        (s) => s && !s.startsWith(`guide.${type}.step`)
    );

    const warning = t(`guide.${type}.warning`);
    const hasWarning = warning && !warning.startsWith(`guide.${type}.warning`);

    const example = t(`guide.${type}.example`);
    const hasExample = example && !example.startsWith(`guide.${type}.example`);

    if (!isOpen) {
        return (
            <div className="flex items-center">
                <button
                    type="button"
                    onClick={() => setIsOpen(true)}
                    className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold text-brand bg-indigo-500/12 border border-indigo-500/25 hover:bg-indigo-500/20 transition-all cursor-pointer"
                    title={t('guide.view_instructions')}
                >
                    <span className="w-4 h-4 rounded-full bg-primary text-primary-foreground flex items-center justify-center font-bold text-[11px] leading-none shrink-0">
                        !
                    </span>
                    <span>{t('guide.guide_button')}</span>
                </button>
            </div>
        );
    }

    return (
        <div className="rounded-[18px] border border-indigo-500/25 bg-indigo-500/12 p-3.5 space-y-2.5 text-sm text-foreground animate-in fade-in zoom-in-95 duration-150 relative">
            <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-2 font-bold text-brand">
                    <span className="w-5 h-5 rounded-full bg-primary text-primary-foreground flex items-center justify-center font-bold text-xs shrink-0">
                        !
                    </span>
                    <span className="text-xs sm:text-sm font-bold">{title}</span>
                </div>
                <button
                    type="button"
                    onClick={() => setIsOpen(false)}
                    className="p-1 rounded-full text-muted-foreground hover:text-foreground hover:bg-indigo-500/12 transition-colors cursor-pointer"
                    title={t('guide.close')}
                >
                    <X className="w-4 h-4" />
                </button>
            </div>

            {desc && (
                <p className="text-xs text-foreground/80 leading-relaxed">
                    {desc}
                </p>
            )}

            {steps.length > 0 && (
                <ul className="space-y-1 text-xs text-foreground/80 pl-1">
                    {steps.map((step, i) => (
                        <li key={i} className="flex items-start gap-1.5">
                            <span className="font-semibold text-brand shrink-0">•</span>
                            <span>{step}</span>
                        </li>
                    ))}
                </ul>
            )}

            {hasWarning && (
                <div className="flex items-center gap-1.5 p-2 rounded-xl bg-amber-500/15 dark:bg-amber-400/15 border border-amber-500/25 text-amber-800 dark:text-amber-200 text-xs font-semibold">
                    <AlertTriangle className="w-4 h-4 text-amber-700 shrink-0 dark:text-amber-300" />
                    <span>{warning}</span>
                </div>
            )}

            {hasExample && (
                <div className="text-[11px] font-mono bg-glass-subtle px-2.5 py-1 rounded-lg border border-indigo-500/25 text-brand inline-block">
                    {t('guide.example_label')}: {example}
                </div>
            )}
        </div>
    );
}
