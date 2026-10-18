import AppLayout from '@/layouts/app-layout';
import { Head, usePage, useForm } from '@inertiajs/react';
import { type BreadcrumbItem, SearchData, Folder } from '@/types';
import { useEffect } from 'react';
import { router } from '@inertiajs/react';
import TestTable from '@/components/test/test-table';
import PremiumFilters from '@/components/premium-filters';
import { useTranslation } from 'react-i18next';
import MobileSearchModal from '@/components/MobileSearchModal';

export default function Test() {
    const { folder } = usePage<{ folder: Folder }>().props;
    const { t } = useTranslation();  // Using the translation hook

    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: t('test'),
            href: '/dashboard'
        }
    ];

    // Form handling for search and per_page
    const { data, setData } = useForm<SearchData>({
        search: ''
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        router.get(route('folder.show', folder.id), data);
    };


    useEffect(() => {
        const urlParams = new URLSearchParams(location.search);
        const searchQuery = urlParams.get('search') || ''; // Get 'search' query from the URL
        setData('search', searchQuery); // Set it to the form state
    }, [location.search]);

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title="Test" />
            <div className="flex h-full flex-1 flex-col gap-4 rounded-xl p-4">
                {/* Search and Per-Page Selection */}
                <div className="flex justify-end items-center mb-2">
                    <MobileSearchModal
                        data={data}
                        setData={setData}
                        handleSubmit={handleSubmit}
                    />
                    <div className="hidden lg:block w-full">
                        <PremiumFilters handleSubmit={handleSubmit} setData={setData} data={data} />
                    </div>
                </div>

                {/* Table */}
                <div className="overflow-x-auto">

                    <TestTable {...folder} />

                </div>
            </div>
        </AppLayout>
    );
}
