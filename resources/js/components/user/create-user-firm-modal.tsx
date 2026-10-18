import React from 'react';
import { User, Firm } from '@/types';

interface CreateUserFirmModalProps {
    user: User;
    firms: Firm[];
}

const CreateUserFirmModal = (_props: CreateUserFirmModalProps) => {
    return (
        <button className="bg-blue-500 text-white px-2 py-1 rounded text-xs">
            + Add Firm
        </button>
    );
};

export default CreateUserFirmModal;
