import { toast } from 'sonner';

/**
 * One message, one toast, everywhere. Many actions show a toast in their onSuccess and the server flashes its own
 * message for the same action (FlashMessages), and a flash can be re-read on a later reload of the same page. So:
 *   - the same text never stacks: it reuses one toast (id = kind + text);
 *   - a second toast of the same kind within a moment of the first is the same event told twice: dropped.
 */
const WINDOW_MS = 1500;
const kinds = ['success', 'error', 'warning', 'info'] as const;
const last: Record<string, number> = {};

type ToastFn = (message: unknown, data?: Record<string, unknown>) => string | number;

for (const kind of kinds) {
    const original = toast[kind] as unknown as ToastFn;
    (toast as unknown as Record<string, ToastFn>)[kind] = (message, data) => {
        const text = typeof message === 'string' ? message : null;
        const now = Date.now();
        if (text !== null && data?.id === undefined) {
            if (now - (last[kind] ?? 0) < WINDOW_MS) return `${kind}:${text}`;
            last[kind] = now;
            return original(message, { ...data, id: `${kind}:${text}` });
        }
        return original(message, data);
    };
}
