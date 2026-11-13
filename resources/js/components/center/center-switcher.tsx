import { router, usePage } from '@inertiajs/react';
import { Building2, Check, ChevronDown } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';

interface CenterOption {
    id: number;
    name: string;
    code: string;
    logo_url: string | null;
    suspended: boolean;
}

interface Props {
    auth: { center: { id: number; name: string; code: string } | null; centers: CenterOption[] | null };
    [key: string]: unknown;
}

/** SuperAdmin: the center every center page works on (header, left of the language switcher). */
export default function CenterSwitcher() {
    const { t } = useTranslation();
    const { auth } = usePage<Props>().props;
    const [open, setOpen] = useState(false);
    const ref = useRef<HTMLDivElement>(null);

    useEffect(() => {
        const close = (e: MouseEvent) => ref.current && !ref.current.contains(e.target as Node) && setOpen(false);
        document.addEventListener('mousedown', close);
        return () => document.removeEventListener('mousedown', close);
    }, []);

    const centers = auth.centers;
    if (!centers || centers.length < 2) return null;
    const current = centers.find((c) => c.id === auth.center?.id);

    const pick = (c: CenterOption) => {
        setOpen(false);
        if (c.id === current?.id) return;
        // A list page stays (it shows the other center's list); a record page (/mock/5) goes to the mock list.
        const stay = !/\/\d+(\/|$)/.test(window.location.pathname);
        router.post(route('centers.switch', c.id), { stay: stay ? 1 : 0 }, { preserveScroll: true });
    };

    return (
        <div ref={ref} className="relative">
            <button
                type="button"
                onClick={() => setOpen((o) => !o)}
                title={t('exam_admin.nav.centers')}
                className="inline-flex h-9 max-w-[12rem] cursor-pointer items-center gap-1.5 rounded-full border border-glass-edge bg-glass-subtle px-3 text-xs font-bold text-foreground transition-colors hover:bg-accent"
            >
                <Building2 className="h-3.5 w-3.5 shrink-0 text-brand" />
                <span className="truncate">{current?.name ?? '—'}</span>
                <ChevronDown className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
            </button>
            {open && (
                <div className="glass-strong absolute top-full right-0 z-50 mt-2 max-h-80 w-64 overflow-y-auto rounded-2xl p-1">
                    {centers.map((c) => (
                        <button
                            key={c.id}
                            type="button"
                            onClick={() => pick(c)}
                            className={`flex w-full cursor-pointer items-center gap-2 rounded-lg px-3 py-2 text-left text-xs transition-colors ${
                                c.id === current?.id ? 'bg-indigo-500/12 text-primary' : 'text-foreground hover:bg-accent'
                            }`}
                        >
                            {c.logo_url ? (
                                <img src={c.logo_url} alt="" className="h-6 w-6 shrink-0 rounded-md object-cover" />
                            ) : (
                                <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-md bg-muted">
                                    <Building2 className="h-3.5 w-3.5 text-muted-foreground" />
                                </span>
                            )}
                            <span className="min-w-0 flex-1">
                                <span className="block truncate font-bold">{c.name}</span>
                                <span className="block font-mono text-[10px] text-muted-foreground">
                                    {c.code}
                                    {c.suspended ? ' · suspended' : ''}
                                </span>
                            </span>
                            {c.id === current?.id && <Check className="h-3.5 w-3.5 shrink-0" />}
                        </button>
                    ))}
                </div>
            )}
        </div>
    );
}
