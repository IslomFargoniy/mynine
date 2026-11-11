import { useForm, usePage } from '@inertiajs/react';
import React, { FormEventHandler, useRef, useEffect } from 'react';
import { useTranslation } from 'react-i18next';

import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { toast } from 'sonner';

import {
    Dialog,
    DialogClose,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle
} from '@/components/ui/dialog';
import { Auth, Role, User } from '@/types';
import { Select, SelectContent, SelectItem, SelectTrigger } from '@/components/ui/select';

interface UpdateUserModalProps {
    roles: Role[];
    user: User;
    open: boolean;
    setOpen: (open: boolean) => void;
}

export default function UpdateUserModal({ roles, user, open, setOpen }: UpdateUserModalProps) {
    const { t } = useTranslation();
    const nameInput = useRef<HTMLInputElement>(null);

    const { data, setData, put, processing, reset, errors, clearErrors } = useForm({
        name: user.name || '',
        phone: user.phone || '',
        role: (user.roles ?? [])[0]?.name || '',
        email: user.email || '',
        password: user.password || '',
        create_test_limit: user.create_test_limit ?? 5
    });

    const { auth } = usePage().props as unknown as { auth?: Auth };

    const isAdmin = auth?.user?.roles?.some(role => role.name === 'Admin');

    useEffect(() => {
        setData({
            name: user.name || '',
            phone: user.phone || '',
            role: (user.roles ?? [])[0]?.name || '',
            email: user.email || '',
            password: '',
            create_test_limit: user.create_test_limit ?? 5
        });
    }, [user, setData]);

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        put(`/user/${user.id}`, {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpen(false); // 🔒 CLOSE MODAL HERE
                toast.success(t('updated_successfully'));
            },
            onError: (err) => {
                nameInput.current?.focus();
                // Display a friendly error message if available
                const errorMessage = err?.error || t('create_failed'); // Use fallback error message
                toast.error(errorMessage); // Display error message
            }
        });

    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>

            <DialogContent className="sm:max-w-lg w-full">
                <DialogHeader className="space-y-1 pb-2 border-b border-divider">
                    <DialogTitle className="text-lg font-bold text-foreground">
                        {t('modal.update_user_title')}
                    </DialogTitle>
                    <DialogDescription className="text-xs text-muted-foreground">
                        {t('modal.update_user_desc')}
                    </DialogDescription>
                </DialogHeader>

                <form onSubmit={submit} className="space-y-4">
                    <div>
                        <Label htmlFor="name">{t('name')}</Label>
                        <Input
                            id="name"
                            ref={nameInput}
                            value={data.name}
                            onChange={(e) => setData('name', e.target.value)}
                        />
                        <InputError message={errors.name} />
                    </div>

                    <div>
                        <Label htmlFor="phone">{t('phone')}</Label>
                        <Input
                            id="phone"
                            type={'number'}
                            value={data.phone}
                            onChange={(e) => setData('phone', e.target.value)}
                        />
                        <InputError message={errors.phone} />
                    </div>


                    {isAdmin && (

                        <div>
                            <Label htmlFor="test_id">{t('role')}</Label>
                            <Select
                                value={String(data.role || '')}
                                onValueChange={(value) => setData('role', value)}
                            >
                                <SelectTrigger className="w-full">
                                   <span>
                                        {data.role
                                            ? roles.find((t) => t.name === data.role)?.name
                                            : t('select_test')}
                                    </span>
                                </SelectTrigger>

                                <SelectContent>
                                    {roles.map((role) => (
                                        <SelectItem key={role.id} value={String(role.name)}>
                                            {role.name}
                                        </SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>

                            <InputError message={errors.role} />
                        </div>

                    )}


                    <div>
                        <Label htmlFor="email">{t('email')}</Label>
                        <Input
                            id="email"
                            value={data.email}
                            onChange={(e) => setData('email', e.target.value)}
                        />
                        <InputError message={errors.email} />
                    </div>

                    <div>
                        <Label htmlFor="password">{t('password')}</Label>
                        <Input
                            id="password"
                            type="number"
                            inputMode="numeric"
                            onChange={(e) => setData('password', e.target.value)}
                        />
                        <InputError message={errors.password} />
                    </div>

                    {isAdmin && (
                        <div>
                            <Label htmlFor="create_test_limit">{t('user_form.test_limit')}</Label>
                            <Input
                                id="create_test_limit"
                                type="number"
                                min="0"
                                value={data.create_test_limit}
                                onChange={(e) => setData('create_test_limit', parseInt(e.target.value) || 0)}
                            />
                            <InputError message={errors.create_test_limit as string} />
                        </div>
                    )}


                    <DialogFooter className="gap-2">
                        <DialogClose asChild>
                            <Button
                                variant="secondary"
                                onClick={() => {
                                    reset();
                                    clearErrors();
                                }}
                            >
                                {t('cancel')}
                            </Button>
                        </DialogClose>

                        <Button
                            type="submit"
                            disabled={processing}
                        >
                            {t('save')}
                        </Button>
                    </DialogFooter>

                </form>
            </DialogContent>
        </Dialog>

    );
}
