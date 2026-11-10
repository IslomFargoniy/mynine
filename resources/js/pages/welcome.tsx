import { AppBottomNav } from '@/components/app-bottom-nav';
import Footer from '@/components/Footer';
import Header from '@/components/Header';
import Courses from '@/components/Home/Courses';
import Hero from '@/components/Home/Hero';
import { User } from '@/types';
import { Head, Link, router, usePage } from '@inertiajs/react';
import { useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Icon } from '@iconify/react';

export default function Welcome() {
    const { auth } = usePage<{
        auth: User;
    }>().props;

    const { t } = useTranslation(); // Using the translation hook

    useEffect(() => {
        const tg = window.Telegram?.WebApp?.initData ? window.Telegram.WebApp : undefined;
        tg?.ready();
        tg?.expand();

        const user = tg?.initDataUnsafe?.user;

        // ✅ Prevent multiple login attempts if user already logged in
        if (!auth?.user && user) {
            fetch('/webapp-login', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '',
                },
                body: JSON.stringify({
                    initData: tg?.initData,
                    ...user
                }),
            })
                .then((res) => res.json())
                .then((data) => {
                    if (data.success && data.redirect) {
                        router.visit(data.redirect);
                    }
                })
                .catch((err) => console.error('Telegram WebApp login error:', err));
        }
    }, [auth?.user]);

    return (
        <>
            <Head title={t('seo.welcome_title')}>
                <link rel="preconnect" href="https://fonts.bunny.net" />
                <link href="https://fonts.bunny.net/css?family=instrument-sans:400,500,600" rel="stylesheet" />
            </Head>
            <div>
                {/*<header className="mb-6 w-full max-w-[335px] text-sm not-has-[nav]:hidden lg:max-w-4xl">*/}
                {/*    <nav className="flex items-center justify-end gap-4">*/}
                {/*        {auth.user ? (*/}
                {/*            <Link*/}
                {/*                href={route('dashboard')}*/}
                {/*                className="inline-block rounded-sm border border-[#19140035] px-5 py-1.5 text-sm leading-normal text-[#1b1b18] hover:border-[#1915014a] dark:border-[#3E3E3A] dark:text-[#EDEDEC] dark:hover:border-[#62605b]"*/}
                {/*            >*/}
                {/*                Dashboard*/}
                {/*            </Link>*/}
                {/*        ) : (*/}
                {/*            <>*/}
                {/*                <Link*/}
                {/*                    href={route('login')}*/}
                {/*                    className="inline-block rounded-sm border border-transparent px-5 py-1.5 text-sm leading-normal text-[#1b1b18] hover:border-[#19140035] dark:text-[#EDEDEC] dark:hover:border-[#3E3E3A]"*/}
                {/*                >*/}
                {/*                    Log in*/}
                {/*                </Link>*/}
                {/*                <Link*/}
                {/*                    href={route('register')}*/}
                {/*                    className="inline-block rounded-sm border border-[#19140035] px-5 py-1.5 text-sm leading-normal text-[#1b1b18] hover:border-[#1915014a] dark:border-[#3E3E3A] dark:text-[#EDEDEC] dark:hover:border-[#62605b]"*/}
                {/*                >*/}
                {/*                    Register*/}
                {/*                </Link>*/}
                {/*            </>*/}
                {/*        )}*/}
                {/*    </nav>*/}
                {/*</header>*/}

                <div>
                    <Header />
                    <div>
                        <Hero />

                        <div className={'container mx-auto mb-20 px-6'} id="tests">
                            {/* Heading */}
                            <div className="mt-20 mb-8 items-end justify-between flex flex-wrap gap-6">
                                <div className="space-y-2">
                                    <h2 className="text-4xl md:text-5xl font-extrabold text-gray-900 dark:text-white tracking-tight">
                                        {t('landing.popular_tests')} <span className="text-primary">{t('landing.tests_accent')}</span>
                                    </h2>
                                    <p className="text-gray-500 dark:text-gray-400 font-medium">{t('landing.explore_desc')}</p>
                                </div>
                                <Link
                                    href={route('all-test.index')}
                                    className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-gray-50 dark:bg-white/5 border border-gray-100 dark:border-white/10 text-primary font-bold hover:bg-primary hover:text-white transition-all duration-300"
                                >
                                    {t('landing.explore_all')}
                                    <Icon icon="solar:round-alt-arrow-right-bold" className="size-5" />
                                </Link>
                            </div>

                            <Courses />
                        </div>
                    </div>
                </div>

                <Footer />

                <AppBottomNav />
            </div>
        </>
    );
}
