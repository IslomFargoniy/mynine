import { Head } from '@inertiajs/react';
import AuthLayout from '@/layouts/auth-layout';
import { useTranslation } from 'react-i18next';
import RegisterCard from '@/components/auth/register-card';
export default function Register() {

    const { t } = useTranslation();


    return (
        <AuthLayout title={t('register.title')} description={t('register.description')}>
            <Head title={t('register.title')} />

            <RegisterCard />

        </AuthLayout>
    );
}
