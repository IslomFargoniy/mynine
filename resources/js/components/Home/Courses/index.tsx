import React, { useEffect, useState } from 'react';
import { useKeenSlider } from 'keen-slider/react';
import 'keen-slider/keen-slider.min.css';
import { Icon } from '@iconify/react';
import { useTranslation } from 'react-i18next';
import { Test } from '@/types';
import CreateAttemptModal from '@/components/attempt/create-attempt-modal';

const Courses: React.FC = () => {
    const { t } = useTranslation();
    const [tests, setTests] = useState<Test[]>([]);

    const [sliderRef, instanceRef] = useKeenSlider<HTMLDivElement>({
        loop: true,
        slides: { perView: 3, spacing: 20 },
        breakpoints: {
            '(max-width: 1200px)': { slides: { perView: 2, spacing: 15 } },
            '(max-width: 600px)': { slides: { perView: 1, spacing: 10 } },
        },
    });

    useEffect(() => {
        fetch(route('landing-page-tests'))
            .then(res => res.json())
            .then(res => setTests(res.data ?? res))
            .catch(err => console.error('getTest error:', err));
    }, []);

    const { i18n } = useTranslation();

    useEffect(() => {
        setTimeout(() => {
            instanceRef.current?.update();
        }, 300); // Give minor delay for DOM to settle after translation
    }, [i18n.language, tests, instanceRef]);

    const renderStars = (rating: number) => {
        const fullStars = Math.floor(rating);
        const halfStars = rating % 1 >= 0.5 ? 1 : 0;
        const emptyStars = 5 - fullStars - halfStars;

        return (
            <>
                {Array.from({ length: fullStars }, (_, i) => (
                    <Icon key={`full-${i}`} icon="tabler:star-filled" className="text-amber-500 text-xl inline-block" />
                ))}
                {halfStars > 0 && (
                    <Icon key="half" icon="tabler:star-half-filled" className="text-amber-500 text-xl inline-block" />
                )}
                {Array.from({ length: emptyStars }, (_, i) => (
                    <Icon key={`empty-${i}`} icon="tabler:star-filled" className="text-muted-foreground text-xl inline-block" />
                ))}
            </>
        );
    };

    // fallback for 1-2 tests
    if (tests.length <= 2) {
        return (
            <div className="flex justify-center gap-6 flex-wrap">
                {tests.map(items => (
                    <div key={items.id} className="w-full sm:w-1/2 lg:w-1/3">
                        <div className="glass m-3 px-3 pt-3 rounded-[28px] h-full">
                            <div className="relative rounded-[22px]">
                                <img
                                    src={`/images/courses/coursethree.png`}
                                    alt={t('home.course_image')}
                                    className="m-auto clipPath"
                                    width={389}
                                    height={262}
                                />
                                <div className="absolute right-5 -bottom-2 rounded-full">
                                    <CreateAttemptModal test={items} />
                                </div>
                            </div>
                            <div className="px-3 pt-6">
                                <h3 className="text-2xl font-bold text-foreground max-w-[75%] inline-block">
                                    {items.folder?.name ? `${items.folder.name} : ` : ''}{items.name}
                                </h3>


                                <div
                                    className="flex justify-between items-center py-6 border-b border-divider">
                                    <div className="flex items-center gap-4">{renderStars(5)}</div>
                                    <h3 className="text-3xl font-medium text-foreground ">{t('home.free')}</h3>
                                </div>

                                <div className="flex justify-between pt-6">
                                    <div className="flex gap-2 items-center">
                                        <Icon icon="solar:notebook-minimalistic-outline"
                                              className="text-brand text-xl" />
                                        <h3 className="text-base font-medium text-muted-foreground ">{t('home.steps', { count: items.types.length })}</h3>
                                    </div>
                                    <div className="flex gap-2 items-center">
                                        <Icon icon="solar:users-group-rounded-linear"
                                              className="text-brand text-xl" />
                                        <h3 className="text-base font-medium text-muted-foreground ">{t('home.students', { count: items.attempts_count })}</h3>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                ))}
            </div>
        );
    }

    return (
        <div ref={sliderRef} className="keen-slider py-8">
            {tests.map(items => (
                <div key={items.id} className="keen-slider__slide px-2">
                    <div
                        className="group relative glass p-4 rounded-[28px] transition-transform duration-500 hover:-translate-y-2 h-full flex flex-col">
                        
                        {/* Image Section */}
                        <div className="relative rounded-[22px] overflow-hidden aspect-[4/3] bg-muted">
                            <img
                                src="/images/courses/coursethree.png"
                                alt={items.name}
                                className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                            />
                            <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
                            <div className="absolute right-4 bottom-4 transition-transform duration-500 group-hover:translate-x-1 scale-110">
                                <CreateAttemptModal test={items} />
                            </div>
                        </div>

                        {/* Content Section */}
                        <div className="px-2 pt-6 flex-1 flex flex-col">
                            <h3 className="text-xl font-bold text-foreground line-clamp-2 leading-snug group-hover:text-brand transition-colors duration-300">
                                {items.folder?.name ? `${items.folder.name} : ` : ''}{items.name}
                            </h3>

                            <div className="flex justify-between items-center py-5 mt-auto border-b border-divider">
                                <div className="flex items-center gap-1">
                                    {renderStars(5)}
                                </div>
                                <span className="px-3 py-1 bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200 text-sm font-bold rounded-full uppercase tracking-wider">
                                    {t('landing.free')}
                                </span>
                            </div>

                            <div className="flex justify-between items-center pt-5">
                                <div className="flex gap-2 items-center text-muted-foreground ">
                                    <Icon icon="solar:notebook-minimalistic-bold-duotone" className="text-brand text-xl" />
                                    <span className="text-xs font-bold uppercase tracking-wide">{items.types.length} {t('landing.parts')}</span>
                                </div>
                                <div className="flex gap-2 items-center text-muted-foreground ">
                                    <Icon icon="solar:users-group-rounded-bold-duotone" className="text-brand text-xl" />
                                    <span className="text-xs font-bold uppercase tracking-wide">{items.attempts_count} {t('landing.users')}</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            ))}
        </div>
    );
};

export default Courses;
