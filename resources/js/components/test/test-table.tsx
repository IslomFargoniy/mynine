import React, { useState } from 'react';
import CreateTestModal from '@/components/test/create-test-modal';
import { PencilIcon, TrashIcon } from 'lucide-react';
import UpdateTestModal from '@/components/test/update-test-modal';
import DeleteItemModal from '@/components/delete-item-modal';
import { Link, useForm, usePage } from '@inertiajs/react';
import { useTranslation } from 'react-i18next';
import { Auth, Test, Folder } from '@/types';
import { toast } from 'sonner';



const TestTable = ({ ...folder }: Folder) => {

    const { t } = useTranslation();  // Using the translation hook
    const [open, setOpen] = useState(false);
    const [openDelete, setOpenDelete] = useState(false);
    const [selectedTest, setSelectedTest] = useState<Test | null>(null);


    const { auth } = usePage().props as unknown as { auth?: Auth };

    const isAdmin = auth?.user?.roles?.some(role => role.name === 'Admin');

    const handleUpdateClick = (testData: Test) => {
        setSelectedTest(testData); // Set the selected test data
        setOpen(true); // Open the modal
    };

    const handleDeleteClick = (testData: Test) => {
        setSelectedTest(testData); // Set the selected test for deletion
        setOpenDelete(true); // Open the delete modal
    };


    const { delete: deleteTest, reset, clearErrors } = useForm();

    const handleDelete = (id: number) => {
        deleteTest(route('test.destroy', id), {
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
            {/* Header with Create Button */}
            <div className="flex justify-between items-center mb-4">
                <h2 className="text-xl font-semibold text-foreground">
                    {t('tests')}
                </h2>
                {isAdmin && (
                    <CreateTestModal folder_id={folder.id} />
                )}
            </div>

            {/* Cards Grid */}
            <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                {folder.tests.map((item, index) => {
                    const globalIndex = index + 1;
                    const isActive = item.active == 1;

                    return (
                        <div
                            key={item.id}
                            className="group flex flex-col justify-between glass rounded-[22px] p-6 transition-all duration-300 hover:-translate-y-1"
                        >
                            {/* Header */}
                            <div className="mb-4">
                                <div className="flex items-center justify-between mb-2">
                                    <span className="text-[10px] font-bold uppercase tracking-widest text-brand">
                                        #{globalIndex}
                                    </span>
                                    <div className="flex gap-1">
                                        {isActive ? (
                                            <span className="inline-flex items-center rounded-full bg-emerald-500/12 px-2 py-0.5 text-[10px] font-bold text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200">
                                                {t('active')}
                                            </span>
                                        ) : (
                                            <span className="inline-flex items-center rounded-full bg-muted px-2 py-0.5 text-[10px] font-bold text-foreground border border-glass-edge">
                                                {t('inactive')}
                                            </span>
                                        )}
                                        {isAdmin && (
                                            <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-bold ${item.open == 1 ? 'bg-indigo-500/12 text-brand' : 'bg-amber-500/15 text-amber-800 dark:bg-amber-400/15 dark:text-amber-200'}`}>
                                                {item.open == 1 ? t('open') : t('closed') ?? 'Closed'}
                                            </span>
                                        )}
                                    </div>
                                </div>
                                <h3 className="line-clamp-1 text-lg font-bold text-foreground group-hover:text-brand transition-colors">
                                    {item.name}
                                </h3>
                                {item.purpose === 'mock' && (
                                    <span className="mt-1 inline-flex rounded-full bg-indigo-500/12 px-2 py-0.5 text-[10px] font-bold text-brand">
                                        {t('exam_admin.nav.mock_bank')} · {t(`exam_admin.bank.status.${item.bank_status ?? 'draft'}`)}
                                    </span>
                                )}
                            </div>

                            {/* Comment */}
                            <div className="mb-4">
                                <p className="line-clamp-2 text-xs leading-relaxed text-muted-foreground">
                                    {item.comment || t('no_comment')}
                                </p>
                            </div>

                            {/* Types Tags */}
                            <div className="mb-6">
                                <div className="flex flex-wrap gap-1.5">
                                    {item.types.map((i, idx) => (
                                        <Link 
                                            key={idx} 
                                            href={`/test-type/${i.id}`}
                                            className="inline-flex items-center px-2 py-1 rounded-full bg-muted text-[10px] font-semibold text-foreground border border-glass-edge hover:border-ring hover:text-brand transition-all"
                                        >
                                            {i.type?.name}
                                        </Link>
                                    ))}
                                </div>
                            </div>

                            {/* Audio Player */}
                            {item.audio_path && (
                                <div className="mb-6 glass-subtle p-2">
                                    <audio className="w-full h-8" controls>
                                        <source src={`/${item.audio_path}`} type="audio/mpeg" />
                                    </audio>
                                </div>
                            )}

                            {/* Actions */}
                            {isAdmin && (
                                <div className="flex items-center gap-2 pt-2 mt-auto border-t border-divider">
                                    <button
                                        type="button"
                                        onClick={() => handleUpdateClick(item)}
                                        className="px-3 py-2 bg-indigo-500/12 text-brand hover:bg-primary hover:text-primary-foreground rounded-full font-semibold text-xs flex items-center justify-center gap-1.5 flex-1 transition-all cursor-pointer active:scale-95"
                                    >
                                        <PencilIcon className="h-3.5 w-3.5" />
                                        {t('edit')}
                                    </button>

                                    <button
                                        type="button"
                                        onClick={() => handleDeleteClick(item)}
                                        className="p-2 bg-rose-500/12 text-rose-800 dark:bg-rose-400/15 dark:text-rose-200 hover:bg-destructive hover:text-white dark:hover:bg-destructive dark:hover:text-white rounded-full font-semibold text-xs flex items-center justify-center gap-1.5 transition-all cursor-pointer active:scale-95"
                                        title={t('delete')}
                                    >
                                        <TrashIcon className="h-3.5 w-3.5" />
                                    </button>
                                </div>
                            )}
                        </div>
                    );
                })}
            </div>

            {/* Modals */}
            {selectedTest && open && (
                <UpdateTestModal
                    test={selectedTest}
                    open={open}
                    setOpen={setOpen}
                />
            )}

            {selectedTest && openDelete && (
                <DeleteItemModal
                    item={selectedTest}
                    open={openDelete}
                    setOpen={setOpenDelete}
                    onDelete={handleDelete}
                />
            )}
        </div>

    );
};

export default TestTable;
