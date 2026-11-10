import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Part } from '@/types';
import { useForm } from '@inertiajs/react';
import { toast } from 'sonner';
import { Edit, TrashIcon } from 'lucide-react';
import DeleteItemModal from '@/components/delete-item-modal';
import PartModal from '@/components/part/part-modal';

interface PartUpdateProps {
    part: Part;
    partIndex: number;
    testType?: any;
}

export default function PartComponent({ part, testType }: PartUpdateProps) {
    const { t } = useTranslation();
    const [openDelete, setOpenDelete] = useState(false);
    const [openEditModal, setOpenEditModal] = useState(false);

    const { delete: deletePart, reset, clearErrors } = useForm();

    const handleDelete = () => {
        deletePart(route('part.destroy', part.id), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpenDelete(false);
                toast.success(t('deleted_successfully'));
            },
            onError: (err) => {
                const errorMessage = err?.error || t('delete_failed');
                toast.error(errorMessage);
            },
        });
    };

    return (
        <div className="flex items-center gap-1">
            {/* Edit part button opens full-screen PartModal */}
            <button
                type="button"
                onClick={() => setOpenEditModal(true)}
                className="p-1.5 rounded-full hover:bg-indigo-500/12 text-brand transition-colors cursor-pointer"
                title={`${t('edit')} ${t('part')}`}
            >
                <Edit className="w-4 h-4" />
            </button>

            {/* Delete part */}
            <button
                type="button"
                onClick={() => setOpenDelete(true)}
                className="p-1.5 rounded-full hover:bg-rose-500/12 text-rose-700 dark:text-rose-300 transition-colors cursor-pointer"
                title={`${t('delete')} ${t('part')}`}
            >
                <TrashIcon className="w-4 h-4" />
            </button>

            {/* Modals */}
            {openEditModal && (
                <PartModal
                    testType={part.test_type || testType}
                    part={part}
                    open={openEditModal}
                    setOpen={setOpenEditModal}
                />
            )}

            {openDelete && (
                <DeleteItemModal
                    item={part}
                    open={openDelete}
                    setOpen={setOpenDelete}
                    onDelete={handleDelete}
                />
            )}
        </div>
    );
}
