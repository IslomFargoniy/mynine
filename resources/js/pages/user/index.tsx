import AppLayout from '@/layouts/app-layout';
import { Head, usePage, useForm } from '@inertiajs/react';
import { type BreadcrumbItem, type UserPaginate, SearchData, Role, User as UserType } from '@/types';

import { router } from '@inertiajs/react';
import UserTable from '@/components/user/user-table';
import PremiumFilters from '@/components/premium-filters';
import { useTranslation } from 'react-i18next';
import MobileSearchModal from '@/components/MobileSearchModal';

export default function User() {
    const { user, roles, teachers, filters, isAdmin } = usePage<{
        user: UserPaginate,
        roles: Role[],
        teachers?: UserType[],
        filters: any,
        isAdmin: boolean
    }>().props;
    const { t } = useTranslation();  // Using the translation hook

    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: t('user'),
            href: '/dashboard'
        }
    ];

    // Form handling for search and per_page
    const { data, setData } = useForm<SearchData>({
        search: filters?.search || '',
        role: filters?.role || '',
        teacher_id: filters?.teacher_id || '',
        from: filters?.from || '',
        to: filters?.to || '',
        per_page: filters?.per_page || user.per_page,
        page: user.current_page,
        total: user.total
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        router.get(route('user.index'), data);
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title="User" />
            <div className="flex h-full flex-1 flex-col gap-4 rounded-xl p-4">
                {/* Search and Per-Page Selection */}
                <div className="flex justify-end items-center mb-2">
                    <MobileSearchModal
                        data={data}
                        setData={setData}
                        handleSubmit={handleSubmit}
                        roles={roles}
                        teachers={teachers}
                        isAdmin={isAdmin}
                    />
                    <div className="hidden lg:block w-full">
                        <PremiumFilters 
                            handleSubmit={handleSubmit} 
                            setData={setData} 
                            data={data} 
                            roles={roles}
                            teachers={teachers}
                            isAdmin={isAdmin}
                        />
                    </div>
                </div>

                {/* Table */}
                <div className="overflow-x-auto">

                    <UserTable
                        {...user}
                        roles={roles}
                        searchData={data} />

                </div>
            </div>
        </AppLayout>
    );
}
