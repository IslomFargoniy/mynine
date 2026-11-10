import { useForm } from '@inertiajs/react';
import { FormEventHandler, useRef } from 'react';
import { useTranslation } from 'react-i18next';

import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

import HeadingSmall from '@/components/heading-small';

import { Dialog, DialogClose, DialogContent, DialogDescription, DialogFooter, DialogTitle, DialogTrigger } from '@/components/ui/dialog';

export default function DeleteUser() {
    const { t } = useTranslation(); // Use translation hook
    const passwordInput = useRef<HTMLInputElement>(null);
    const { data, setData, delete: destroy, processing, reset, errors, clearErrors } = useForm<Required<{ password: string }>>({ password: '' });

    const deleteUser: FormEventHandler = (e) => {
        e.preventDefault();

        destroy(route('profile.destroy'), {
            preserveScroll: true,
            onSuccess: () => closeModal(),
            onError: () => passwordInput.current?.focus(),
            onFinish: () => reset(),
        });
    };

    const closeModal = () => {
        clearErrors();
        reset();
    };

    return (
        <div className="space-y-6">
            <HeadingSmall title={t('delete_account.title')} description={t('delete_account.description')} />
            <div className="space-y-4 rounded-[18px] border border-rose-500/25 bg-rose-500/12 p-4 dark:bg-rose-400/15">
                <div className="relative space-y-0.5 text-rose-800 dark:text-rose-200">
                    <p className="font-medium">{t('delete_account.warning')}</p>
                    <p className="text-sm">{t('delete_account.warning_description')}</p>
                </div>

                <Dialog>
                    <DialogTrigger asChild>
                        <Button variant="destructive">{t('delete_account.delete_button')}</Button>
                    </DialogTrigger>
                    <DialogContent>
                        <DialogTitle>{t('delete_account.confirmation_title')}</DialogTitle>
                        <DialogDescription>
                            {t('delete_account.confirmation_description')}
                        </DialogDescription>
                        <form className="space-y-6" onSubmit={deleteUser}>
                            <div className="grid gap-2">
                                <Label htmlFor="password" className="sr-only">
                                    {t('delete_account.password_label')}
                                </Label>

                                <Input
                                    id="password"
                                    type="password"
                                    name="password"
                                    ref={passwordInput}
                                    value={data.password}
                                    onChange={(e) => setData('password', e.target.value)}
                                    placeholder={t('delete_account.password_placeholder')}
                                    autoComplete="current-password"
                                />

                                <InputError message={errors.password} />
                            </div>

                            <DialogFooter className="gap-2">
                                <DialogClose asChild>
                                    <Button variant="secondary" onClick={closeModal}>
                                        {t('delete_account.cancel_button')}
                                    </Button>
                                </DialogClose>

                                <Button variant="destructive" disabled={processing} asChild>
                                    <button type="submit">{t('delete_account.delete_button')}</button>
                                </Button>
                            </DialogFooter>
                        </form>
                    </DialogContent>
                </Dialog>
            </div>
        </div>
    );
}
