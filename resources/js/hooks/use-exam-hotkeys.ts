import { useEffect, useState, useCallback } from 'react';

interface ExamHotkeysOptions {
    onNextQuestion?: () => void;
    onPrevQuestion?: () => void;
    onToggleFlag?: () => void;
    onToggleTimer?: () => void;
    onHighlight?: () => void;
    enabled?: boolean;
}

export function useExamHotkeys({
    onNextQuestion,
    onPrevQuestion,
    onToggleFlag,
    onToggleTimer,
    onHighlight,
    enabled = true,
}: ExamHotkeysOptions) {
    const [isHelpOpen, setIsHelpOpen] = useState<boolean>(false);

    const handleKeyDown = useCallback(
        (e: KeyboardEvent) => {
            if (!enabled) return;

            const isInputFocused =
                document.activeElement &&
                (document.activeElement.tagName === 'INPUT' ||
                    document.activeElement.tagName === 'TEXTAREA' ||
                    (document.activeElement as HTMLElement).isContentEditable);

            // Never hijack keys while the candidate is typing an answer
            if (isInputFocused && !e.altKey && e.key !== 'F1') return;

            // Alt + / or F1: Show Keyboard Shortcuts Help
            if ((e.altKey && e.key === '/') || e.key === 'F1') {
                e.preventDefault();
                setIsHelpOpen((prev) => !prev);
                return;
            }

            // Alt + N: Next Question
            if (e.altKey && (e.key.toLowerCase() === 'n' || e.key === 'ArrowRight')) {
                e.preventDefault();
                onNextQuestion?.();
                return;
            }

            // Alt + P: Previous Question
            if (e.altKey && (e.key.toLowerCase() === 'p' || e.key === 'ArrowLeft')) {
                e.preventDefault();
                onPrevQuestion?.();
                return;
            }

            // Alt + F: Flag Question
            if (e.altKey && e.key.toLowerCase() === 'f') {
                e.preventDefault();
                onToggleFlag?.();
                return;
            }

            // Alt + T: Toggle Timer
            if (e.altKey && e.key.toLowerCase() === 't') {
                e.preventDefault();
                onToggleTimer?.();
                return;
            }

            // Alt + H: Highlight
            if (e.altKey && e.key.toLowerCase() === 'h') {
                e.preventDefault();
                onHighlight?.();
                return;
            }
        },
        [enabled, onNextQuestion, onPrevQuestion, onToggleFlag, onToggleTimer, onHighlight]
    );

    useEffect(() => {
        window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, [handleKeyDown]);

    return {
        isHelpOpen,
        openHelp: () => setIsHelpOpen(true),
        closeHelp: () => setIsHelpOpen(false),
        toggleHelp: () => setIsHelpOpen((prev) => !prev),
    };
}
