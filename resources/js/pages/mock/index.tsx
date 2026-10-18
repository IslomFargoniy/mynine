import AppLayout from '@/layouts/app-layout';
import { Head, usePage, useForm } from '@inertiajs/react';
import { type BreadcrumbItem, type MockPaginate, SearchData, Test, User, Folder } from '@/types';

import { router } from '@inertiajs/react';
import MockTable from '@/components/mock/mock-table';
import PremiumFilters from '@/components/premium-filters';
import { useTranslation } from 'react-i18next';
import MobileSearchModal from '@/components/MobileSearchModal';

export default function Mock() {
    const { mock, tests, users, teachers, folders, filters, isAdmin } = usePage<{
        mock: MockPaginate,
        tests: Test[],
        users: User[],
        teachers?: User[],
        folders?: Folder[],
        filters: any,
        isAdmin: boolean
    }>().props;
    const { t } = useTranslation();  // Using the translation hook

    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: t('mock'),
            href: '/dashboard'
        }
    ];

    // Form handling for search and per_page
    const { data, setData } = useForm<SearchData>({
        search: filters?.search || '',
        teacher_id: filters?.teacher_id || '',
        user_id: filters?.user_id || '',
        test_id: filters?.test_id || '',
        folder_id: filters?.folder_id || '',
        from: filters?.from || '',
        to: filters?.to || '',
        per_page: filters?.per_page || mock.per_page,
        page: mock.current_page,
        total: mock.total
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        router.get(route('mock.index'), data);
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title="Mock" />
            <div className="flex h-full flex-1 flex-col gap-4 rounded-xl p-4">
                {/* Search and Per-Page Selection */}
                <div className="flex justify-end items-center mb-2">
                    <MobileSearchModal
                        data={data}
                        setData={setData}
                        handleSubmit={handleSubmit}
                        users={users}
                        teachers={teachers}
                        tests={tests}
                        folders={folders}
                        isAdmin={isAdmin}
                    />
                    <div className="hidden lg:block w-full">
                        <PremiumFilters
                            data={data}
                            setData={setData}
                            handleSubmit={handleSubmit}
                            isAdmin={isAdmin}
                            users={users}
                            teachers={teachers}
                            tests={tests}
                            folders={folders}
                        />
                    </div>
                </div>

                {/* Table */}
                <div className="overflow-x-auto">

                    <MockTable {...mock}
                               searchData={data}
                               tests={tests}
                    />

                </div>
            </div>
        </AppLayout>
    );
}
