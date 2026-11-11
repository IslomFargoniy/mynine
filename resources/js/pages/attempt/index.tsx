
import AppLayout from '@/layouts/app-layout';
import { Head, usePage, useForm } from '@inertiajs/react';
import { type BreadcrumbItem, type AttemptPaginate, SearchData, User, Mock, Test, Folder, Attempt as AttemptType } from '@/types';
import { useEffect, useState, useRef } from 'react';
import { router } from '@inertiajs/react';
import AttemptTable from '@/components/attempt/attempt-table';
import PremiumFilters from '@/components/premium-filters';
import { useTranslation } from 'react-i18next';
import MobileSearchModal from '@/components/MobileSearchModal';

export default function Attempt() {
    const { attempt, users, mocks, tests, folders, filters, isAdmin } = usePage<{ 
        attempt: AttemptPaginate,
        users: User[],
        mocks: Mock[],
        tests: Test[],
        folders?: Folder[],
        filters: any,
        isAdmin: boolean
    }>().props;
    const { t } = useTranslation();  // Using the translation hook

    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: t('attempt'),
            href: '/dashboard'
        }
    ];

    // Form handling for search and per_page
    const { data, setData } = useForm<SearchData>({
        search: filters?.search || '',
        user_id: filters?.user_id || '',
        mock_id: filters?.mock_id || '',
        test_id: filters?.test_id || '',
        folder_id: filters?.folder_id || '',
        from: filters?.from || '',
        to: filters?.to || '',
        per_page: filters?.per_page || attempt.per_page,
        page: attempt.current_page,
        total: attempt.total
    });

    const [attemptsList, setAttemptsList] = useState<AttemptType[]>(attempt.data);
    const [loading, setLoading] = useState(false);
    const sentinelRef = useRef<HTMLDivElement | null>(null);

    const hasMore = attempt.current_page < attempt.last_page;

    useEffect(() => {
        if (attempt.current_page === 1) {
            setAttemptsList(attempt.data);
        } else {
            setAttemptsList(prev => {
                const existingIds = new Set(prev.map(a => a.id));
                const newAttempts = attempt.data.filter(a => !existingIds.has(a.id));
                return [...prev, ...newAttempts];
            });
        }
    }, [attempt.data, attempt.current_page]);

    useEffect(() => {
        if (!hasMore || loading) return;

        const observer = new IntersectionObserver((entries) => {
            if (entries[0].isIntersecting) {
                setLoading(true);
                router.get(route('attempt.index'), {
                    ...data,
                    page: attempt.current_page + 1
                }, {
                    preserveState: true,
                    preserveScroll: true,
                    only: ['attempt'],
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
    }, [hasMore, loading, attempt.current_page, data]);

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        setAttemptsList([]);
        router.get(route('attempt.index'), { ...data, page: 1 });
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('page_titles.attempts')} />
            <div className="flex h-full flex-1 flex-col gap-4 rounded-xl p-4">
                {/* Search and Per-Page Selection */}
                <div className="flex justify-end items-center mb-2">
                    <MobileSearchModal
                        data={data}
                        setData={setData}
                        handleSubmit={handleSubmit}
                        users={users}
                        mocks={mocks}
                        tests={tests}
                        folders={folders}
                        isAdmin={isAdmin}
                    />
                    <div className="hidden lg:block w-full">
                        <PremiumFilters 
                            handleSubmit={handleSubmit} 
                            setData={setData} 
                            data={data} 
                            users={users}
                            mocks={mocks}
                            tests={tests}
                            folders={folders}
                            isAdmin={isAdmin}
                        />
                    </div>
                </div>

                {/* Table */}
                <div className="min-w-0">
                    <AttemptTable 
                        {...attempt} 
                        data={attemptsList} 
                        searchData={data} 
                        hidePagination={true} 
                    />
                </div>

                {/* Scroll Sentinel */}
                <div ref={sentinelRef} className="h-10 flex justify-center items-center">
                    {loading && (
                        <div className="flex items-center gap-2 text-sm text-muted-foreground py-4">
                            <span className="animate-spin inline-block w-5 h-5 border-2 border-t-transparent border-primary rounded-full"></span>
                            <span>{t('loading')}</span>
                        </div>
                    )}
                </div>
            </div>
        </AppLayout>
    );
}
