import DeleteItemModal from '@/components/delete-item-modal';
import { ModuleBadge } from '@/components/exam-admin/shared';
import MockStudentManager from '@/components/mock/mock-student-manager';

import { Mock, type MockPaginate, SearchData, Test } from '@/types';
import { Link, useForm } from '@inertiajs/react';
import { format } from 'date-fns';
import { CheckCircle, Clock, MinusCircle, Monitor, PencilIcon, Plus, TrashIcon } from 'lucide-react';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { toast } from 'sonner';

interface MockTableProps extends MockPaginate {
    searchData: SearchData;
    tests: Test[];
}

const MockTable = ({ tests: _tests, searchData, ...mock }: MockTableProps) => {
    const { t } = useTranslation(); // Using the translation hook
    const [, setOpen] = useState(false);
    const [openDelete, setOpenDelete] = useState(false);
    const [selectedMock, setSelectedMock] = useState<Mock | null>(null);

    const renderStatusBadge = (item: Mock) => {
        const status = (item as any).status || (item.active ? 'active' : 'inactive');
        if (!item.active || status === 'inactive') {
            return (
                <span className="inline-flex items-center rounded-full bg-muted px-2 py-0.5 text-[10px] font-bold text-muted-foreground">
                    <MinusCircle className="mr-1 h-3 w-3" /> {t('inactive')}
                </span>
            );
        }
        if (status === 'scheduled') {
            return (
                <span className="inline-flex items-center rounded-full bg-amber-500/15 px-2 py-0.5 text-[10px] font-bold text-amber-800 dark:bg-amber-400/15 dark:text-amber-200">
                    <Clock className="mr-1 h-3 w-3" /> {t('scheduled')}
                </span>
            );
        }
        if (status === 'expired') {
            return (
                <span className="inline-flex items-center rounded-full bg-rose-500/12 px-2 py-0.5 text-[10px] font-bold text-rose-800 dark:bg-rose-400/15 dark:text-rose-200">
                    <MinusCircle className="mr-1 h-3 w-3" /> {t('expired')}
                </span>
            );
        }
        return (
            <span className="inline-flex items-center rounded-full bg-emerald-500/12 px-2 py-0.5 text-[10px] font-bold text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200">
                <CheckCircle className="mr-1 h-3 w-3" /> {t('active')}
            </span>
        );
    };

    const handleDeleteClick = (mockData: Mock) => {
        setSelectedMock(mockData); // Set the selected mock for deletion
        setOpenDelete(true); // Open the delete modal
    };

    const { delete: deleteMock, reset, clearErrors } = useForm();

    const handleDelete = (id: number) => {
        deleteMock(route('mock.destroy', id), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpen(false); // 🔒 CLOSE MODAL HERE
                toast.success(t('deleted_successfully')); // Success message
            },
            onError: (err) => {
                // Display a friendly error message if available
                const errorMessage = err?.error || t('delete_failed'); // Use fallback error message
                toast.error(errorMessage); // Display error message
            },
        });
    };

    return (
        <div>
            <div className="mb-4 flex items-center justify-between">
                <h2 className="text-xl font-semibold text-foreground">{t('mock')}</h2>
                <Link
                    href={route('mock.create')}
                    className="btn-glass-primary inline-flex cursor-pointer items-center gap-2 rounded-full px-5 py-2.5 text-xs font-bold transition-all hover:brightness-110 active:scale-95"
                >
                    <Plus className="h-4 w-4" />
                    {t('create')} {t('mock')}
                </Link>
            </div>

            {/* Cards Grid */}
            <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                {mock.data.map((item, index) => {
                    const globalIndex = (mock.current_page - 1) * mock.per_page + index + 1;

                    return (
                        <div
                            key={item.id}
                            className="glass group flex flex-col justify-between rounded-[22px] p-6 transition-all duration-300 hover:-translate-y-1"
                        >
                            {/* Header */}
                            <div className="mb-4">
                                <div className="flex items-center justify-between mb-2">
                                    <span className="text-[10px] font-bold uppercase tracking-widest text-brand">
                                        #{globalIndex}
                                    </span>
                                    {renderStatusBadge(item)}
                                </div>
                                <h3 className="line-clamp-1 text-xl font-bold text-foreground group-hover:text-brand transition-colors">
                                    <Link href={`/mock/${item.id}`}>{item.name}</Link>
                                </h3>
                                {item.modules && item.modules.length > 0 ? (
                                    <div className="mt-2 flex flex-wrap items-center gap-1">
                                        {item.modules.map((module) => (
                                            <ModuleBadge key={module.id} type={module.type?.name}>
                                                {module.type?.name?.[0]} · {module.test_type?.test?.name}
                                            </ModuleBadge>
                                        ))}
                                        {item.require_desktop && (
                                            <span className="inline-flex items-center gap-1 rounded-full border border-glass-edge bg-glass-subtle px-2 py-0.5 text-[10px] font-bold text-muted-foreground">
                                                <Monitor className="h-3 w-3" />
                                            </span>
                                        )}
                                    </div>
                                ) : (
                                    <div className="mt-1 flex items-center text-xs text-muted-foreground">
                                        <span className="font-semibold text-brand">{item.test?.folder?.name}</span>
                                        <span className="mx-2 opacity-30">/</span>
                                        <span className="truncate">{item.test?.name}</span>
                                    </div>
                                )}
                            </div>

                            {/* Comment */}
                            <div className="mb-6 flex-grow">
                                <p className="line-clamp-3 text-sm leading-relaxed text-muted-foreground italic">
                                    {item.comment || t('no_comment')}
                                </p>
                            </div>

                            {/* Dates */}
                            <div className="glass-subtle mb-6 space-y-2 rounded-[18px] p-3">
                                <div className="flex justify-between text-[11px]">
                                    <span className="text-muted-foreground">{t('started_at')}</span>
                                    <span className="font-mono font-medium text-foreground">
                                        {format(new Date(item.started_at), 'MMM dd, HH:mm')}
                                    </span>
                                </div>
                                <div className="flex justify-between text-[11px]">
                                    <span className="text-muted-foreground">{t('finished_at')}</span>
                                    <span className="font-mono font-medium text-foreground">
                                        {format(new Date(item.finished_at), 'MMM dd, HH:mm')}
                                    </span>
                                </div>
                            </div>

                            {/* Actions */}
                            <div className="flex items-center justify-between gap-2 pt-3 border-t border-divider">
                                <MockStudentManager
                                    mockId={item.id}
                                    mockName={item.name}
                                    students={(item as any).students ?? []}
                                />

                                <div className="flex items-center gap-1.5">
                                    <Link
                                        href={route('mock.edit', item.id)}
                                        className="p-2 bg-indigo-500/12 text-brand hover:bg-primary hover:text-primary-foreground rounded-full font-semibold text-xs transition-all cursor-pointer active:scale-95"
                                        title={t('edit')}
                                    >
                                        <PencilIcon className="h-3.5 w-3.5" />
                                    </Link>

                                    <button
                                        type="button"
                                        onClick={() => handleDeleteClick(item)}
                                        className="p-2 bg-rose-500/12 text-rose-800 dark:bg-rose-400/15 dark:text-rose-200 hover:bg-rose-600 hover:text-white dark:hover:bg-rose-600 dark:hover:text-white rounded-full font-semibold text-xs transition-all cursor-pointer active:scale-95"
                                        title={t('delete')}
                                    >
                                        <TrashIcon className="h-3.5 w-3.5" />
                                    </button>
                                </div>
                            </div>
                        </div>
                    );
                })}
            </div>

            {/* Modals */}
            {selectedMock && openDelete && <DeleteItemModal item={selectedMock} open={openDelete} setOpen={setOpenDelete} onDelete={handleDelete} />}

            {/* Pagination */}
            <div className="mt-6 flex flex-col items-center justify-between gap-3 text-sm text-foreground sm:flex-row">
                <div>
                    {t('showing', {
                        from: mock.from,
                        to: mock.to,
                        total: mock.total,
                    })}
                </div>
                <div className="flex flex-wrap justify-center gap-1">
                    {mock.links.map((link, index) => (
                        <Link
                            key={index}
                            href={`${link.url ?? '?'}&search=${searchData.search}&per_page=${searchData.per_page}`}
                            className={`rounded-full px-3 py-1 text-sm transition ${
                                link.active
                                    ? 'btn-glass-primary'
                                    : !link.url
                                      ? 'cursor-not-allowed text-muted-foreground'
                                      : 'border border-glass-edge bg-glass-subtle text-foreground hover:bg-accent'
                            }`}
                            dangerouslySetInnerHTML={{ __html: link.label }}
                        />
                    ))}
                </div>
            </div>
        </div>
    );
};

export default MockTable;
