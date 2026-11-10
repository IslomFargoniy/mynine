import { useForm } from '@inertiajs/react';
import React, { FormEventHandler, useRef, useState } from 'react';
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
    DialogTitle,
    DialogTrigger
} from '@/components/ui/dialog';
import { IoCreate } from 'react-icons/io5';
import { baseButton } from '@/components/ui/baseButton';

export default function CreateUserModal() {
    const { t } = useTranslation();
    const [open, setOpen] = useState(false);

    const nameInput = useRef<HTMLInputElement>(null);

    const { data, setData, post, processing, reset, errors, clearErrors } = useForm({
        name: '',
        phone: '',
        email: '',
        password: '',
        create_test_limit: 5
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        post(route('user.store'), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpen(false); // 🔒 CLOSE MODAL HERE
                toast.success(t('created_successfully'));
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
            <DialogTrigger asChild>
                <button
                    className={`${baseButton} btn-glass-primary rounded-full! hover:brightness-110 focus:ring-ring`}
                >
                    <IoCreate className="w-4 h-4" />
                    {t('create')}
                </button>
            </DialogTrigger>

            <DialogContent>
                <DialogTitle>{t('modal.create_title')}</DialogTitle>
                <DialogDescription>{t('modal.create_description')}</DialogDescription>


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

                    <div>
                        <Label htmlFor="create_test_limit">Test yaratish limiti</Label>
                        <Input
                            id="create_test_limit"
                            type="number"
                            min="0"
                            value={data.create_test_limit}
                            onChange={(e) => setData('create_test_limit', parseInt(e.target.value) || 0)}
                        />
                        <InputError message={errors.create_test_limit as string} />
                    </div>


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
