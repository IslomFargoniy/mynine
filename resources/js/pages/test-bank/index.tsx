import DeleteItemModal from '@/components/delete-item-modal';
import CreateFolderModal from '@/components/folder/create-folder-modal';
import UpdateFolderModal from '@/components/folder/update-folder-modal';
import MobileSearchModal from '@/components/MobileSearchModal';
import PremiumFilters from '@/components/premium-filters';
import UpdateTestModal from '@/components/test/update-test-modal';
import FolderSection from '@/components/test-bank/folder-section';
import AppLayout from '@/layouts/app-layout';
import { type BreadcrumbItem, type Folder, type FolderPaginate, type SearchData, type Test } from '@/types';
import { Icon } from '@iconify/react';
import { Head, router, useForm, usePage } from '@inertiajs/react';
import { useCallback, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { toast } from 'sonner';

type Filters = { search?: string; folder_id?: string | number; from?: string; to?: string; per_page?: string | number };

/** Keep the order of what is already loaded, refresh changed folders in place, append new ones. */
function mergeFolders(previous: Folder[], incoming: Folder[]): Folder[] {
    const byId = new Map(incoming.map((f) => [f.id, f]));
    const merged = previous.map((f) => byId.get(f.id) ?? f);
    const known = new Set(previous.map((f) => f.id));
    return [...merged, ...incoming.filter((f) => !known.has(f.id))];
}

/**
 * Test Bank: practice tests grouped by folder (infinite scroll over folders).
 * Admins manage folders and tests here too; see AllTestController for what each role receives.
 */
export default function TestBank() {
    const { folder, folders, filters, isAdmin } = usePage<{
        folder: FolderPaginate;
        folders: Folder[];
        filters: Filters;
        isAdmin: boolean;
    }>().props;
    const { t } = useTranslation();

    const breadcrumbs: BreadcrumbItem[] = [{ title: t('test_bank.title'), href: route('test-bank.index') }];

    const basePerPage = filters?.per_page === 'all' ? 100 : Number(filters?.per_page) || 10;

    const { data, setData } = useForm<SearchData>({
        search: filters?.search || '',
        folder_id: filters?.folder_id || '',
        from: filters?.from || '',
        to: filters?.to || '',
        per_page: filters?.per_page || folder.per_page,
        page: folder.current_page,
        total: folder.total,
    });

    const [foldersList, setFoldersList] = useState<Folder[]>(folder.data);
    const [loading, setLoading] = useState(false);
    const [exhausted, setExhausted] = useState(false);
    const sentinelRef = useRef<HTMLDivElement | null>(null);
    // How the next "folder" prop is applied: replace the list (new search / full refresh) or merge into it.
    const nextMode = useRef<'replace' | 'merge'>('replace');

    const listRef = useRef<Folder[]>(folder.data);
    useEffect(() => {
        listRef.current = foldersList;
    }, [foldersList]);

    useEffect(() => {
        const mode = nextMode.current;
        nextMode.current = 'merge';
        if (mode === 'replace') {
            setFoldersList(folder.data);
            setExhausted(false);
            return;
        }
        const previous = listRef.current;
        const next = mergeFolders(previous, folder.data);
        // A later page that brought nothing new: stop loading instead of looping.
        if (next.length === previous.length && folder.current_page > 1) setExhausted(true);
        setFoldersList(next);
    }, [folder]);

    const hasMore = !exhausted && foldersList.length < folder.total;

    // Server-applied filters (not the unsubmitted form state).
    const query = useCallback(
        (extra: Record<string, number>) => ({
            ...(filters?.search ? { search: filters.search } : {}),
            ...(filters?.folder_id ? { folder_id: filters.folder_id } : {}),
            ...(filters?.from && filters?.to ? { from: filters.from, to: filters.to } : {}),
            ...extra,
        }),
        [filters],
    );

    useEffect(() => {
        if (!hasMore || loading) return;

        const observer = new IntersectionObserver(
            (entries) => {
                if (!entries[0].isIntersecting) return;
                setLoading(true);
                router.get(route('test-bank.index'), query({ page: Math.floor(foldersList.length / basePerPage) + 1, per_page: basePerPage }), {
                    preserveState: true,
                    preserveScroll: true,
                    preserveUrl: true,
                    only: ['folder'],
                    onFinish: () => setLoading(false),
                });
            },
            { rootMargin: '100px' },
        );

        if (sentinelRef.current) observer.observe(sentinelRef.current);

        return () => observer.disconnect();
    }, [hasMore, loading, foldersList.length, basePerPage, query]);

    /** After an admin change: reload every folder loaded so far, in one request. */
    const refresh = useCallback(() => {
        nextMode.current = 'replace';
        router.get(route('test-bank.index'), query({ page: 1, per_page: Math.min(100, Math.max(basePerPage, foldersList.length)) }), {
            preserveState: true,
            preserveScroll: true,
            preserveUrl: true,
            only: ['folder'],
        });
    }, [query, basePerPage, foldersList.length]);

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        nextMode.current = 'replace';
        router.get(route('test-bank.index'), { ...data, page: 1 });
    };

    // /folder/{id} redirects to ?folder_id={id}: bring that folder into view.
    const focusedFolderId = Number(filters?.folder_id) || null;
    useEffect(() => {
        if (focusedFolderId) document.getElementById(`folder-${focusedFolderId}`)?.scrollIntoView({ block: 'start' });
    }, [focusedFolderId]);

    // Admin dialogs
    const [editFolder, setEditFolder] = useState<Folder | null>(null);
    const [deleteFolder, setDeleteFolder] = useState<Folder | null>(null);
    const [editTest, setEditTest] = useState<Test | null>(null);
    const [deleteTest, setDeleteTest] = useState<Test | null>(null);

    const onError = (errors: Record<string, string>) => toast.error(errors?.error || Object.values(errors)[0] || t('delete_failed'));

    const handleDeleteFolder = (id: number) =>
        router.delete(route('folder.destroy', id), {
            preserveScroll: true,
            preserveState: true,
            onSuccess: () => {
                setFoldersList((prev) => prev.filter((f) => f.id !== id));
                toast.success(t('deleted_successfully'));
                refresh();
            },
            onError,
        });

    const handleDeleteTest = (id: number) =>
        router.delete(route('test.destroy', id), {
            preserveScroll: true,
            preserveState: true,
            onSuccess: () => {
                toast.success(t('deleted_successfully'));
                refresh();
            },
            onError,
        });

    const handleToggleTest = (test: Test, field: 'active' | 'open') =>
        router.post(
            route('test.update', test.id),
            {
                name: test.name,
                comment: test.comment ?? '',
                active: Number(test.active) === 1 ? 1 : 0,
                open: Number(test.open) === 1 ? 1 : 0,
                [field]: Number(test[field]) === 1 ? 0 : 1,
            },
            {
                preserveScroll: true,
                preserveState: true,
                onSuccess: () => {
                    toast.success(t('updated_successfully'));
                    refresh();
                },
                onError,
            },
        );

    const visibleFolders = isAdmin ? foldersList : foldersList.filter((f) => Array.isArray(f.tests) && f.tests.length > 0);

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('test_bank.title')} />
            <div className="flex h-full flex-1 flex-col gap-4 rounded-xl p-4">
                <div className="mb-2 flex items-center justify-end gap-2">
                    <MobileSearchModal data={data} setData={setData} handleSubmit={handleSubmit} folders={folders} isAdmin={isAdmin} />
                    <div className="hidden w-full lg:block">
                        <PremiumFilters handleSubmit={handleSubmit} setData={setData} data={data} folders={folders} isAdmin={isAdmin} />
                    </div>
                    {isAdmin && <CreateFolderModal onSuccess={refresh} />}
                </div>

                <div className="space-y-12">
                    {visibleFolders.length > 0 ? (
                        visibleFolders.map((item) => (
                            <FolderSection
                                key={item.id}
                                folder={item}
                                isAdmin={isAdmin}
                                highlighted={focusedFolderId === item.id}
                                onChanged={refresh}
                                onEditFolder={setEditFolder}
                                onDeleteFolder={setDeleteFolder}
                                onEditTest={setEditTest}
                                onDeleteTest={setDeleteTest}
                                onToggleTest={handleToggleTest}
                            />
                        ))
                    ) : (
                        <div className="flex flex-col items-center justify-center rounded-[18px] border border-dashed border-glass-dash py-20 text-muted-foreground">
                            <Icon icon="solar:folder-error-linear" className="mb-4 text-6xl text-muted-foreground" />
                            <p className="text-xl font-bold text-muted-foreground">{t('no_tests_found')}</p>
                        </div>
                    )}
                </div>

                <div ref={sentinelRef} className="flex h-10 items-center justify-center">
                    {loading && (
                        <div className="flex items-center gap-2 py-4 text-sm text-muted-foreground">
                            <span className="inline-block h-5 w-5 animate-spin rounded-full border-2 border-primary border-t-transparent"></span>
                            <span>{t('loading')}</span>
                        </div>
                    )}
                </div>
            </div>

            {isAdmin && (
                <>
                    {editFolder && (
                        <UpdateFolderModal
                            key={`folder-${editFolder.id}`}
                            folder={editFolder}
                            open={!!editFolder}
                            setOpen={(open) => !open && setEditFolder(null)}
                            onSuccess={refresh}
                        />
                    )}
                    {deleteFolder && (
                        <DeleteItemModal
                            item={deleteFolder}
                            open={!!deleteFolder}
                            setOpen={(open) => !open && setDeleteFolder(null)}
                            onDelete={handleDeleteFolder}
                        />
                    )}
                    {editTest && (
                        <UpdateTestModal
                            key={`test-${editTest.id}`}
                            test={editTest}
                            open={!!editTest}
                            setOpen={(open) => !open && setEditTest(null)}
                            onSuccess={refresh}
                        />
                    )}
                    {deleteTest && (
                        <DeleteItemModal
                            item={deleteTest}
                            open={!!deleteTest}
                            setOpen={(open) => !open && setDeleteTest(null)}
                            onDelete={handleDeleteTest}
                        />
                    )}
                </>
            )}
        </AppLayout>
    );
}
