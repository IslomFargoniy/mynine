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
        <div className="glass-strong rounded-[22px] overflow-hidden">
            {/* Header / Actions potentially here */}
            
            {/* Table Container */}
            <div className="overflow-x-auto">
                <table className="w-full text-sm text-left">
                    <thead className="bg-muted text-muted-foreground text-xs font-semibold uppercase tracking-wide border-b border-divider">
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
                                    className="h-8 px-3 rounded-full border border-emerald-500/25 bg-emerald-500/12 text-emerald-800 hover:bg-emerald-500/20 hover:text-emerald-900 dark:bg-emerald-400/15 dark:text-emerald-200 dark:hover:text-emerald-100 gap-1.5 font-bold text-[10px] uppercase tracking-tighter transition-all active:scale-95"
                                >
                                    <FileSpreadsheet className="h-3.5 w-3.5" />
                                    {t('export_to_excel') ?? 'Export'}
                                </Button>
                            </th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-divider">
                        {attempt.data.map((item, index) => {
                            const globalIndex = (attempt.current_page - 1) * attempt.per_page + index + 1;
                            const isFinished = !!item.finished_at;

                            return (
                                <tr key={item.id} className="border-b border-divider hover:bg-accent/60 transition-colors group">
                                    <td className="px-6 py-4 text-muted-foreground font-mono">{globalIndex}</td>
                                    
                                    {isAdmin && (
                                        <td className="px-6 py-4">
                                            <div className="flex flex-col">
                                                <span className="font-medium text-foreground">{item?.user?.name}</span>
                                                <span className="text-xs text-muted-foreground">{item?.user?.email}</span>
                                            </div>
                                        </td>
                                    )}

                                    <td className="px-6 py-4 font-medium text-foreground">
                                        {item.name || item.mock_student?.name || (item as any).mockStudent?.name || item.user?.name || "---"}
                                    </td>

                                    <td className="px-6 py-4">
                                        <div className="flex flex-col">
                                            <span className="font-semibold text-brand ">
                                                {item?.mock?.name || item?.test?.folder?.name}
                                            </span>
                                            <span className="text-xs text-muted-foreground">
                                                {item?.test?.name}
                                            </span>
                                        </div>
                                    </td>

                                    <td className="px-6 py-4 text-center">
                                        {isFinished ? (
                                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200">
                                                <CheckCircle className="w-3 h-3 mr-1" /> {t('finished') ?? 'Finished'}
                                            </span>
                                        ) : (
                                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-500/12 text-brand animate-pulse">
                                                <MinusCircle className="w-3 h-3 mr-1" /> {t('in_progress') ?? 'In Progress'}
                                            </span>
                                        )}
                                    </td>

                                    <td className="px-6 py-4">
                                        <div className="text-[10px] space-y-1.5 font-medium">
                                            <div className="flex items-center text-muted-foreground">
                                                <span className="w-16 opacity-60 uppercase tracking-tighter">{t('start')}:</span>
                                                <span className="font-bold">{item.started_at ? format(new Date(item.started_at), 'MMM dd, HH:mm') : '---'}</span>
                                            </div>
                                            {item.finished_at && (
                                                <div className="flex items-center text-emerald-700 dark:text-emerald-300">
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
                                                    <div key={type.id} className="flex justify-between items-center bg-muted px-1.5 py-0.5 rounded-md border border-glass-edge">
                                                        <span className="opacity-70 truncate font-black text-[9px]" title={t(type.type.name.toLowerCase())}>
                                                            {t(type.type.name.toLowerCase())[0].toUpperCase()}
                                                        </span>
                                                        <span className="font-black text-foreground">{score}</span>
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
                                            className="flex items-center gap-1.5 px-3 py-1.5 bg-indigo-500/12 text-brand rounded-full hover:bg-primary hover:text-primary-foreground transition-colors"
                                        >
                                            <Icon icon="solar:eye-bold" className="text-lg" />
                                            <span className="font-semibold text-xs">{t('view_result')}</span>
                                        </button>

                                        <button
                                            onClick={() => window.open(route('attempt.pdf', item.id), '_blank')}
                                            className="flex items-center gap-1.5 px-3 py-1.5 border border-glass-edge bg-glass-subtle text-foreground rounded-full hover:bg-accent transition-colors"
                                        >
                                            <Icon icon="solar:document-bold" className="text-lg" />
                                            <span className="font-semibold text-xs">{t('download_pdf')}</span>
                                        </button>
                                                </>
                                            ) : (
                                                <Link
                                                    href={`/practice?attempt_id=${item.id}`}
                                                    className="btn-glass-primary px-3 py-1 text-xs font-bold rounded-full hover:brightness-110 transition"
                                                >
                                                    {t('continue')}
                                                </Link>
                                            )}

                                            {isAdmin && (
                                                <button
                                                    onClick={() => handleDeleteClick(item)}
                                                    className="p-2 text-rose-700 dark:text-rose-300 hover:bg-rose-500/12 dark:hover:bg-rose-400/15 rounded-full transition-colors opacity-0 group-hover:opacity-100"
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
                <div className="px-6 py-4 bg-muted border-t border-divider flex flex-col sm:flex-row justify-between items-center gap-4">
                    <div className="text-sm text-muted-foreground">
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
                                className={`px-3 py-1 rounded-full text-sm transition-all duration-200 ${
                                    link.active
                                        ? 'btn-glass-primary'
                                        : !link.url
                                            ? 'text-muted-foreground opacity-60 cursor-not-allowed border border-transparent'
                                            : 'bg-glass-subtle text-foreground border border-glass-edge hover:bg-accent hover:text-brand'
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
