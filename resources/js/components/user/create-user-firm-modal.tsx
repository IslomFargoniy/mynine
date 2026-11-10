import React from 'react';
import { User, Firm } from '@/types';

interface CreateUserFirmModalProps {
    user: User;
    firms: Firm[];
}

const CreateUserFirmModal = (_props: CreateUserFirmModalProps) => {
    return (
        <button className="btn-glass-primary px-3 py-1 rounded-full text-xs font-semibold">
            + Add Firm
        </button>
    );
};

export default CreateUserFirmModal;
