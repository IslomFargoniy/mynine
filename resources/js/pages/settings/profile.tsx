import { type BreadcrumbItem, type SharedData } from '@/types';
import { Transition } from '@headlessui/react';
import { Head, useForm, usePage } from '@inertiajs/react';
import { FormEventHandler } from 'react';
import { useTranslation } from 'react-i18next';

import HeadingSmall from '@/components/heading-small';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import AppLayout from '@/layouts/app-layout';
import SettingsLayout from '@/layouts/settings/layout';

const breadcrumbs: BreadcrumbItem[] = [
    {
        title: 'Profile settings',
        href: '/settings/profile',
    },
];

type ProfileForm = {
    name: string;
    phone: string;
    email: string;
    username: string;
};

export default function Profile() {
    const { auth } = usePage<SharedData>().props;

    const { data, setData, patch, errors, processing, recentlySuccessful } = useForm<Required<ProfileForm>>({
        name: auth.user.name,
        phone: auth.user.phone,
        email: auth.user.email,
        username: auth.user.username,
    });

    const { t } = useTranslation(); // Using the translation hook

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        patch(route('profile.update'), {
            preserveScroll: true,
        });
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('profile_settings.title')} />

            <SettingsLayout>
                <div className="space-y-6">
                    <HeadingSmall title={t('profile_settings.heading')} description={t('profile_settings.description')} />

                    <form onSubmit={submit} className="space-y-6">
                        <div className="grid gap-2">
                            <Label htmlFor="name">{t('profile_settings.name')}</Label>

                            <Input
                                id="name"
                                className="mt-1 block w-full"
                                value={data.name}
                                onChange={(e) => setData('name', e.target.value)}
                                required
                                autoComplete="name"
                                placeholder={t('profile_settings.full_name')}
                            />

                            <InputError className="mt-2" message={errors.name} />
                        </div>
                        <div className="grid gap-2">
                            <Label htmlFor="phone">{t('profile_settings.phone')}</Label>

                            <Input
                                id="phone"
                                className="mt-1 block w-full"
                                value={data.phone}
                                onChange={(e) => setData('phone', e.target.value)}
                                autoComplete="phone"
                                placeholder={t('profile_settings.phone')}
                            />

                            <InputError className="mt-2" message={errors.phone} />
                        </div>
                        <div className="grid gap-2">
                            <Label htmlFor="username">{t('username')}</Label>

                            <Input
                                id="username"
                                className="mt-1 block w-full"
                                value={data.username}
                                onChange={(e) => setData('username', e.target.value)}
                                autoComplete="phone"
                                placeholder={t('username')}
                            />

                            <InputError className="mt-2" message={errors.username} />
                        </div>

                        {/*<div className="grid gap-2">*/}
                        {/*    <Label htmlFor="email">{t('profile_settings.email')}</Label>*/}

                        {/*    <Input*/}
                        {/*        id="email"*/}
                        {/*        type="email"*/}
                        {/*        className="mt-1 block w-full"*/}
                        {/*        value={data.email}*/}
                        {/*        onChange={(e) => setData('email', e.target.value)}*/}

                        {/*        autoComplete="username"*/}
                        {/*        placeholder={t('profile_settings.email_address')}*/}
                        {/*    />*/}

                        {/*    <InputError className="mt-2" message={errors.email} />*/}
                        {/*</div>*/}

                        {/*{mustVerifyEmail && auth.user.email_verified_at === null && (*/}
                        {/*    <div>*/}
                        {/*        <p className="text-muted-foreground -mt-4 text-sm">*/}
                        {/*            {t('profile_settings.unverified_email')}{' '}*/}
                        {/*            <Link*/}
                        {/*                href={route('verification.send')}*/}
                        {/*                method="post"*/}
                        {/*                as="button"*/}
                        {/*                className="text-foreground underline decoration-neutral-300 underline-offset-4 transition-colors duration-300 ease-out hover:decoration-current! dark:decoration-neutral-500"*/}
                        {/*            >*/}
                        {/*                {t('profile_settings.resend_verification_email')}*/}
                        {/*            </Link>*/}
                        {/*        </p>*/}

                        {/*        {status === 'verification-link-sent' && (*/}
                        {/*            <div className="mt-2 text-sm font-medium text-green-600">*/}
                        {/*                {t('profile_settings.verification_link_sent')}*/}
                        {/*            </div>*/}
                        {/*        )}*/}
                        {/*    </div>*/}
                        {/*)}*/}

                        <div className="flex items-center gap-4">
                            <Button disabled={processing}>{t('profile_settings.save')}</Button>

                            <Transition
                                show={recentlySuccessful}
                                enter="transition ease-in-out"
                                enterFrom="opacity-0"
                                leave="transition ease-in-out"
                                leaveTo="opacity-0"
                            >
                                <p className="text-sm text-neutral-600">{t('profile_settings.saved')}</p>
                            </Transition>
                        </div>
                    </form>
                </div>
            </SettingsLayout>
        </AppLayout>
    );
}
