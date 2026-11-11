import { Icon } from "@iconify/react";
import { useTranslation } from "react-i18next";

const Hero = () => {
    const { t } = useTranslation();
    return (
        <section
            id="home-section"
            className="relative overflow-hidden pb-20 pt-32 md:pt-40"
        >

            <div className="container mx-auto lg:max-w-screen-xl md:max-w-screen-md px-6 relative z-10">
                <div className="grid grid-cols-1 lg:grid-cols-12 items-center gap-16">
                    {/* Left Content */}
                    <div className="lg:col-span-7 min-w-0 flex flex-col gap-10 glass rounded-[28px] p-6 sm:p-10">
                        <div className="space-y-6">
                            {/* Discount badge */}
                            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-emerald-500/25 bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200 animate-pulse">
                                <Icon
                                    icon="solar:verified-check-bold"
                                    className="text-xl"
                                />
                                <p className="text-sm font-bold tracking-tight">
                                    {t('landing.hero_badge')}
                                </p>
                            </div>

                            {/* Heading */}
                            <h1 className="text-foreground text-5xl sm:text-7xl font-extrabold leading-[1.1] tracking-tight">
                                {t('landing.hero_title')} <br />
                                <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-600 to-violet-600 dark:from-indigo-300 dark:to-violet-300">
                                    {t('landing.hero_title_accent')}
                                </span>
                            </h1>

                            {/* Subheading */}
                            <h3 className="text-muted-foreground text-xl leading-relaxed max-w-2xl">
                                {t('landing.hero_subtitle')}
                            </h3>
                        </div>

                        {/* CTA / Action */}
                        <div className="flex flex-wrap items-center gap-6">
                            <a href="#tests" className="btn-glass-primary rounded-full px-10 py-5 font-bold text-xl hover:brightness-110 active:scale-95 transition-all duration-300">
                                {t('landing.start_free_test')}
                            </a>
                            <div className="glass-subtle flex items-center gap-5 px-8 py-5 rounded-full hover:bg-accent transition-colors duration-300 group">
                                <img
                                    src="/images/banner/openai.png"
                                    alt={t('home.ai_evaluation_alt')}
                                    width={160}
                                    className="opacity-90 group-hover:scale-105 transition-transform duration-300 rounded-lg"
                                />
                                <div className="h-8 w-px bg-divider mx-2" />
                                <span className="text-sm font-bold text-muted-foreground leading-tight">
                                    {t('landing.ai_evaluation')} <br /> {t('landing.ai_feedback')}
                                </span>
                            </div>
                        </div>

                        {/* Features */}
                        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
                            {[
                                { text: t('landing.feature_real_interface'), icon: "solar:monitor-bold" },
                                { text: t('landing.feature_instant_result'), icon: "solar:graph-bold" },
                                { text: t('landing.feature_ai_writing'), icon: "solar:pen-new-square-bold" }
                            ].map((item, i) => (
                                <div key={i} className="flex gap-3 items-center group">
                                    <div className="p-2 rounded-xl glass-subtle text-brand group-hover:scale-110 transition-transform duration-300">
                                        <Icon icon={item.icon} className="size-6" />
                                    </div>
                                    <p className="text-sm font-bold text-muted-foreground">
                                        {item.text}
                                    </p>
                                </div>
                            ))}
                        </div>
                    </div>

                    {/* Right Image */}
                    <div className="lg:col-span-5 flex justify-center relative">
                        <div className="relative z-10 w-full animate-float">
                            <img
                                src="/images/banner/mahila.png"
                                alt={t('home.success_alt')}
                                width={800}
                                height={800}
                                className="object-contain w-full drop-shadow-[0_20px_50px_rgba(79,70,229,0.25)]"
                            />
                        </div>
                    </div>
                </div>
            </div>
            
            <style>{`
                @keyframes float {
                    0%, 100% { transform: translateY(0px); }
                    50% { transform: translateY(-20px); }
                }
                .animate-float {
                    animation: float 6s ease-in-out infinite;
                }
            `}</style>
        </section>
    );
};

export default Hero;
