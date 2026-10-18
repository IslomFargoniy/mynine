import { useEffect, useState, useCallback, useRef } from 'react';
import { toast } from 'sonner';

interface SavedDraft<T> {
    answers: T;
    lastSavedAt: string;
}

export function useExamAutoSave<T extends Record<string, any>>(attemptId: string | number, currentAnswers: T) {
    const [isOffline, setIsOffline] = useState(!navigator.onLine);
    const [lastSaved, setLastSaved] = useState<string | null>(null);
    const isInitialMount = useRef(true);

    const storageKey = `mynine_attempt_draft_${attemptId}`;

    // Track online/offline status
    useEffect(() => {
        const handleOnline = () => {
            setIsOffline(false);
            toast.success("Internet aloqasi tiklandi. Javoblar sinxronlanmoqda...", { id: 'network-status' });
        };

        const handleOffline = () => {
            setIsOffline(true);
            toast.warning("Internet aloqasi uzildi. Javoblar lokal xotirada saqlanadi.", { id: 'network-status', duration: 10000 });
        };

        window.addEventListener('online', handleOnline);
        window.addEventListener('offline', handleOffline);

        return () => {
            window.removeEventListener('online', handleOnline);
            window.removeEventListener('offline', handleOffline);
        };
    }, []);

    // Save current answers to localStorage on change
    useEffect(() => {
        if (isInitialMount.current) {
            isInitialMount.current = false;
            return;
        }

        if (!attemptId) return;

        try {
            const now = new Date().toLocaleTimeString();
            const draft: SavedDraft<T> = {
                answers: currentAnswers,
                lastSavedAt: now
            };
            localStorage.setItem(storageKey, JSON.stringify(draft));
            setLastSaved(now);
        } catch (e) {
            console.error("AutoSave to localStorage failed:", e);
        }
    }, [attemptId, currentAnswers, storageKey]);

    // Restore draft helper
    const restoreDraft = useCallback((): T | null => {
        if (!attemptId) return null;
        try {
            const raw = localStorage.getItem(storageKey);
            if (!raw) return null;
            const parsed: SavedDraft<T> = JSON.parse(raw);
            return parsed.answers;
        } catch {
            return null;
        }
    }, [attemptId, storageKey]);

    // Clear draft helper
    const clearDraft = useCallback(() => {
        if (!attemptId) return;
        localStorage.removeItem(storageKey);
    }, [attemptId, storageKey]);

    return {
        isOffline,
        lastSaved,
        restoreDraft,
        clearDraft
    };
}
