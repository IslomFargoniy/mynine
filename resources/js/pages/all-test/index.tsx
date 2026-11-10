import AppLayout from '@/layouts/app-layout';
import { Head, usePage, useForm } from '@inertiajs/react';
import { type BreadcrumbItem, type FolderPaginate, SearchData, Folder, User } from '@/types';
import { useEffect, useState, useRef } from 'react';
import { router } from '@inertiajs/react';
import AllTestCard from '@/components/all-test/all-test-card';
import PremiumFilters from '@/components/premium-filters';
import { useTranslation } from 'react-i18next';
import MobileSearchModal from '@/components/MobileSearchModal';

export default function AllTest() {
    const { folder, folders, filters, isAdmin } = usePage<{ 
        folder: FolderPaginate,
        folders: Folder[],
        filters: any,
        isAdmin: boolean
    }>().props;
    const { t } = useTranslation();  // Using the translation hook

    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: t('all_tests'),
            href: '/dashboard'
        }
    ];

    // Form handling for search and per_page
    const { data, setData } = useForm<SearchData>({
        search: filters?.search || '',
        folder_id: filters?.folder_id || '',
        from: filters?.from || '',
        to: filters?.to || '',
        per_page: filters?.per_page || folder.per_page,
        page: folder.current_page,
        total: folder.total
    });

    const [foldersList, setFoldersList] = useState<Folder[]>(folder.data);
    const [loading, setLoading] = useState(false);
    const sentinelRef = useRef<HTMLDivElement | null>(null);

    const hasMore = folder.current_page < folder.last_page;

    useEffect(() => {
        if (folder.current_page === 1) {
            setFoldersList(folder.data);
        } else {
            setFoldersList(prev => {
                const existingIds = new Set(prev.map(f => f.id));
                const newFolders = folder.data.filter(f => !existingIds.has(f.id));
                return [...prev, ...newFolders];
            });
        }
    }, [folder.data, folder.current_page]);

    useEffect(() => {
        if (!hasMore || loading) return;

        const observer = new IntersectionObserver((entries) => {
            if (entries[0].isIntersecting) {
                setLoading(true);
                router.get(route('all-test.index'), {
                    ...data,
                    page: folder.current_page + 1
                }, {
                    preserveState: true,
                    preserveScroll: true,
                    only: ['folder'],
                    onSuccess: () => {
                        setLoading(false);
                    },
                    onError: () => {
                        setLoading(false);
                    }
                });
            }
        }, {
            rootMargin: '100px',
        });

        if (sentinelRef.current) {
            observer.observe(sentinelRef.current);
        }

        return () => observer.disconnect();
    }, [hasMore, loading, folder.current_page, data]);

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        setFoldersList([]);
        router.get(route('all-test.index'), { ...data, page: 1 });
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('all_tests')} />
            <div className="flex h-full flex-1 flex-col gap-4 rounded-xl p-4">
                {/* Search and Per-Page Selection */}
                <div className="flex justify-end items-center mb-2">
                    <MobileSearchModal
                        data={data}
                        setData={setData}
                        handleSubmit={handleSubmit}
                        folders={folders}
                        isAdmin={isAdmin}
                    />
                    <div className="hidden lg:block w-full">
                        <PremiumFilters 
                            handleSubmit={handleSubmit} 
                            setData={setData} 
                            data={data} 
                            folders={folders}
                            isAdmin={isAdmin}
                        />
                    </div>
                </div>

                {/* Table */}
                <div className="overflow-x-auto">
                    <AllTestCard 
                        {...folder} 
                        data={foldersList} 
                        searchData={data} 
                        hidePagination={true} 
                    />
                </div>

                {/* Scroll Sentinel */}
                <div ref={sentinelRef} className="h-10 flex justify-center items-center">
                    {loading && (
                        <div className="flex items-center gap-2 text-sm text-gray-500 py-4">
                            <span className="animate-spin inline-block w-5 h-5 border-2 border-t-transparent border-blue-600 rounded-full"></span>
                            <span>{t('loading')}</span>
                        </div>
                    )}
                </div>
            </div>
        </AppLayout>
    );
}
