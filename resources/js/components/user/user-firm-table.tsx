import React, { useState } from 'react';
import { TrashIcon } from 'lucide-react';
import { useForm } from '@inertiajs/react';
import { useTranslation } from 'react-i18next';
import { Firm, User, UserFirm } from '@/types';
import DeleteItemModal from '@/components/delete-item-modal';
import { toast } from 'sonner';
import CreateUserFirmModal from '@/components/user/create-user-firm-modal';


type UserFirmTableProps = {
    user: User;
    firms: Firm[];
};

const UserFirmTable = ({ user, firms }: UserFirmTableProps) => {

    const { t } = useTranslation();  // Using the translation hook
    const [openDelete, setOpenDelete] = useState(false);
    const [selectedUserFirm, setSelectedUserFirm] = useState<UserFirm | null>(null);


    const handleDeleteClick = (user_firm: UserFirm) => {
        setSelectedUserFirm(user_firm);
        setOpenDelete(true);
    };
    const { delete: deleteUserFirm, reset, clearErrors } = useForm();

    const handleDelete = (id: number) => {

        deleteUserFirm(`/user_firm/${id}`, {
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
        <div>

            <h3 className={'capitalize text-center py-2'}>{t('user_firm')}</h3>

            {/* Table */}
            <div className="overflow-x-auto">
                <table className="border-collapse w-full text-sm text-left text-foreground">
                    <thead className="bg-gray-100 dark:bg-gray-700">
                    <tr>
                        <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">{t('n')}</td>
                        <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">{t('firm')}</td>
                        <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">{t('user')}</td>
                        <th className="border border-gray-300 dark:border-gray-600 px-4 py-2">
                            <CreateUserFirmModal user={user} firms={firms} />
                        </th>
                    </tr>
                    </thead>
                    <tbody className="bg-white dark:bg-gray-800">
                    {user.user_firms?.map((item, index) => {
                        return (
                            <tr key={item.id} className="hover:bg-gray-50 dark:hover:bg-gray-700">
                                <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">{index + 1}</td>
                                <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">{item.firm?.name}</td>
                                <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">{item.user?.name}</td>
                                <td className="border border-gray-300 dark:border-gray-600 px-4 py-2">

                                    <div className="inline-flex shadow-sm">
                                        <button
                                            onClick={() => handleDeleteClick(item)}
                                            className="bg-red-500 px-3 py-2 text-sm font-medium text-white border border-red-600 hover:bg-red-600 focus:z-10 rounded"
                                        >
                                            <TrashIcon className="w-4 h-4" />
                                        </button>
                                    </div>

                                </td>
                            </tr>
                        );
                    })}
                    </tbody>

                    {/* Pass selected user to the DeleteUserModal */}
                    {selectedUserFirm && openDelete && (
                        <DeleteItemModal
                            item={selectedUserFirm}
                            open={openDelete}  // Assuming you have a separate state for openDelete
                            setOpen={setOpenDelete}  // Or you can manage this in its own state
                            onDelete={handleDelete} // Handle deletion
                        />
                    )}

                </table>

            </div>
        </div>
    );
};

export default UserFirmTable;
