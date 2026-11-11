import React, { useState } from 'react';
import { PencilIcon, TrashIcon } from 'lucide-react';
import { format } from 'date-fns';
import { IconAction } from '@/components/ui/icon-action';
import { Table, TableBody, TableCell, TableEmpty, TableHead, TableHeader, TableRow, TruncatedText } from '@/components/ui/table';
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
            <div className="glass-strong overflow-hidden rounded-[22px]">
                <Table>
                    <TableHeader>
                        <TableRow>
                            <TableHead className="w-10 text-right">{t('n')}</TableHead>
                            <TableHead>{t('name')}</TableHead>
                            <TableHead>{t('phone')}</TableHead>
                            <TableHead className="hidden lg:table-cell">{t('telegram_id')}</TableHead>
                            <TableHead className="hidden lg:table-cell">{t('created_at')}</TableHead>
                            <TableHead className="w-px">
                                <span className="sr-only">{t('attempts_table.actions')}</span>
                            </TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {user.data.length === 0 && <TableEmpty colSpan={6}>{t('common.no_data')}</TableEmpty>}
                        {user.data.map((item, index) => {
                            const globalIndex = (user.current_page - 1) * user.per_page + index + 1;
                            const roles = item.roles?.map((role) => role.name).join(', ');
                            const created = item.created_at ? format(new Date(item.created_at), 'dd.MM.yy HH:mm') : '—';
                            return (
                                <TableRow key={item.id}>
                                    <TableCell className="text-right font-mono text-muted-foreground tabular-nums max-md:hidden">{globalIndex}</TableCell>
                                    <TableCell>
                                        <div className="flex min-w-0 flex-wrap items-center gap-1.5">
                                            <Link href={`/user/${item.id}`} className="min-w-0 font-bold text-foreground transition-colors hover:text-brand">
                                                <TruncatedText className="max-w-[14rem]">{item.name}</TruncatedText>
                                            </Link>
                                            {roles && (
                                                <span className="rounded-full border border-glass-edge bg-muted px-1.5 py-0.5 text-[10px] font-bold text-muted-foreground">
                                                    {roles}
                                                </span>
                                            )}
                                        </div>
                                        {item.email && <TruncatedText className="max-w-[16rem] text-[11px] text-muted-foreground">{item.email}</TruncatedText>}
                                    </TableCell>
                                    <TableCell label={t('phone')} className="text-foreground/80">
                                        <div className="font-medium whitespace-nowrap tabular-nums">{item.phone || '—'}</div>
                                        {item.username && <TruncatedText className="max-w-[10rem] text-[11px] text-muted-foreground">@{item.username}</TruncatedText>}
                                        {item.telegram_id && (
                                            <div className="text-[11px] text-muted-foreground lg:hidden">
                                                {t('telegram_id')}: {item.telegram_id}
                                            </div>
                                        )}
                                    </TableCell>
                                    <TableCell className="hidden font-mono text-[11px] text-foreground/80 lg:table-cell">{item.telegram_id || '—'}</TableCell>
                                    <TableCell className="hidden text-[11px] whitespace-nowrap text-muted-foreground tabular-nums lg:table-cell">{created}</TableCell>
                                    <TableCell className="text-right">
                                        <div className="flex items-center justify-end gap-0.5">
                                            <IconAction label={t('edit')} tone="brand" onClick={() => handleUpdateClick(item)}>
                                                <PencilIcon />
                                            </IconAction>
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
                <div className="mt-4 flex flex-col items-center justify-between gap-3 text-sm text-foreground/80 sm:flex-row">
                    <div>
                        {t('showing', {
                            from: user.from,
                            to: user.to,
                            total: user.total
                        })}
                    </div>
                    <div className="flex flex-wrap justify-center gap-1">
                        {user.links.map((link, index) => (
                            <Link
                                key={index}
                                href={`${link.url ?? '?'}&search=${searchData.search}&per_page=${searchData.per_page}`}
                                className={`px-3 py-1 rounded-full text-sm transition ${
                                    link.active
                                        ? 'btn-glass-primary'
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

export default UserTable;
