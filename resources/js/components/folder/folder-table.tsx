import React, { useState } from 'react';
import CreateFolderModal from '@/components/folder/create-folder-modal';
import { CheckCircle, MinusCircle, PencilIcon, TrashIcon } from 'lucide-react';
import UpdateFolderModal from '@/components/folder/update-folder-modal';
import DeleteItemModal from '@/components/delete-item-modal';
import { Link, useForm, usePage } from '@inertiajs/react';
import { useTranslation } from 'react-i18next';
import { Auth, Folder, type FolderPaginate, SearchData } from '@/types';
import { toast } from 'sonner';


interface FolderTableProps extends FolderPaginate {
    searchData: SearchData;
}

const FolderTable = ({ searchData, ...folder }: FolderTableProps) => {

    const { t } = useTranslation();  // Using the translation hook
    const [open, setOpen] = useState(false);
    const [openDelete, setOpenDelete] = useState(false);
    const [selectedFolder, setSelectedFolder] = useState<Folder | null>(null);


    const { auth } = usePage().props as unknown as { auth?: Auth };

    const isAdmin = auth?.user?.roles?.some(role => role.name === 'Admin');

    const handleUpdateClick = (folderData: Folder) => {
        setSelectedFolder(folderData); // Set the selected folder data
        setOpen(true); // Open the modal
    };

    const handleDeleteClick = (folderData: Folder) => {
        setSelectedFolder(folderData); // Set the selected folder for deletion
        setOpenDelete(true); // Open the delete modal
    };


    const { delete: deleteFolder, reset, clearErrors } = useForm();

    const handleDelete = (id: number) => {
        deleteFolder(route('folder.destroy', id), {
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
            }
        });
    };

    return (
        <div>
            <div className="flex justify-between items-center mb-4">
                <h2 className="text-xl font-semibold text-foreground">
                    {t('folder')}
                </h2>
                {isAdmin && <CreateFolderModal />}
            </div>


            {/* Cards Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                {folder.data.map((item, index) => {
                    const globalIndex = (folder.current_page - 1) * folder.per_page + index + 1;

                    return (
                        <div
                            key={item.id}
                            className="glass rounded-[22px] p-5 hover:bg-accent/40 transition-all flex flex-col justify-between"
                        >
                            {/* Header */}
                            <div className="flex justify-between items-start gap-2">
                                <h3 className="text-base font-bold text-foreground line-clamp-1 hover:text-brand transition-colors">
                                    <Link href={`/folder/${item.id}`}>
                                        {item.name}
                                    </Link>
                                </h3>
                                <span className="text-[11px] font-semibold text-muted-foreground shrink-0">#{globalIndex}</span>
                            </div>

                            {/* Comment */}
                            <p className="mt-1.5 text-xs text-muted-foreground line-clamp-2 min-h-[32px]">
                                {item.comment || t('no_comment')}
                            </p>

                            {/* Status */}
                            <div className="mt-4 flex items-center justify-between border-t border-divider pt-3">
                                <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold ${
                                    item.active == 1
                                        ? 'bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200 border border-emerald-500/25'
                                        : 'bg-muted text-foreground border border-glass-edge'
                                }`}>
                                    {item.active == 1 ? (
                                        <CheckCircle className="w-3.5 h-3.5" />
                                    ) : (
                                        <MinusCircle className="w-3.5 h-3.5" />
                                    )}
                                    {item.active == 1 ? t('active') : t('inactive')}
                                </span>
                            </div>

                            {/* Actions */}
                            {isAdmin && (
                                <div className="mt-3 flex gap-2 pt-1">
                                    <button
                                        type="button"
                                        onClick={() => handleUpdateClick(item)}
                                        className="px-3 py-2 bg-indigo-500/12 text-brand hover:bg-primary hover:text-primary-foreground rounded-full font-semibold text-xs flex items-center justify-center gap-1.5 flex-1 transition-all cursor-pointer active:scale-95"
                                        title={t('edit')}
                                    >
                                        <PencilIcon className="w-3.5 h-3.5" />
                                    </button>

                                    <button
                                        type="button"
                                        onClick={() => handleDeleteClick(item)}
                                        className="px-3 py-2 bg-rose-500/12 text-rose-800 dark:bg-rose-400/15 dark:text-rose-200 hover:bg-destructive hover:text-white dark:hover:bg-destructive dark:hover:text-white rounded-full font-semibold text-xs flex items-center justify-center gap-1.5 flex-1 transition-all cursor-pointer active:scale-95"
                                        title={t('delete')}
                                    >
                                        <TrashIcon className="w-3.5 h-3.5" />
                                    </button>
                                </div>
                            )}
                        </div>
                    );
                })}
            </div>

            {/* Modals */}
            {selectedFolder && open && (
                <UpdateFolderModal
                    folder={selectedFolder}
                    open={open}
                    setOpen={setOpen}
                />
            )}

            {selectedFolder && openDelete && (
                <DeleteItemModal
                    item={selectedFolder}
                    open={openDelete}
                    setOpen={setOpenDelete}
                    onDelete={handleDelete}
                />
            )}

            {/* Pagination */}
            <div className="mt-6 flex justify-between items-center text-sm text-muted-foreground">
                <div>
                    {t('showing', {
                        from: folder.from,
                        to: folder.to,
                        total: folder.total
                    })}
                </div>
                <div className="flex gap-1">
                    {folder.links.map((link, index) => (
                        <Link
                            key={index}
                            href={`${link.url ?? '?'}&search=${searchData.search}&per_page=${searchData.per_page}`}
                            className={`px-3 py-1 rounded-full text-sm transition ${
                                link.active
                                    ? 'bg-primary text-primary-foreground shadow-glass-pill'
                                    : !link.url
                                        ? 'text-muted-foreground cursor-not-allowed'
                                        : 'bg-glass-subtle text-foreground border border-glass-edge hover:bg-accent'
                            }`}
                            dangerouslySetInnerHTML={{ __html: link.label }}
                        />
                    ))}
                </div>
            </div>
        </div>

    );
};

export default FolderTable;
