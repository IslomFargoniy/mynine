import { fmtDateTime, inputClass } from '@/components/exam-admin/shared';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { cn } from '@/lib/utils';
import { type SharedData } from '@/types';
import { useForm, usePage } from '@inertiajs/react';
import { CheckCircle2, KeyRound } from 'lucide-react';
import { FormEventHandler, useState } from 'react';
import { useTranslation } from 'react-i18next';

export interface CenterPasswordStatus {
    set: boolean;
    updatedAt: string | null;
}

/** "Center password: set / not set" chip; warning style when missing (PCs cannot register without it). */
export function CenterPasswordChip({ status, onClick }: { status: CenterPasswordStatus; onClick?: () => void }) {
    const { t } = useTranslation();

    return (
        <button
            type="button"
            onClick={onClick}
            className={cn(
                'inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-[11px] font-bold transition-colors',
                status.set
                    ? 'border-emerald-500/25 bg-emerald-500/12 text-emerald-800 hover:bg-emerald-500/20 dark:text-emerald-200'
                    : 'border-amber-500/30 bg-amber-500/15 text-amber-800 hover:bg-amber-500/25 dark:text-amber-200',
            )}
        >
            <KeyRound className="h-3.5 w-3.5" />
            {status.set ? t('exam_admin.settings.chip_set') : t('exam_admin.settings.chip_missing')}
        </button>
    );
}

/** Center password form (registering a PC, leaving the locked exam screen, the app's admin menu). */
export function CenterPasswordDialog({ status, open, onOpenChange }: { status: CenterPasswordStatus; open: boolean; onOpenChange: (open: boolean) => void }) {
    const { t } = useTranslation();
    const { flash } = usePage<SharedData>().props;
    const [saved, setSaved] = useState(false);
    const { data, setData, post, processing, errors, reset, clearErrors } = useForm({ password: '', password_confirmation: '' });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        setSaved(false);
        post(route('desktop.settings.exit-password'), {
            preserveScroll: true,
            preserveState: true,
            onSuccess: () => {
                reset();
                setSaved(true);
            },
        });
    };

    const generalError = (errors as Record<string, string>).error;

    return (
        <Dialog
            open={open}
            onOpenChange={(next) => {
                onOpenChange(next);
                if (!next) {
                    reset();
                    clearErrors();
                    setSaved(false);
                }
            }}
        >
            <DialogContent className="sm:max-w-md">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2">
                        <KeyRound className="h-5 w-5 text-brand" />
                        {t('exam_admin.settings.exit_password')}
                    </DialogTitle>
                    <DialogDescription className="text-xs text-foreground">{t('exam_admin.settings.uses')}</DialogDescription>
                </DialogHeader>

                {/* autoComplete="off" + non-credential names: browsers should not offer to save it as a login. */}
                <form onSubmit={submit} className="space-y-4" autoComplete="off">
                    <p className={cn('text-xs', status.set ? 'text-muted-foreground' : 'font-semibold text-amber-700 dark:text-amber-300')}>
                        {status.set
                            ? t('exam_admin.settings.exit_password_set', { date: fmtDateTime(status.updatedAt) })
                            : t('exam_admin.settings.exit_password_missing')}
                    </p>

                    {saved && flash?.success && (
                        <p role="status" className="flex items-center gap-1.5 rounded-[14px] bg-emerald-500/12 px-3 py-2 text-xs font-semibold text-emerald-800 dark:text-emerald-200">
                            <CheckCircle2 className="h-4 w-4 shrink-0" />
                            {t(flash.success)}
                        </p>
                    )}
                    {generalError && <InputError message={generalError} />}

                    <div>
                        <Label htmlFor="center-password">{t('exam_admin.settings.new_password')}</Label>
                        <input
                            id="center-password"
                            name="center_password_new"
                            type="password"
                            autoComplete="new-password"
                            className={inputClass}
                            value={data.password}
                            onChange={(e) => setData('password', e.target.value)}
                        />
                        <InputError message={errors.password} />
                    </div>
                    <div>
                        <Label htmlFor="center-password-confirmation">{t('exam_admin.settings.confirm_password')}</Label>
                        <input
                            id="center-password-confirmation"
                            name="center_password_new_confirmation"
                            type="password"
                            autoComplete="new-password"
                            className={inputClass}
                            value={data.password_confirmation}
                            onChange={(e) => setData('password_confirmation', e.target.value)}
                        />
                    </div>
                    <p className="text-[11px] text-muted-foreground">{t('exam_admin.settings.hint')}</p>
                    <div className="flex justify-end">
                        <Button type="submit" disabled={processing || data.password.length < 6} className="rounded-full text-xs font-bold">
                            {t('exam_admin.common.save')}
                        </Button>
                    </div>
                </form>
            </DialogContent>
        </Dialog>
    );
}
