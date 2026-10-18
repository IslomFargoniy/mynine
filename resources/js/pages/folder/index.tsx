import AppLayout from '@/layouts/app-layout';
import { Head, usePage, useForm } from '@inertiajs/react';
import { type BreadcrumbItem, type FolderPaginate, SearchData, User } from '@/types';

import { router } from '@inertiajs/react';
import FolderTable from '@/components/folder/folder-table';
import PremiumFilters from '@/components/premium-filters';
import { useTranslation } from 'react-i18next';
import MobileSearchModal from '@/components/MobileSearchModal';

export default function Folder() {
    const { folder, users, teachers, filters, isAdmin } = usePage<{ 
        folder: FolderPaginate,
        users: User[],
        teachers?: User[],
        filters: any,
        isAdmin: boolean
    }>().props;
    const { t } = useTranslation();  // Using the translation hook

    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: t('dashboard') || 'Boshqaruv paneli',
            href: route('dashboard')
        },
        {
            title: t('folders') || 'Jildlar',
            href: route('folder.index')
        }
    ];

    // Form handling for search and per_page
    const { data, setData } = useForm<SearchData>({
        search: filters?.search || '',
        teacher_id: filters?.teacher_id || '',
        user_id: filters?.user_id || '',
        from: filters?.from || '',
        to: filters?.to || '',
        per_page: filters?.per_page || folder.per_page,
        page: folder.current_page,
        total: folder.total
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        router.get(route('folder.index'), data);
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title="Folder" />
            <div className="flex h-full flex-1 flex-col gap-4 rounded-xl p-4">
                {/* Search and Per-Page Selection */}
                <div className="flex justify-end items-center mb-2">
                    <MobileSearchModal
                        data={data}
                        setData={setData}
                        handleSubmit={handleSubmit}
                        users={users}
                        teachers={teachers}
                        isAdmin={isAdmin}
                    />
                    <div className="hidden lg:block w-full">
                        <PremiumFilters
                            handleSubmit={handleSubmit}
                            setData={setData}
                            data={data}
                            users={users}
                            teachers={teachers}
                            isAdmin={isAdmin}
                        />
                    </div>
                </div>

                {/* Table */}
                <div className="overflow-x-auto">

                    <FolderTable {...folder} searchData={data} />

                </div>
            </div>
        </AppLayout>
    );
}
