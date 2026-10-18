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
                    className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-semibold text-blue-700 dark:text-blue-300 bg-blue-50/80 dark:bg-blue-950/50 border border-blue-200 dark:border-blue-800/80 hover:bg-blue-100 dark:hover:bg-blue-900 transition-all cursor-pointer shadow-2xs"
                    title={t('guide.view_instructions') || "Savol turi bo'yicha yo'riqnomani ko'rish"}
                >
                    <span className="w-4 h-4 rounded-full bg-blue-600 dark:bg-blue-500 text-white flex items-center justify-center font-bold text-[11px] leading-none shrink-0 shadow-xs">
                        !
                    </span>
                    <span>{t('guide.guide_button') || "Ko'rsatma va qoidalar"}</span>
                </button>
            </div>
        );
    }

    return (
        <div className="rounded-xl border border-blue-200 bg-blue-50/70 dark:bg-blue-950/40 dark:border-blue-800 p-3.5 space-y-2.5 text-sm text-gray-800 dark:text-gray-200 animate-in fade-in zoom-in-95 duration-150 relative">
            <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-2 font-bold text-blue-900 dark:text-blue-200">
                    <span className="w-5 h-5 rounded-full bg-blue-600 dark:bg-blue-500 text-white flex items-center justify-center font-bold text-xs shrink-0 shadow-xs">
                        !
                    </span>
                    <span className="text-xs sm:text-sm font-bold">{title}</span>
                </div>
                <button
                    type="button"
                    onClick={() => setIsOpen(false)}
                    className="p-1 rounded-md text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 hover:bg-blue-100 dark:hover:bg-blue-900/60 transition-colors cursor-pointer"
                    title={t('guide.close') || "Yopish"}
                >
                    <X className="w-4 h-4" />
                </button>
            </div>

            {desc && (
                <p className="text-xs text-gray-600 dark:text-gray-300 leading-relaxed">
                    {desc}
                </p>
            )}

            {steps.length > 0 && (
                <ul className="space-y-1 text-xs text-gray-700 dark:text-gray-300 pl-1">
                    {steps.map((step, i) => (
                        <li key={i} className="flex items-start gap-1.5">
                            <span className="font-semibold text-blue-600 dark:text-blue-400 shrink-0">•</span>
                            <span>{step}</span>
                        </li>
                    ))}
                </ul>
            )}

            {hasWarning && (
                <div className="flex items-center gap-1.5 p-2 rounded-lg bg-amber-100/80 dark:bg-amber-950/60 border border-amber-300 dark:border-amber-800 text-amber-900 dark:text-amber-200 text-xs font-semibold">
                    <AlertTriangle className="w-4 h-4 text-amber-600 shrink-0" />
                    <span>{warning}</span>
                </div>
            )}

            {hasExample && (
                <div className="text-[11px] font-mono bg-white dark:bg-gray-900/60 px-2.5 py-1 rounded border border-blue-100 dark:border-blue-900 text-blue-800 dark:text-blue-300 inline-block">
                    {t('guide.example_label') || 'Misol'}: {example}
                </div>
            )}
        </div>
    );
}
