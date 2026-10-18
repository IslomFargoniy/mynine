import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Check, Globe } from 'lucide-react';

interface LanguageBarProps {
    variant?: 'light' | 'dark' | 'header';
    placement?: 'bottom' | 'top' | 'left' | 'right';
    className?: string;
}

const LanguageBar = ({ variant, placement, className }: LanguageBarProps) => {
    const { i18n } = useTranslation();
    const [open, setOpen] = useState(false);
    const dropdownRef = useRef<HTMLDivElement>(null);

    const currentLang = i18n.language || 'uz';

    const changeLanguage = (lang: string) => {
        i18n.changeLanguage(lang);
        localStorage.setItem('lang', lang);
        setOpen(false);
    };

    // Close dropdown on outside click
    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
                setOpen(false);
            }
        };
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    const languages = [
        { code: 'uz', flag: '🇺🇿', label: 'O\'zbek' },
        { code: 'en', flag: '🇬🇧', label: 'English' },
        { code: 'ru', flag: '🇷🇺', label: 'Русский' },
    ];

    const currentLangObj = languages.find(l => l.code === currentLang) || languages[0];

    const defaultButtonClass = variant === 'dark'
        ? "inline-flex items-center gap-1.5 rounded-lg border border-white/20 bg-white/10 px-3 py-1.5 text-xs font-semibold text-white backdrop-blur-sm hover:bg-white/20 transition-all cursor-pointer shadow-xs"
        : variant === 'header'
        ? "inline-flex items-center gap-1.5 rounded-[2px] border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-2.5 py-1 text-xs font-bold text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors cursor-pointer shrink-0"
        : "inline-flex items-center gap-1.5 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 px-3 py-1.5 text-xs font-semibold text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-700 transition-all cursor-pointer shadow-xs";

    return (
        <div className={`relative inline-block text-left ${className || ''}`} ref={dropdownRef}>
            <button
                type="button"
                onClick={() => setOpen(!open)}
                className={defaultButtonClass}
            >
                <Globe className="w-3.5 h-3.5 text-gray-500 dark:text-gray-400" />
                <span>{currentLangObj.flag} {currentLangObj.code.toUpperCase()}</span>
            </button>

            {open && (
                <div className={`absolute ${placement === 'top' ? 'bottom-full mb-2' : 'top-full mt-2'} right-0 z-50 w-36 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-1 shadow-lg`}>
                    {languages.map((lang) => (
                        <button
                            key={lang.code}
                            type="button"
                            onClick={() => changeLanguage(lang.code)}
                            className={`flex w-full items-center justify-between px-3 py-2 text-xs font-semibold rounded-lg transition-colors cursor-pointer ${
                                currentLang === lang.code
                                    ? 'bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400'
                                    : 'text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700'
                            }`}
                        >
                            <span className="flex items-center gap-2">
                                <span>{lang.flag}</span>
                                <span>{lang.label}</span>
                            </span>
                            {currentLang === lang.code && (
                                <Check className="w-3.5 h-3.5 text-blue-600 dark:text-blue-400" />
                            )}
                        </button>
                    ))}
                </div>
            )}
        </div>
    );
};

export default LanguageBar;
