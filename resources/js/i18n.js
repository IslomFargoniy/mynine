import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';
import { router } from '@inertiajs/react';

import en from '../lang/en.json';
import uz from '../lang/uz.json';
import ru from '../lang/ru.json';

i18n
    .use(LanguageDetector)
    .use(initReactI18next)
    .init({
        resources: {
            en: { translation: en },
            uz: { translation: uz },
            ru: { translation: ru }
        },
        // Only the three languages we ship; "en-US" / "ru-RU" from the browser map to "en" / "ru".
        // Default for new visitors is Uzbek (the center's audience).
        supportedLngs: ['uz', 'en', 'ru'],
        nonExplicitSupportedLngs: true,
        load: 'languageOnly',
        fallbackLng: 'uz',
        detection: {
            // The switcher stores the choice under "lang"; read that first so it survives reloads.
            order: ['localStorage', 'navigator'],
            lookupLocalStorage: 'lang',
            caches: ['localStorage'],
        },
        interpolation: {
            escapeValue: false
        }
    });

/** The chosen language as one of uz/en/ru. */
export const currentLocale = () => (i18n.resolvedLanguage || i18n.language || 'uz').split('-')[0];

/**
 * Keep server-rendered text (flash / validation messages, PDFs, Blade pages) in the same language:
 * every Inertia request carries X-Locale (read by the SetLocale middleware), and a change of language,
 * or a page that the server rendered in another language, is stored in the session via GET /lang/{locale}.
 */
const syncServerLocale = (lang) => {
    if (typeof window === 'undefined') return;
    document.documentElement.lang = lang;
    fetch(`/lang/${lang}`, { headers: { Accept: 'application/json', 'X-Requested-With': 'XMLHttpRequest' }, credentials: 'same-origin' }).catch(() => {});
};

if (typeof window !== 'undefined') {
    router.on('before', (event) => {
        event.detail.visit.headers = { ...event.detail.visit.headers, 'X-Locale': currentLocale() };
    });

    i18n.on('languageChanged', () => syncServerLocale(currentLocale()));

    const serverLang = (document.documentElement.lang || '').split('-')[0];
    if (serverLang && serverLang !== currentLocale()) syncServerLocale(currentLocale());
}

export default i18n;
