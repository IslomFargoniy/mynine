import React, { useState } from 'react';
import { PencilIcon, TrashIcon } from 'lucide-react';
import UpdateUserModal from '@/components/user/update-user-modal';
import DeleteItemModal from '@/components/delete-item-modal';
import { Link, useForm, usePage } from '@inertiajs/react';
import { useTranslation } from 'react-i18next';
import { User, type UserPaginate, SearchData, Role, Auth } from '@/types';
import { toast } from 'sonner';


interface UserTableProps extends UserPaginate {
    roles: Role[];
    searchData: SearchData;
}

const UserTable = ({ roles, searchData, ...user }: UserTableProps) => {

    const { t } = useTranslation();  // Using the translation hook
    const [open, setOpen] = useState(false);
    const [openDelete, setOpenDelete] = useState(false);
    const [selectedUser, setSelectedUser] = useState<User | null>(null);


    const { auth } = usePage().props as unknown as { auth?: Auth };

    const isAdmin = auth?.user?.roles?.some(role => role.name === 'Admin');

    const handleUpdateClick = (userData: User) => {
        setSelectedUser(userData); // Set the selected user data
        setOpen(true); // Open the modal
    };

    const handleDeleteClick = (userData: User) => {
        setSelectedUser(userData); // Set the selected user for deletion
        setOpenDelete(true); // Open the delete modal
    };

    const { delete: deleteUser, reset, clearErrors } = useForm();

    const handleDelete = (id: number) => {

        deleteUser(`/user/${id}`, {
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
            {/* Table Container */}
            <div className="overflow-x-auto rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 shadow-xs">
                <table className="w-full text-xs text-left border-collapse">
                    <thead className="bg-gray-50 dark:bg-gray-800/60 text-gray-500 dark:text-gray-400 font-bold uppercase text-[10px] tracking-wider border-b border-gray-200 dark:border-gray-800">
                    <tr>
                        <th className="px-4 py-3 font-bold">{t('n')}</th>
                        <th className="px-4 py-3 font-bold">{t('name')}</th>
                        <th className="px-4 py-3 font-bold">{t('username')}</th>
                        <th className="px-4 py-3 font-bold">{t('telegram_id')}</th>
                        <th className="px-4 py-3 font-bold">{t('phone')}</th>
                        <th className="px-4 py-3 font-bold">{t('email')}</th>
                        <th className="px-4 py-3 font-bold">{t('created_at')}</th>
                        <th className="px-4 py-3 font-bold text-right">
                            {/*<CreateUserModal />*/}
                        </th>
                    </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100 dark:divide-gray-800/60">
                    {user.data.map((item, index) => {
                        const globalIndex = (user.current_page - 1) * user.per_page + index + 1;
                        return (
                            <tr key={item.id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/40 transition-colors">
                                <td className="px-4 py-3 font-semibold text-gray-400 dark:text-gray-500">#{globalIndex}</td>
                                <td className="px-4 py-3 font-bold text-gray-900 dark:text-gray-100">
                                    <Link href={`/user/${item.id}`} className="hover:text-blue-600 dark:hover:text-blue-400 transition-colors">
                                        {item.name}
                                        <span className="ml-1.5 text-[11px] font-medium text-gray-400 dark:text-gray-500">
                                            ( {item.roles?.map((role) => role.name).join(', ')} )
                                        </span>
                                    </Link>
                                </td>
                                <td className="px-4 py-3 text-gray-600 dark:text-gray-300 font-medium">{item.username || '-'}</td>
                                <td className="px-4 py-3 text-gray-600 dark:text-gray-300 font-medium">{item.telegram_id || '-'}</td>
                                <td className="px-4 py-3 text-gray-600 dark:text-gray-300 font-medium">{item.phone || '-'}</td>
                                <td className="px-4 py-3 text-gray-600 dark:text-gray-300 font-medium">{item.email || '-'}</td>
                                <td className="px-4 py-3 text-gray-500 dark:text-gray-400 text-[11px]">
                                    {new Date(item.created_at).toLocaleString('sv-SE').replace('T', ' ')}
                                </td>
                                <td className="px-4 py-3 text-right">
                                    <div className="flex items-center justify-end gap-2">
                                        <button
                                            type="button"
                                            onClick={() => handleUpdateClick(item)}
                                            className="p-2 bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 hover:bg-blue-600 hover:text-white dark:hover:bg-blue-600 dark:hover:text-white rounded-xl font-semibold text-xs transition-all cursor-pointer shadow-xs active:scale-95"
                                            title={t('edit')}
                                        >
                                            <PencilIcon className="w-3.5 h-3.5" />
                                        </button>
                                        {isAdmin && (
                                            <button
                                                type="button"
                                                onClick={() => handleDeleteClick(item)}
                                                className="p-2 bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400 hover:bg-red-600 hover:text-white dark:hover:bg-red-600 dark:hover:text-white rounded-xl font-semibold text-xs transition-all cursor-pointer shadow-xs active:scale-95"
                                                title={t('delete')}
                                            >
                                                <TrashIcon className="w-3.5 h-3.5" />
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

            {/* Modals */}
            {selectedUser && open && (
                <UpdateUserModal
                    roles={roles}
                    user={selectedUser}
                    open={open}
                    setOpen={setOpen}
                />
            )}

            {selectedUser && openDelete && (
                <DeleteItemModal
                    item={selectedUser}
                    open={openDelete}
                    setOpen={setOpenDelete}
                    onDelete={handleDelete}
                />
            )}

                {/* Pagination */}
                <div className="mt-4 flex justify-between items-center text-sm text-gray-600 dark:text-gray-300">
                    <div>
                        {t('showing', {
                            from: user.from,
                            to: user.to,
                            total: user.total
                        })}
                    </div>
                    <div className="flex gap-1">
                        {user.links.map((link, index) => (
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

export default UserTable;
