import React from 'react';


export default function AppLogo() {

    const domain =
        typeof window !== "undefined" ? window.location.hostname : "mynine.uz";

    // domenni capitalize qilish (faqat birinchi harflar katta)
    const capitalizeDomain = domain
        .toLowerCase()
        .replace(/\b\w/g, (char) => char.toUpperCase());

    return (
        <>
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

            {/*<div*/}
            {/*    className="bg-sidebar-primary text-sidebar-primary-foreground flex aspect-square size-8 items-center justify-center rounded-md">*/}
            {/*    /!*<AppLogoIcon className="size-5 fill-current text-white dark:text-black" />*!/*/}
            {/*    <img*/}
            {/*        src="/logo.svg"*/}
            {/*        alt="App Logo"*/}
            {/*        className="size-9 fill-current text-white dark:text-black"*/}
            {/*    />*/}

            {/*</div>*/}

            {/*<div className="ml-1 grid flex-1 text-left text-sm">*/}
            {/*    <span className="mb-0.5 truncate leading-none font-semibold">IELTS</span>*/}
            {/*</div>*/}
        </>
    );
}
