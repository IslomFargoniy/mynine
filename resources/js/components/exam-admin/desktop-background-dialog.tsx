import { fmtDateTime } from '@/components/exam-admin/shared';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { router, useForm } from '@inertiajs/react';
import { ImageIcon, Trash2, Upload } from 'lucide-react';
import { FormEventHandler, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';

export interface DesktopBackground {
    sha256: string;
    updatedAt: string | null;
}

/** Background picture of the exam app's code screen (every PC downloads it with its config). */
export function DesktopBackgroundDialog({
    background,
    open,
    onOpenChange,
}: {
    background: DesktopBackground | null;
    open: boolean;
    onOpenChange: (open: boolean) => void;
}) {
    const { t } = useTranslation();
    const { data, setData, post, processing, errors, reset, clearErrors } = useForm<{ image: File | null }>({ image: null });
    const [preview, setPreview] = useState<string | null>(null);

    useEffect(() => {
        if (!data.image) {
            setPreview(null);
            return;
        }
        const url = URL.createObjectURL(data.image);
        setPreview(url);
        return () => URL.revokeObjectURL(url);
    }, [data.image]);

    const close = (next: boolean) => {
        onOpenChange(next);
        if (!next) {
            reset();
            clearErrors();
        }
    };

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        post(route('desktop.settings.background.update'), {
            forceFormData: true,
            preserveScroll: true,
            onSuccess: () => reset(),
        });
    };

    const remove = () =>
        router.delete(route('desktop.settings.background.destroy'), {
            preserveScroll: true,
        });

    const current = background ? `${route('desktop.settings.background')}?v=${background.sha256.slice(0, 12)}` : null;
    const shown = preview ?? current;

    return (
        <Dialog open={open} onOpenChange={close}>
            <DialogContent className="sm:max-w-xl">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2">
                        <ImageIcon className="h-5 w-5 text-brand" />
                        {t('exam_admin.background.title')}
                    </DialogTitle>
                    <DialogDescription className="text-xs text-foreground">{t('exam_admin.background.description')}</DialogDescription>
                </DialogHeader>

                <form onSubmit={submit} className="space-y-4">
                    <div className="relative aspect-video w-full overflow-hidden rounded-[14px] border border-glass-edge bg-muted">
                        {shown ? (
                            <img src={shown} alt="" className="h-full w-full object-cover" />
                        ) : (
                            <div className="flex h-full items-center justify-center text-xs text-muted-foreground">{t('exam_admin.background.none')}</div>
                        )}
                        {/* The code card sits in the middle of the screen. */}
                        <div className="absolute top-1/2 left-1/2 h-[38%] w-[34%] -translate-x-1/2 -translate-y-1/2 rounded-sm bg-white/90 shadow" />
                    </div>

                    {background && !preview && (
                        <p className="text-xs text-muted-foreground">{t('exam_admin.background.updated', { date: fmtDateTime(background.updatedAt) })}</p>
                    )}

                    <div>
                        <input
                            type="file"
                            accept="image/jpeg,image/png,image/webp"
                            onChange={(e) => setData('image', e.target.files?.[0] ?? null)}
                            className="block w-full text-xs file:mr-3 file:rounded-full file:border-0 file:bg-indigo-500/15 file:px-4 file:py-2 file:text-xs file:font-bold file:text-brand"
                        />
                        <p className="mt-1 text-[11px] text-muted-foreground">{t('exam_admin.background.hint')}</p>
                        <InputError message={errors.image} />
                    </div>

                    <div className="flex items-center justify-between gap-2">
                        {background ? (
                            <Button type="button" variant="outline" size="sm" onClick={remove}>
                                <Trash2 className="h-4 w-4" />
                                {t('exam_admin.background.remove')}
                            </Button>
                        ) : (
                            <span />
                        )}
                        <Button type="submit" size="sm" disabled={!data.image || processing}>
                            <Upload className="h-4 w-4" />
                            {t('exam_admin.background.save')}
                        </Button>
                    </div>
                </form>
            </DialogContent>
        </Dialog>
    );
}
