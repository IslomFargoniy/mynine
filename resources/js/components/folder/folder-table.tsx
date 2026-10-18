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
    const isTeacher = auth?.user?.roles?.some(role => role.name === 'Teacher');

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
                <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-100">
                    {t('folder')}
                </h2>
                {(isAdmin || isTeacher) && <CreateFolderModal />}
            </div>


            {/* Cards Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                {folder.data.map((item, index) => {
                    const globalIndex = (folder.current_page - 1) * folder.per_page + index + 1;

                    return (
                        <div
                            key={item.id}
                            className="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl p-5 shadow-xs hover:shadow-md transition-all flex flex-col justify-between"
                        >
                            {/* Header */}
                            <div className="flex justify-between items-start gap-2">
                                <h3 className="text-base font-bold text-gray-900 dark:text-gray-100 line-clamp-1 hover:text-blue-600 dark:hover:text-blue-400 transition-colors">
                                    <Link href={`/folder/${item.id}`}>
                                        {item.name}
                                    </Link>
                                </h3>
                                <span className="text-[11px] font-semibold text-gray-400 dark:text-gray-500 shrink-0">#{globalIndex}</span>
                            </div>

                            {/* Comment */}
                            <p className="mt-1.5 text-xs text-gray-500 dark:text-gray-400 line-clamp-2 min-h-[32px]">
                                {item.comment || t('no_comment')}
                            </p>

                            {/* Status */}
                            <div className="mt-4 flex items-center justify-between border-t border-gray-100 dark:border-gray-800/60 pt-3">
                                <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold ${
                                    item.active == 1
                                        ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-800/40'
                                        : 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400'
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
                            {(isAdmin || isTeacher) && (
                                <div className="mt-3 flex gap-2 pt-1">
                                    <button
                                        type="button"
                                        onClick={() => handleUpdateClick(item)}
                                        className="px-3 py-2 bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 hover:bg-blue-600 hover:text-white dark:hover:bg-blue-600 dark:hover:text-white rounded-xl font-semibold text-xs flex items-center justify-center gap-1.5 flex-1 transition-all cursor-pointer shadow-xs active:scale-95"
                                        title={t('edit')}
                                    >
                                        <PencilIcon className="w-3.5 h-3.5" />
                                    </button>

                                    <button
                                        type="button"
                                        onClick={() => handleDeleteClick(item)}
                                        className="px-3 py-2 bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400 hover:bg-red-600 hover:text-white dark:hover:bg-red-600 dark:hover:text-white rounded-xl font-semibold text-xs flex items-center justify-center gap-1.5 flex-1 transition-all cursor-pointer shadow-xs active:scale-95"
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
            <div className="mt-6 flex justify-between items-center text-sm text-gray-600 dark:text-gray-300">
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
                            className={`px-3 py-1 rounded-md text-sm transition ${
                                link.active
                                    ? 'bg-blue-600 text-white'
                                    : !link.url
                                        ? 'text-gray-400 dark:text-gray-500 cursor-not-allowed'
                                        : 'bg-white dark:bg-gray-800 dark:text-gray-200 text-gray-700 border border-gray-300 dark:border-gray-600 hover:bg-gray-100 dark:hover:bg-gray-700'
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
