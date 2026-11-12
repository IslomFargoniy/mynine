import React, { useState } from 'react';
import { CheckCircle, Eye, FileSpreadsheet, FileText, MinusCircle, TrashIcon } from 'lucide-react';
import { IconAction } from '@/components/ui/icon-action';
import { Table, TableBody, TableCell, TableEmpty, TableHead, TableHeader, TableRow, TruncatedText } from '@/components/ui/table';
import DeleteItemModal from '@/components/delete-item-modal';
import { Link, useForm, usePage } from '@inertiajs/react';
import { useTranslation } from 'react-i18next';
import { Auth, Attempt, type AttemptPaginate, SearchData } from '@/types';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { exportAttemptsToExcel } from '@/lib/excel-export';
import { formatServerTime } from '@/lib/server-time';

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

    const fmt = (value?: string | null) => formatServerTime(value, 'dd.MM HH:mm');

    const statusBadge = (finished: boolean) =>
        finished ? (
            <span className="inline-flex items-center gap-1 rounded-full bg-emerald-500/12 px-2 py-0.5 text-[10px] font-bold text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200">
                <CheckCircle className="h-3 w-3" /> {t('finished')}
            </span>
        ) : (
            <span className="inline-flex items-center gap-1 rounded-full bg-indigo-500/12 px-2 py-0.5 text-[10px] font-bold text-brand">
                <MinusCircle className="h-3 w-3" /> {t('in_progress')}
            </span>
        );

    return (
        <div className="glass-strong overflow-hidden rounded-[22px]">
            <div className="flex items-center justify-end border-b border-divider px-3 py-2">
                <Button
                    onClick={() => exportAttemptsToExcel(attempt.data, 'Attempts_Report')}
                    variant="ghost"
                    className="h-8 gap-1.5 rounded-full border border-emerald-500/25 bg-emerald-500/12 px-3 text-[10px] font-bold tracking-tighter text-emerald-800 uppercase transition-all hover:bg-emerald-500/20 hover:text-emerald-900 active:scale-95 dark:bg-emerald-400/15 dark:text-emerald-200 dark:hover:text-emerald-100"
                >
                    <FileSpreadsheet className="h-3.5 w-3.5" />
                    {t('export_to_excel')}
                </Button>
            </div>

            <Table>
                <TableHeader>
                    <TableRow>
                        <TableHead className="w-10 text-right">#</TableHead>
                        <TableHead>{t('attempts_table.candidate')}</TableHead>
                        <TableHead>
                            {t('test')} / {t('mock')}
                        </TableHead>
                        <TableHead className="hidden lg:table-cell">{t('status')}</TableHead>
                        <TableHead>{t('date')}</TableHead>
                        <TableHead>{t('result')}</TableHead>
                        <TableHead className="w-px text-right">
                            <span className="sr-only">{t('attempts_table.actions')}</span>
                        </TableHead>
                    </TableRow>
                </TableHeader>
                <TableBody>
                    {attempt.data.length === 0 && (
                        <TableEmpty colSpan={7}>
                            {searchData?.search || searchData?.mock_id || searchData?.test_id || searchData?.folder_id || searchData?.user_id || (searchData?.from && searchData?.to)
                                ? t('attempts_table.empty_filtered')
                                : t('attempts_table.empty')}
                        </TableEmpty>
                    )}
                    {attempt.data.map((item, index) => {
                        const globalIndex = (attempt.current_page - 1) * attempt.per_page + index + 1;
                        const isFinished = !!item.finished_at;
                        const candidate = item.name || item.mock_student?.name || item.mockStudent?.name || item.user?.name || '—';
                        // Attempt name usually equals the user's name: show the account only when it adds something.
                        const account = isAdmin && item.user ? [item.user.name !== candidate ? item.user.name : null, item.user.email].filter(Boolean).join(' · ') : '';

                        return (
                            <TableRow key={item.id} className="group">
                                <TableCell className="text-right font-mono text-muted-foreground tabular-nums max-md:hidden">{globalIndex}</TableCell>

                                <TableCell>
                                    <div className="flex min-w-0 items-center gap-2">
                                        <span className="font-mono text-[10px] text-muted-foreground md:hidden">#{globalIndex}</span>
                                        <TruncatedText className="max-w-[14rem] font-semibold text-foreground">{candidate}</TruncatedText>
                                    </div>
                                    {account && <TruncatedText className="max-w-[14rem] text-[11px] text-muted-foreground">{account}</TruncatedText>}
                                    <div className="mt-1 lg:hidden">{statusBadge(isFinished)}</div>
                                </TableCell>

                                <TableCell label={`${t('test')} / ${t('mock')}`}>
                                    <TruncatedText className="max-w-[14rem] font-semibold text-brand">{item?.mock?.name || item?.test?.folder?.name || '—'}</TruncatedText>
                                    <TruncatedText className="max-w-[14rem] text-[11px] text-muted-foreground">{item?.test?.name}</TruncatedText>
                                </TableCell>

                                <TableCell className="hidden lg:table-cell">{statusBadge(isFinished)}</TableCell>

                                <TableCell label={t('date')} className="text-[11px] whitespace-nowrap tabular-nums">
                                    <div className="font-semibold text-foreground" title={t('start')}>
                                        {fmt(item.started_at)}
                                    </div>
                                    {item.finished_at && (
                                        <div className="text-emerald-700 dark:text-emerald-300" title={t('end')}>
                                            {fmt(item.finished_at)}
                                        </div>
                                    )}
                                </TableCell>

                                <TableCell label={t('result')}>
                                    <div className="grid w-max grid-cols-2 gap-1 text-[11px]">
                                        {item.attempt_types.map((type) => {
                                            const score =
                                                type.type.name === 'Writing'
                                                    ? (type.band ?? null)
                                                    : type.type.name === 'Speaking'
                                                      ? type.score
                                                      : type.is_correct_count;

                                            return (
                                                <div
                                                    key={type.id}
                                                    className="flex items-center justify-between gap-1.5 rounded-md border border-glass-edge bg-muted px-1.5 py-0.5"
                                                    title={t(type.type.name.toLowerCase())}
                                                >
                                                    <span className="text-[9px] font-black opacity-70">{type.type.name[0]}</span>
                                                    <span className="font-black text-foreground tabular-nums">{score ?? '—'}</span>
                                                </div>
                                            );
                                        })}
                                    </div>
                                </TableCell>

                                <TableCell className="text-right max-md:border-t max-md:border-divider max-md:pt-2">
                                    <div className="flex items-center justify-end gap-0.5">
                                        {isFinished ? (
                                            <>
                                                <IconAction label={t('view_result')} tone="brand" asChild>
                                                    <Link href={route('attempt.show', item.id)}>
                                                        <Eye />
                                                    </Link>
                                                </IconAction>
                                                <IconAction label={t('download_pdf')} asChild>
                                                    <a href={route('attempt.pdf', item.id)} target="_blank" rel="noreferrer">
                                                        <FileText />
                                                    </a>
                                                </IconAction>
                                            </>
                                        ) : (
                                            <Link
                                                href={`/practice?attempt_id=${item.id}`}
                                                className="btn-glass-primary rounded-full px-3 py-1 text-xs font-bold whitespace-nowrap transition hover:brightness-110"
                                            >
                                                {t('continue')}
                                            </Link>
                                        )}

                                        {isAdmin && (
                                            <IconAction label={t('delete')} tone="danger" onClick={() => handleDeleteClick(item)}>
                                                <TrashIcon />
                                            </IconAction>
                                        )}
                                    </div>
                                </TableCell>
                            </TableRow>
                        );
                    })}
                </TableBody>
            </Table>

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
                                href={link.url ?? ''}
                                // The server keeps every filter in the page links (withQueryString).
                                onClick={(e) => !link.url && e.preventDefault()}
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
