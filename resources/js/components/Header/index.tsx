import LoginCard from '@/components/auth/login-card';
import RegisterCard from '@/components/auth/register-card';
import LanguageBar from '@/components/language';
import AppearanceToggleDropdown from '@/components/appearance-dropdown';
import FindMockModal from '@/components/mock/find-mock-modal';
import type { SharedData } from '@/types';
import { Icon } from '@iconify/react';
import { Link, usePage } from '@inertiajs/react';
import React, { useEffect, useRef, useState } from 'react';
import HeaderLink from '../Header/Navigation/HeaderLink';
import { headerData } from '../Header/Navigation/menuData';
import MobileHeaderLink from '../Header/Navigation/MobileHeaderLink';
import Logo from './Logo';
import { useTranslation } from 'react-i18next';

const Header: React.FC = () => {
    const { t } = useTranslation();
    const [navbarOpen, setNavbarOpen] = useState(false);
    const [sticky, setSticky] = useState(false);
    const [isSignInOpen, setIsSignInOpen] = useState(false);
    const [isSignUpOpen, setIsSignUpOpen] = useState(false);

    const signInRef = useRef<HTMLDivElement>(null);
    const signUpRef = useRef<HTMLDivElement>(null);
    const mobileMenuRef = useRef<HTMLDivElement>(null);

    const { auth } = usePage<SharedData>().props;

    const handleScroll = () => {
        setSticky(window.scrollY >= 80);
    };

    const handleClickOutside = (event: MouseEvent) => {
        if (signInRef.current && !signInRef.current.contains(event.target as Node)) {
            setIsSignInOpen(false);
        }
        if (signUpRef.current && !signUpRef.current.contains(event.target as Node)) {
            setIsSignUpOpen(false);
        }
        if (mobileMenuRef.current && !mobileMenuRef.current.contains(event.target as Node) && navbarOpen) {
            setNavbarOpen(false);
        }
    };

    useEffect(() => {
        window.addEventListener('scroll', handleScroll);
        document.addEventListener('mousedown', handleClickOutside);
        return () => {
            window.removeEventListener('scroll', handleScroll);
            document.removeEventListener('mousedown', handleClickOutside);
        };
    }, [navbarOpen, isSignInOpen, isSignUpOpen]);

    useEffect(() => {
        document.body.style.overflow = isSignInOpen || isSignUpOpen || navbarOpen ? 'hidden' : '';
    }, [isSignInOpen, isSignUpOpen, navbarOpen]);

    return (
        <header
            className={`fixed top-0 z-40 w-full px-3 transition-all duration-300 ${sticky ? 'pt-2' : 'pt-4'}`}
        >
            <div className="container mx-auto glass-pill px-4 py-2 sm:px-6 md:max-w-screen-md lg:max-w-screen-xl">
                <div className="flex items-center justify-between">
                    <Logo />

                    {/* Desktop Navigation */}
                    <nav className="hidden items-center lg:gap-6 xl:gap-8 lg:flex">
                        <div className="flex items-center lg:gap-6 xl:gap-8">
                            {headerData.map((item) => (
                                <HeaderLink key={item.label} item={item} />
                            ))}
                            <FindMockModal />
                        </div>

                        <div className="flex items-center gap-2">
                            <LanguageBar />
                            <AppearanceToggleDropdown />
                        </div>

                        <div className="flex items-center gap-3">
                            {auth.user ? (
                                <Link
                                    href={route('dashboard')}
                                    className="btn-glass-primary flex items-center gap-2 rounded-full px-6 py-2.5 text-sm font-bold transition-all hover:brightness-110"
                                >
                                    <Icon icon="tabler:layout-dashboard" className="text-lg" />
                                    {t('header.dashboard')}
                                </Link>
                            ) : (
                                <div className="flex items-center gap-4">
                                    <button
                                        className="rounded-full px-6 py-2.5 text-sm font-bold text-foreground transition-colors hover:bg-accent hover:text-brand"
                                        onClick={() => setIsSignInOpen(true)}
                                    >
                                        {t('header.sign_in')}
                                    </button>

                                    <button
                                        className="btn-glass-primary rounded-full px-8 py-2.5 text-sm font-black transition-all hover:brightness-110 active:scale-95"
                                        onClick={() => setIsSignUpOpen(true)}
                                    >
                                        {t('header.sign_up')}
                                    </button>
                                </div>
                            )}
                        </div>
                    </nav>

                    {/* Mobile Controls (Always visible on mobile) */}
                    <div className="flex items-center gap-2 lg:hidden">
                        <LanguageBar />
                        <AppearanceToggleDropdown />
                        <button
                            onClick={() => setNavbarOpen(!navbarOpen)}
                            className="block rounded-full p-2 hover:bg-accent focus:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                            aria-label="Toggle Menu"
                        >
                            <div className="space-y-1.5">
                                <span
                                    className={`block h-0.5 w-6 bg-foreground transition-all ${navbarOpen ? 'translate-y-2 rotate-45' : ''}`}
                                />
                                <span className={`block h-0.5 w-6 bg-foreground transition-all ${navbarOpen ? 'opacity-0' : ''}`} />
                                <span
                                    className={`block h-0.5 w-6 bg-foreground transition-all ${navbarOpen ? '-translate-y-2 -rotate-45' : ''}`}
                                />
                            </div>
                        </button>
                    </div>
                </div>
            </div>

            {/* Modals for Auth */}
            {isSignInOpen && (
                <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 backdrop-blur-sm px-4">
                    <div
                        ref={signInRef}
                        className="relative mx-auto w-full max-w-md"
                    >
                        <button onClick={() => setIsSignInOpen(false)} className="absolute z-10 top-4 right-4 bg-glass-subtle border border-glass-edge rounded-full p-1.5 hover:bg-accent transition-colors">
                            <Icon icon="tabler:x" className="text-xl text-muted-foreground" />
                        </button>
                        <LoginCard />
                    </div>
                </div>
            )}

            {isSignUpOpen && (
                <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 backdrop-blur-sm px-4">
                    <div
                        ref={signUpRef}
                        className="relative mx-auto w-full max-w-md"
                    >
                        <button onClick={() => setIsSignUpOpen(false)} className="absolute z-10 top-4 right-4 bg-glass-subtle border border-glass-edge rounded-full p-1.5 hover:bg-accent transition-colors">
                            <Icon icon="tabler:x" className="text-xl text-muted-foreground" />
                        </button>
                        <RegisterCard />
                    </div>
                </div>
            )}

            {/* Mobile Drawer */}
            {navbarOpen && <div className="fixed inset-0 z-40 bg-black/40 lg:hidden" onClick={() => setNavbarOpen(false)} />}

            <div
                ref={mobileMenuRef}
                className={`fixed top-0 right-0 z-50 h-full w-full max-w-xs transform glass-strong rounded-l-[28px] rounded-r-none transition-transform duration-300 lg:hidden ${navbarOpen ? 'translate-x-0' : 'translate-x-full'}`}
            >
                <div className="flex items-center justify-between p-6">
                    <Logo />
                    <button onClick={() => setNavbarOpen(false)} className="rounded-full p-2 hover:bg-accent">
                        <Icon icon="tabler:x" className="text-2xl text-foreground" />
                    </button>
                </div>

                <nav className="flex flex-col space-y-2 p-6">
                    {headerData.map((item) => (
                        <MobileHeaderLink key={item.label} item={item} />
                    ))}

                    <div className="pt-6">
                        <FindMockModal />
                    </div>

                    <hr className="my-4 border-divider" />

                    {auth.user ? (
                        <Link
                            href={route('dashboard')}
                            className="btn-glass-primary flex items-center justify-center gap-2 rounded-full py-3 font-bold hover:brightness-110"
                        >
                            {t('header.dashboard')}
                        </Link>
                    ) : (
                        <div className="flex flex-col gap-3">
                            <button
                                className="w-full rounded-full border border-glass-edge bg-glass-subtle py-3 font-bold text-foreground hover:bg-accent"
                                onClick={() => {
                                    setIsSignInOpen(true);
                                    setNavbarOpen(false);
                                }}
                            >
                                {t('header.sign_in')}
                            </button>
                            <button
                                className="btn-glass-primary w-full rounded-full py-3 font-bold hover:brightness-110"
                                onClick={() => {
                                    setIsSignUpOpen(true);
                                    setNavbarOpen(false);
                                }}
                            >
                                {t('header.sign_up')}
                            </button>
                        </div>
                    )}
                </nav>
            </div>
        </header>
    );
};

export default Header;
