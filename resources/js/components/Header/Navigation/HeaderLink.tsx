import React, { useEffect, useState } from "react";
import { HeaderItem } from "@/types/menu";
import { Link } from "@inertiajs/react";
import { usePage } from "@inertiajs/react";
import { useTranslation } from "react-i18next";

const HeaderLink: React.FC<{ item: HeaderItem }> = ({ item }) => {
    const { t } = useTranslation();
    const { url } = usePage();
    const currentUrl = new URL(url, window.location.origin);

    const [currentHash, setCurrentHash] = useState(
        window.location.hash || ""
    );

    useEffect(() => {
        const onHashChange = () => {
            setCurrentHash(window.location.hash || "");
        };
        window.addEventListener("hashchange", onHashChange);
        return () => window.removeEventListener("hashchange", onHashChange);
    }, []);

    const path = currentUrl.pathname;
    const isHashLink = item.href?.startsWith("#");

    const isActive =
        (!isHashLink && path === item.href) ||
        (isHashLink &&
            ((item.href === "#" && (currentHash === "" || currentHash === "#")) ||
                currentHash === item.href));

    const baseClasses =
        "text-lg flex items-center gap-1 transition-colors duration-200 relative";
    const activeClasses =
        "text-foreground font-semibold after:absolute after:w-8 after:h-1 after:bg-primary after:rounded-full after:-bottom-1";
    const inactiveClasses =
        "text-muted-foreground hover:text-foreground";

    return (
        <div className="relative group">
            {isHashLink || item.external ? (
                <a
                    href={item.href}
                    className={`${baseClasses} ${
                        isActive ? activeClasses : inactiveClasses
                    }`}
                >
                    {t(item.label)}
                </a>
            ) : (
                <Link
                    href={item.href || "#"}
                    className={`${baseClasses} ${
                        isActive ? activeClasses : inactiveClasses
                    }`}
                >
                    {t(item.label)}
                </Link>
            )}
        </div>
    );
};

export default HeaderLink;
