import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';

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

export default i18n;
