import React, { useState } from 'react';
import { CheckCircle, FileSpreadsheet, MinusCircle, TrashIcon } from 'lucide-react';
import DeleteItemModal from '@/components/delete-item-modal';
import { Link, useForm, usePage } from '@inertiajs/react';
import { useTranslation } from 'react-i18next';
import { Auth, Attempt, type AttemptPaginate, SearchData } from '@/types';
import { toast } from 'sonner';
import { Icon } from '@iconify/react';
import { format } from 'date-fns';
import { Button } from '@/components/ui/button';
import { exportAttemptsToExcel } from '@/lib/excel-export';

interface AttemptTableProps extends AttemptPaginate {
    searchData: SearchData;
    hidePagination?: boolean;
}

const AttemptTable = ({ searchData, hidePagination, ...attempt }: AttemptTableProps) => {



    const { t } = useTranslation();  // Using the translation hook
    const [openDelete, setOpenDelete] = useState(false);
    const [selectedAttempt, setSelectedAttempt] = useState<Attempt | null>(null);


    const { auth } = usePage().props as unknown as { auth?: Auth };

    const isAdmin = auth?.user?.roles?.some(role => role.name === 'Admin');
    const isTeacher = auth?.user?.roles?.some(role => role.name === 'Teacher');

    const handleDeleteClick = (attemptData: Attempt) => {
        setSelectedAttempt(attemptData); // Set the selected attempt for deletion
        setOpenDelete(true); // Open the delete modal
    };


    const { delete: deleteAttempt, reset, clearErrors } = useForm();

    const handleDelete = (id: number) => {
        deleteAttempt(route('attempt.destroy', id), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpenDelete(false); // 🔒 CLOSE MODAL HERE
                toast.success(t('deleted_successfully')); // Success message
            },
            onError: (err) => {
                // Display a friendly error message if available
                const errorMessage = err?.error || t('delete_failed'); // Use fallback error message
                toast.error(errorMessage); // Display error message
            }
        });
    };

    return (
        <div className="bg-white dark:bg-gray-900 rounded-xl shadow-lg border-2 border-gray-200 dark:border-gray-700 overflow-hidden">
            {/* Header / Actions potentially here */}
            
            {/* Table Container */}
            <div className="overflow-x-auto">
                <table className="w-full text-sm text-left">
                    <thead className="bg-gray-50 dark:bg-gray-800/50 text-gray-600 dark:text-gray-400 font-medium border-b border-gray-200 dark:border-gray-700">
                        <tr>
                            <th className="px-6 py-4 font-semibold uppercase tracking-wider">#</th>
                            {isAdmin && <th className="px-6 py-4 font-semibold uppercase tracking-wider">{t('user')}</th>}
                            <th className="px-6 py-4 font-semibold uppercase tracking-wider">{t('attempt_name')}</th>
                            <th className="px-6 py-4 font-semibold uppercase tracking-wider">{t('test')} / {t('mock')}</th>
                            <th className="px-6 py-4 font-semibold uppercase tracking-wider text-center">{t('status')}</th>
                            <th className="px-6 py-4 font-semibold uppercase tracking-wider">{t('date')}</th>
                            <th className="px-6 py-4 font-semibold uppercase tracking-wider">{t('result')}</th>
                            <th className="px-6 py-4 font-semibold uppercase tracking-wider text-right">
                                <Button 
                                    onClick={() => exportAttemptsToExcel(attempt.data, 'Attempts_Report')}
                                    variant="ghost"
                                    className="h-8 px-2 rounded-lg border border-green-200 bg-green-50/50 text-green-700 hover:bg-green-100 hover:text-green-800 dark:border-green-900/30 dark:bg-green-900/20 dark:text-green-400 gap-1.5 font-bold text-[10px] uppercase tracking-tighter transition-all active:scale-95"
                                >
                                    <FileSpreadsheet className="h-3.5 w-3.5" />
                                    {t('export_to_excel') ?? 'Export'}
                                </Button>
                            </th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200 dark:divide-gray-800">
                        {attempt.data.map((item, index) => {
                            const globalIndex = (attempt.current_page - 1) * attempt.per_page + index + 1;
                            const isFinished = !!item.finished_at;

                            return (
                                <tr key={item.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/40 transition-colors group">
                                    <td className="px-6 py-4 text-gray-500 dark:text-gray-400 font-mono">{globalIndex}</td>
                                    
                                    {isAdmin && (
                                        <td className="px-6 py-4">
                                            <div className="flex flex-col">
                                                <span className="font-medium text-gray-900 dark:text-gray-100">{item?.user?.name}</span>
                                                <span className="text-xs text-gray-500">{item?.user?.email}</span>
                                            </div>
                                        </td>
                                    )}

                                    <td className="px-6 py-4 font-medium text-gray-900 dark:text-gray-100">
                                        {item.name || item.mock_student?.name || (item as any).mockStudent?.name || item.user?.name || "---"}
                                    </td>

                                    <td className="px-6 py-4">
                                        <div className="flex flex-col">
                                            <span className="font-semibold text-blue-600 dark:text-blue-400">
                                                {item?.mock?.name || item?.test?.folder?.name}
                                            </span>
                                            <span className="text-xs text-gray-500">
                                                {item?.test?.name}
                                            </span>
                                        </div>
                                    </td>

                                    <td className="px-6 py-4 text-center">
                                        {isFinished ? (
                                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">
                                                <CheckCircle className="w-3 h-3 mr-1" /> {t('finished') ?? 'Finished'}
                                            </span>
                                        ) : (
                                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400 animate-pulse">
                                                <MinusCircle className="w-3 h-3 mr-1" /> {t('in_progress') ?? 'In Progress'}
                                            </span>
                                        )}
                                    </td>

                                    <td className="px-6 py-4">
                                        <div className="text-[10px] space-y-1.5 font-medium">
                                            <div className="flex items-center text-gray-600 dark:text-gray-400">
                                                <span className="w-16 opacity-60 uppercase tracking-tighter">{t('start')}:</span>
                                                <span className="font-bold">{item.started_at ? format(new Date(item.started_at), 'MMM dd, HH:mm') : '---'}</span>
                                            </div>
                                            {item.finished_at && (
                                                <div className="flex items-center text-green-600 dark:text-green-500">
                                                    <span className="w-16 opacity-60 uppercase tracking-tighter">{t('end')}:</span>
                                                    <span className="font-bold">{format(new Date(item.finished_at), 'MMM dd, HH:mm')}</span>
                                                </div>
                                            )}
                                        </div>
                                    </td>

                                    <td className="px-6 py-4">
                                        <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-[11px] min-w-[120px]">
                                            {item.attempt_types.map((type) => {
                                                const score = type.type.name === 'Writing'
                                                    ? Number(type.is_correct_count ?? 0) / 2
                                                    : type.type.name === 'Speaking'
                                                        ? type.score
                                                        : type.is_correct_count;
                                                
                                                return (
                                                    <div key={type.id} className="flex justify-between items-center bg-gray-100 dark:bg-gray-800 px-1.5 py-0.5 rounded border border-gray-200 dark:border-gray-700">
                                                        <span className="opacity-70 truncate font-black text-[9px]" title={t(type.type.name.toLowerCase())}>
                                                            {t(type.type.name.toLowerCase())[0].toUpperCase()}
                                                        </span>
                                                        <span className="font-black text-gray-800 dark:text-gray-200">{score}</span>
                                                    </div>
                                                );
                                            })}
                                        </div>
                                    </td>

                                    <td className="px-6 py-4 text-right">
                                        <div className="flex justify-end items-center gap-2">
                                            {isFinished ? (
                                                <>
                                                    <button
                                            onClick={() => window.location.href = route('attempt.show', item.id)}
                                            className="flex items-center gap-1.5 px-3 py-1.5 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-600 hover:text-white transition-colors"
                                        >
                                            <Icon icon="solar:eye-bold" className="text-lg" />
                                            <span className="font-semibold text-xs">{t('view_result')}</span>
                                        </button>

                                        <button
                                            onClick={() => window.open(route('attempt.pdf', item.id), '_blank')}
                                            className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-50 text-gray-600 rounded-lg hover:bg-gray-800 hover:text-white transition-colors"
                                        >
                                            <Icon icon="solar:document-bold" className="text-lg" />
                                            <span className="font-semibold text-xs">{t('download_pdf')}</span>
                                        </button>
                                                </>
                                            ) : (
                                                <Link
                                                    href={`/practice?attempt_id=${item.id}`}
                                                    className="px-3 py-1 bg-blue-600 text-white text-xs font-bold rounded-md hover:bg-blue-700 transition shadow-sm"
                                                >
                                                    {t('continue')}
                                                </Link>
                                            )}

                                            {(isAdmin || isTeacher) && (
                                                <button
                                                    onClick={() => handleDeleteClick(item)}
                                                    className="p-2 text-red-500 hover:bg-red-50 dark:hover:bg-red-900/30 rounded-lg transition-colors opacity-0 group-hover:opacity-100"
                                                    title={t('delete')}
                                                >
                                                    <TrashIcon className="w-4 h-4" />
                                                </button>
                                            )}
                                        </div>
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>
            </div>



            {/* Pagination */}
            {!hidePagination && (
                <div className="px-6 py-4 bg-gray-50 dark:bg-gray-800/30 border-t border-gray-200 dark:border-gray-700 flex flex-col sm:flex-row justify-between items-center gap-4">
                    <div className="text-sm text-gray-500 dark:text-gray-400">
                        {t('showing', {
                            from: attempt.from,
                            to: attempt.to,
                            total: attempt.total
                        })}
                    </div>
                    <div className="flex gap-1 overflow-x-auto pb-2 sm:pb-0">
                        {attempt.links.map((link, index) => (
                            <Link
                                key={index}
                                href={`${link.url ?? '?'}&search=${searchData.search}&per_page=${searchData.per_page}`}
                                className={`px-3 py-1 rounded-md text-sm transition-all duration-200 ${
                                    link.active
                                        ? 'bg-blue-600 text-white shadow-md'
                                        : !link.url
                                            ? 'text-gray-300 dark:text-gray-600 cursor-not-allowed border border-transparent'
                                            : 'bg-white dark:bg-gray-800 dark:text-gray-200 text-gray-700 border border-gray-200 dark:border-gray-700 hover:border-blue-500 hover:text-blue-600'
                                }`}
                                dangerouslySetInnerHTML={{ __html: link.label }}
                            />
                        ))}
                    </div>
                </div>
            )}

            {/* Delete Modal */}
            {selectedAttempt && openDelete && (
                <DeleteItemModal
                    item={selectedAttempt}
                    open={openDelete}
                    setOpen={setOpenDelete}
                    onDelete={handleDelete}
                />
            )}
        </div>
    );
};

export default AttemptTable;
