import React, { useState } from 'react';
import { TrashIcon } from 'lucide-react';
import { useForm } from '@inertiajs/react';
import { useTranslation } from 'react-i18next';
import { Firm, User, UserFirm } from '@/types';
import DeleteItemModal from '@/components/delete-item-modal';
import { toast } from 'sonner';
import CreateUserFirmModal from '@/components/user/create-user-firm-modal';
import { IconAction } from '@/components/ui/icon-action';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow, TruncatedText } from '@/components/ui/table';


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

            <div className="glass-strong overflow-hidden rounded-[22px]">
                <Table stacked={false}>
                    <TableHeader>
                        <TableRow>
                            <TableHead className="w-10 text-right">{t('n')}</TableHead>
                            <TableHead>{t('firm')}</TableHead>
                            <TableHead>{t('user')}</TableHead>
                            <TableHead className="w-px text-right">
                                <CreateUserFirmModal user={user} firms={firms} />
                            </TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {user.user_firms?.map((item, index) => (
                            <TableRow key={item.id}>
                                <TableCell className="text-right text-muted-foreground tabular-nums">{index + 1}</TableCell>
                                <TableCell>
                                    <TruncatedText>{item.firm?.name}</TruncatedText>
                                </TableCell>
                                <TableCell>
                                    <TruncatedText>{item.user?.name}</TruncatedText>
                                </TableCell>
                                <TableCell className="text-right">
                                    <IconAction label={t('delete')} tone="danger" onClick={() => handleDeleteClick(item)}>
                                        <TrashIcon />
                                    </IconAction>
                                </TableCell>
                            </TableRow>
                        ))}
                    </TableBody>
                </Table>
            </div>

            {selectedUserFirm && openDelete && (
                <DeleteItemModal item={selectedUserFirm} open={openDelete} setOpen={setOpenDelete} onDelete={handleDelete} />
            )}
        </div>
    );
};

export default UserFirmTable;
