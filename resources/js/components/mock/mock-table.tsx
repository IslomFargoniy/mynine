import DeleteItemModal from '@/components/delete-item-modal';
import CreateMockModal from '@/components/mock/create-mock-modal';
import UpdateMockModal from '@/components/mock/update-mock-modal';
import MockStudentManager from '@/components/mock/mock-student-manager';

import { Mock, type MockPaginate, SearchData, Test } from '@/types';
import { Link, useForm } from '@inertiajs/react';
import { format } from 'date-fns';
import { CheckCircle, Clock, MinusCircle, PencilIcon, TrashIcon } from 'lucide-react';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { toast } from 'sonner';

interface MockTableProps extends MockPaginate {
    searchData: SearchData;
    tests: Test[];
}

const MockTable = ({ tests, searchData, ...mock }: MockTableProps) => {
    const { t } = useTranslation(); // Using the translation hook
    const [open, setOpen] = useState(false);
    const [openDelete, setOpenDelete] = useState(false);
    const [selectedMock, setSelectedMock] = useState<Mock | null>(null);

    const renderStatusBadge = (item: Mock) => {
        const status = (item as any).status || (item.active ? 'active' : 'inactive');
        if (!item.active || status === 'inactive') {
            return (
                <span className="inline-flex items-center rounded-full bg-gray-50 px-2 py-0.5 text-[10px] font-bold text-gray-500 dark:bg-gray-800 dark:text-gray-400">
                    <MinusCircle className="mr-1 h-3 w-3" /> {t('inactive') || 'Nofaol'}
                </span>
            );
        }
        if (status === 'scheduled') {
            return (
                <span className="inline-flex items-center rounded-full bg-amber-50 px-2 py-0.5 text-[10px] font-bold text-amber-700 dark:bg-amber-900/20 dark:text-amber-400">
                    <Clock className="mr-1 h-3 w-3" /> {t('scheduled') || 'Boshlanmagan'}
                </span>
            );
        }
        if (status === 'expired') {
            return (
                <span className="inline-flex items-center rounded-full bg-rose-50 px-2 py-0.5 text-[10px] font-bold text-rose-700 dark:bg-rose-900/20 dark:text-rose-400">
                    <MinusCircle className="mr-1 h-3 w-3" /> {t('expired') || 'Vaqti tugagan'}
                </span>
            );
        }
        return (
            <span className="inline-flex items-center rounded-full bg-green-50 px-2 py-0.5 text-[10px] font-bold text-green-700 dark:bg-green-900/20 dark:text-green-400">
                <CheckCircle className="mr-1 h-3 w-3" /> {t('active') || 'Faol'}
            </span>
        );
    };

    const handleUpdateClick = (mockData: Mock) => {
        setSelectedMock(mockData); // Set the selected mock data
        setOpen(true); // Open the modal
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
                <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100">{t('mock')}</h2>
                <CreateMockModal tests={tests} />
            </div>

            {/* Cards Grid */}
            <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                {mock.data.map((item, index) => {
                    const globalIndex = (mock.current_page - 1) * mock.per_page + index + 1;

                    return (
                        <div
                            key={item.id}
                            className="group flex flex-col justify-between rounded-2xl border-2 border-gray-200 bg-white p-6 shadow-sm transition-all duration-300 hover:-translate-y-1 hover:shadow-xl dark:border-gray-700 dark:bg-gray-900"
                        >
                            {/* Header */}
                            <div className="mb-4">
                                <div className="flex items-center justify-between mb-2">
                                    <span className="text-[10px] font-bold uppercase tracking-widest text-blue-500 opacity-70">
                                        #{globalIndex}
                                    </span>
                                    {renderStatusBadge(item)}
                                </div>
                                <h3 className="line-clamp-1 text-xl font-bold text-gray-900 dark:text-white group-hover:text-blue-600 transition-colors">
                                    <Link href={`/mock/${item.id}`}>{item.name}</Link>
                                </h3>
                                <div className="mt-1 flex items-center text-xs text-gray-500 dark:text-gray-400">
                                    <span className="font-semibold text-blue-600/70">{item.test?.folder?.name}</span>
                                    <span className="mx-2 opacity-30">/</span>
                                    <span className="truncate">{item.test?.name}</span>
                                </div>
                            </div>

                            {/* Comment */}
                            <div className="mb-6 flex-grow">
                                <p className="line-clamp-3 text-sm leading-relaxed text-gray-600 dark:text-gray-400 italic">
                                    {item.comment || t('no_comment')}
                                </p>
                            </div>

                            {/* Dates */}
                            <div className="mb-6 space-y-2 rounded-xl bg-gray-50 p-3 dark:bg-gray-800/50">
                                <div className="flex justify-between text-[11px]">
                                    <span className="text-gray-500">{t('started_at')}</span>
                                    <span className="font-mono font-medium text-gray-700 dark:text-gray-300">
                                        {format(new Date(item.started_at), 'MMM dd, HH:mm')}
                                    </span>
                                </div>
                                <div className="flex justify-between text-[11px]">
                                    <span className="text-gray-500">{t('finished_at')}</span>
                                    <span className="font-mono font-medium text-gray-700 dark:text-gray-300">
                                        {format(new Date(item.finished_at), 'MMM dd, HH:mm')}
                                    </span>
                                </div>
                            </div>

                            {/* Actions */}
                            <div className="flex items-center justify-between gap-2 pt-3 border-t border-gray-100 dark:border-gray-800">
                                <MockStudentManager
                                    mockId={item.id}
                                    mockName={item.name}
                                    students={(item as any).students ?? []}
                                />

                                <div className="flex items-center gap-1.5">
                                    <button
                                        type="button"
                                        onClick={() => handleUpdateClick(item)}
                                        className="p-2 bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 hover:bg-blue-600 hover:text-white dark:hover:bg-blue-600 dark:hover:text-white rounded-xl font-semibold text-xs transition-all cursor-pointer shadow-xs active:scale-95"
                                        title={t('edit')}
                                    >
                                        <PencilIcon className="h-3.5 w-3.5" />
                                    </button>

                                    <button
                                        type="button"
                                        onClick={() => handleDeleteClick(item)}
                                        className="p-2 bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400 hover:bg-red-600 hover:text-white dark:hover:bg-red-600 dark:hover:text-white rounded-xl font-semibold text-xs transition-all cursor-pointer shadow-xs active:scale-95"
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
            {selectedMock && open && <UpdateMockModal tests={tests} mock={selectedMock} open={open} setOpen={setOpen} />}

            {selectedMock && openDelete && <DeleteItemModal item={selectedMock} open={openDelete} setOpen={setOpenDelete} onDelete={handleDelete} />}

            {/* Pagination */}
            <div className="mt-6 flex items-center justify-between text-sm text-gray-600 dark:text-gray-300">
                <div>
                    {t('showing', {
                        from: mock.from,
                        to: mock.to,
                        total: mock.total,
                    })}
                </div>
                <div className="flex gap-1">
                    {mock.links.map((link, index) => (
                        <Link
                            key={index}
                            href={`${link.url ?? '?'}&search=${searchData.search}&per_page=${searchData.per_page}`}
                            className={`rounded-md px-3 py-1 text-sm transition ${
                                link.active
                                    ? 'bg-blue-600 text-white'
                                    : !link.url
                                      ? 'cursor-not-allowed text-gray-400 dark:text-gray-500'
                                      : 'border border-gray-300 bg-white text-gray-700 hover:bg-gray-100 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-200 dark:hover:bg-gray-700'
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
