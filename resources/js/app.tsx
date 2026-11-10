import '../css/app.css';
import './i18n';
import "react-datepicker/dist/react-datepicker.css";
import 'react-time-picker/dist/TimePicker.css';
import 'flowbite';



import { createInertiaApp } from '@inertiajs/react';
import { resolvePageComponent } from 'laravel-vite-plugin/inertia-helpers';
import { createRoot } from 'react-dom/client';
import { initializeTheme } from './hooks/use-appearance';
import { Toaster } from 'sonner';
import { initTelegramWebApp } from './hooks/use-telegram';
import { TelegramThemeProvider } from './components/telegram-theme-provider';
import { useIsDark } from './hooks/use-is-dark';

// Sonner defaults to the light theme; follow the <html class="dark"> state instead.
function ThemedToaster() {
    const isDark = useIsDark();

    return <Toaster richColors position="bottom-right" theme={isDark ? 'dark' : 'light'} />;
}

initTelegramWebApp();

const appName = import.meta.env.VITE_APP_NAME || 'Laravel';

createInertiaApp({
    title: (title) => `${title} - ${appName}`,
    resolve: (name) => resolvePageComponent(`./pages/${name}.tsx`, import.meta.glob('./pages/**/*.tsx')),
    setup({ el, App, props }) {
        const root = createRoot(el);

        root.render(
            <TelegramThemeProvider>
                <App {...props} />
                <ThemedToaster />
            </TelegramThemeProvider>
        );
    },
    progress: {
        color: '#4B5563'
    }
});

// This will set light / dark mode on load...
initializeTheme();
