import { useState } from "react";
import { HeaderItem } from "@/types/menu";
import { Link } from '@inertiajs/react';
import { useTranslation } from 'react-i18next';

const MobileHeaderLink: React.FC<{ item: HeaderItem }> = ({ item }) => {
    const [submenuOpen, setSubmenuOpen] = useState(false);
    const { t } = useTranslation();

    const handleToggle = (e: React.MouseEvent) => {
        if (item.submenu) {
            e.preventDefault(); // prevent navigation if submenu exists
            setSubmenuOpen(!submenuOpen);
        }
    };

    return (
        <div className="relative w-full">
            {item.external ? (
                <a
                    href={item.href}
                    className="flex items-center justify-between w-full py-2 text-gray-700 hover:text-black dark:text-gray-300 dark:hover:text-white transition-colors duration-200"
                >
                    {t(item.label)}
                </a>
            ) : (
            <Link
                href={item.href || "#"}
                onClick={handleToggle}
                className="flex items-center justify-between w-full py-2 text-gray-700 hover:text-black dark:text-gray-300 dark:hover:text-white transition-colors duration-200 focus:outline-none"
            >
                {t(item.label)}
                {item.submenu && (
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        width="1.5em"
                        height="1.5em"
                        viewBox="0 0 24 24"
                        className={`ml-2 transition-transform duration-200 ${
                            submenuOpen ? "rotate-180" : ""
                        } text-gray-600 dark:text-gray-300`}
                    >
                        <path
                            fill="none"
                            stroke="currentColor"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth="1.5"
                            d="m7 10l5 5l5-5"
                        />
                    </svg>
                )}
            </Link>
            )}

            {submenuOpen && item.submenu && (
                <div className="bg-white dark:bg-darklight border border-gray-200 dark:border-gray-700 rounded-lg mt-1 p-2 w-full shadow-md">
                    {item.submenu.map((subItem, index) => (
                        <Link
                            key={index}
                            href={subItem.href || "#"}
                            className="block rounded-lg px-4 py-3 text-lg font-bold text-slate-700 hover:bg-slate-50 dark:text-slate-300 dark:hover:bg-slate-800"
                        >
                            {t(subItem.label)}
                        </Link>
                    ))}
                </div>
            )}
        </div>
    );
};

export default MobileHeaderLink;
