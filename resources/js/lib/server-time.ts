import { format } from 'date-fns';

/**
 * Staff pages show every time as the center's (server) wall-clock time, Asia/Tashkent, whatever the
 * browser's time zone. Values from the server come either as naive wall-clock strings ("2026-11-12 09:00:00",
 * already Tashkent time) or as instants with an offset ("…T04:00:00Z", "…T09:00:00+05:00").
 */
export const SERVER_TIME_ZONE = 'Asia/Tashkent';

const NAIVE = /^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?)?$/;

let parts: Intl.DateTimeFormat | null = null;

function zoneParts(instant: Date): Date {
    parts ??= new Intl.DateTimeFormat('en-US', {
        timeZone: SERVER_TIME_ZONE,
        hourCycle: 'h23',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
    });
    const p: Record<string, number> = {};
    parts.formatToParts(instant).forEach(({ type, value }) => (p[type] = Number(value)));
    return new Date(p.year, p.month - 1, p.day, p.hour % 24, p.minute, p.second);
}

/**
 * A Date whose local fields (getHours(), date-fns format...) are the Tashkent wall-clock time of the value.
 * Only for display and for datetime inputs; do not use its getTime() as the real instant.
 */
export function serverWallClock(value?: string | number | Date | null): Date | null {
    if (value === null || value === undefined || value === '') return null;
    if (typeof value === 'string') {
        const m = value.trim().match(NAIVE);
        if (m) {
            return new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]), Number(m[4] ?? 0), Number(m[5] ?? 0), Number(m[6] ?? 0));
        }
    }
    const instant = value instanceof Date ? value : new Date(value);
    return Number.isNaN(instant.getTime()) ? null : zoneParts(instant);
}

/** Current Tashkent wall-clock time (see serverWallClock). */
export function serverNow(): Date {
    return zoneParts(new Date());
}

/** date-fns pattern formatted in Tashkent time; `fallback` for empty/invalid values. */
export function formatServerTime(value: string | number | Date | null | undefined, pattern: string, fallback = '—'): string {
    const date = serverWallClock(value);
    return date ? format(date, pattern) : fallback;
}

/** Tashkent wall-clock value for <input type="datetime-local"> ("yyyy-MM-ddTHH:mm"); the server reads it back as Tashkent time. */
export function toServerInput(value?: string | null): string {
    return formatServerTime(value, "yyyy-MM-dd'T'HH:mm", '');
}

/** Real instant (ms) of a server value, treating naive strings as Tashkent time (UTC+5, no DST). */
export function serverInstant(value?: string | null): number {
    if (!value) return NaN;
    const m = value.trim().match(NAIVE);
    if (m) {
        return Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3]), Number(m[4] ?? 0) - 5, Number(m[5] ?? 0), Number(m[6] ?? 0));
    }
    return new Date(value).getTime();
}
