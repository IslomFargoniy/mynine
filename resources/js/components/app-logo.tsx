import { type Auth } from '@/types';
import { usePage } from '@inertiajs/react';

/**
 * Sidebar / header logo. Staff of a partner center see their center's logo and name (name only when no
 * logo is uploaded) with a small "Powered by Mynine"; the SuperAdmin, the Mynine center and everyone
 * else see the Mynine logo.
 */
export default function AppLogo() {
    const { auth } = usePage().props as unknown as { auth?: Auth };
    const center = auth?.center;
    const branded = !!center && !center.is_mynine && !auth?.access?.superAdmin;

    if (branded && center) {
        return (
            <span className="flex min-w-0 items-center gap-2.5" data-testid="center-logo">
                {center.logo_url ? (
                    <img
                        src={center.logo_url}
                        alt=""
                        aria-hidden="true"
                        width={36}
                        height={36}
                        className="size-9 shrink-0 rounded-xl bg-white object-contain shadow-sm ring-1 ring-black/5"
                    />
                ) : (
                    <span
                        aria-hidden="true"
                        className="hidden size-9 shrink-0 items-center justify-center rounded-xl bg-primary text-base font-extrabold text-primary-foreground shadow-sm group-data-[collapsible=icon]:flex"
                    >
                        {center.name.trim().charAt(0).toUpperCase()}
                    </span>
                )}
                <span className="flex min-w-0 flex-col leading-tight group-data-[collapsible=icon]:hidden">
                    <span className="truncate text-base font-extrabold tracking-tight text-foreground">{center.name}</span>
                    <span className="truncate text-[10px] font-medium text-muted-foreground">Powered by Mynine</span>
                </span>
            </span>
        );
    }

    const domain = typeof window !== 'undefined' ? window.location.hostname : 'mynine.uz';

    // domenni capitalize qilish (faqat birinchi harflar katta)
    const capitalizeDomain = domain.toLowerCase().replace(/\b\w/g, (char) => char.toUpperCase());

    return (
        <span className="flex items-center gap-2.5">
            <img
                src="/images/icons/mynine-icon.png"
                alt=""
                aria-hidden="true"
                width={36}
                height={36}
                className="size-9 shrink-0 rounded-xl bg-white object-contain shadow-sm ring-1 ring-black/5"
            />
            <span className="truncate text-lg font-extrabold tracking-tight text-foreground group-data-[collapsible=icon]:hidden">
                {capitalizeDomain}
            </span>
        </span>
    );
}
