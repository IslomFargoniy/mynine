import React from 'react';
import { useTranslation } from 'react-i18next';

import Logo from '../Header/Logo';
import { Icon } from '@iconify/react';
import { headerData } from '../Header/Navigation/menuData';

const Footer: React.FC = () => {
    const { t } = useTranslation();
    const domain =
        typeof window !== 'undefined' ? window.location.hostname : 'mynine.uz';

    // domenni capitalize qilish (faqat birinchi harflar katta)
    const capitalizeDomain = domain
        .toLowerCase()
        .replace(/\b\w/g, (char) => char.toUpperCase());

    return (
        <footer id="contact" className="pt-10 pb-32 md:pb-10">
            <div className="container mx-auto lg:max-w-screen-xl md:max-w-screen-md px-4">
            <div className="glass rounded-[28px] p-6 sm:p-10">
                <div className="grid grid-cols-1 gap-y-10 gap-x-16 sm:grid-cols-2 lg:grid-cols-12 xl:gap-x-8">

                    {/* Logo & Social Icons */}
                    <div className="col-span-4 md:col-span-12 lg:col-span-4">
                        <Logo />
                        <p className="mt-4 text-muted-foreground text-sm max-w-xs">
                            {capitalizeDomain} — {t('footer.description')}
                        </p>
                        <div className="flex items-center gap-4 mt-4">
                            <a target="_blank" href="https://t.me/IslomFargniy"
                               className="hover:text-brand text-foreground text-3xl">
                                <Icon icon="tabler:brand-facebook" />
                            </a>
                            <a target="_blank" href="https://t.me/IslomFargniy"
                               className="hover:text-brand text-foreground text-3xl">
                                <Icon icon="tabler:brand-telegram" />
                            </a>
                            <a target="_blank" href="https://t.me/IslomFargniy"
                               className="hover:text-brand text-foreground text-3xl">
                                <Icon icon="tabler:brand-instagram" />
                            </a>
                        </div>
                    </div>

                    {/* Quick Links */}
                    <div className="col-span-4">
                        <h3 className="mb-4 text-2xl font-medium text-foreground">{t('footer.quick_links')}</h3>
                        <ul>
                            {headerData.map((item, index) => (
                                <li key={index}
                                    className="mb-2 text-muted-foreground hover:text-brand w-fit">
                                    <a href={item.href}>{t(item.label)}</a>
                                </li>
                            ))}
                        </ul>
                    </div>

                    {/*/!* Resources *!/*/}
                    {/*<div className="col-span-2">*/}
                    {/*    <h3 className="mb-4 text-2xl font-medium text-foreground">Resources</h3>*/}
                    {/*    <ul>*/}
                    {/*        {['About IELTS', 'Practice Tests', 'Band Calculator', 'FAQs', 'Contact Us'].map((label, i) => (*/}
                    {/*            <li key={i} className="mb-2 text-muted-foreground hover:text-brand w-fit">*/}
                    {/*                <Link href="#">{label}</Link>*/}
                    {/*            </li>*/}
                    {/*        ))}*/}
                    {/*    </ul>*/}
                    {/*</div>*/}

                    {/* Contact Info */}
                    <div className="col-span-4 md:col-span-4 lg:col-span-4 space-y-6">
                        <div className="flex items-center gap-2">
                            <Icon icon="tabler:brand-google-maps" className="text-brand text-3xl" />
                            <span className="text-lg text-muted-foreground">
                                {t('footer.address')}
                            </span>
                        </div>
                        <div className="flex items-center gap-2">
                            <Icon icon="tabler:phone" className="text-brand text-3xl" />
                            <a href="tel:+998911157709">
                                <span className="text-lg text-muted-foreground">+998 91 115 77 09</span>
                            </a>
                        </div>
                        <div className="flex items-center gap-2">
                            <Icon icon="tabler:mail" className="text-brand text-3xl" />

                            <a href={'https://t.me/IslomFargniy'} target="_blank">
                                <span className="text-lg text-muted-foreground">{t('footer.support_telegram')}</span>
                            </a>

                        </div>
                    </div>
                </div>

                {/* Footer Bottom */}
                <div className="mt-10 lg:flex items-center justify-between flex-wrap gap-4">
                    <span className="text-muted-foreground text-sm text-center lg:text-start">
                        © 2025 <strong>{capitalizeDomain}</strong>. {t('footer.rights')}
                    </span>
                </div>
            </div>
            </div>
        </footer>
    );
};

export default Footer;
