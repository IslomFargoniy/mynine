import { useEffect, useState } from 'react';

const read = () => typeof document !== 'undefined' && document.documentElement.classList.contains('dark');

/**
 * Whether the `dark` class is currently on <html>. This is the single source of truth for the
 * theme (set by the appearance toggle, the system preference, the Telegram Mini App, or forced off
 * by the exam room), so charts/toasts that need JS colours follow it instead of re-deriving it.
 */
export function useIsDark(): boolean {
    const [isDark, setIsDark] = useState(read);

    useEffect(() => {
        const root = document.documentElement;
        const observer = new MutationObserver(() => setIsDark(read()));
        observer.observe(root, { attributes: true, attributeFilter: ['class'] });
        setIsDark(read());

        return () => observer.disconnect();
    }, []);

    return isDark;
}
