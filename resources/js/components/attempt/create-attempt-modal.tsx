import { useForm } from '@inertiajs/react';
import React, { FormEventHandler, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';

import { Button } from '@/components/ui/button';
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
import { Mock, Test } from '@/types';

import { FaCirclePlay } from 'react-icons/fa6';

interface AttemptUpdateProps {
    test: Test;
    mock?: Mock;
}

export default function CreateAttemptModal({ test, mock }: AttemptUpdateProps) {
    const { t } = useTranslation();
    const [open, setOpen] = useState(false);
    const audioRef = useRef<HTMLAudioElement | null>(null);

    const { data, setData, post, processing, reset, clearErrors, errors } = useForm<{
        name: string,
        test_id: number,
        mock_id?: number
    }>({
        name: '',
        test_id: test.id,
        mock_id: mock?.id
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        post(route('attempt.store'), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpen(false);
                toast.success(t('created_successfully'));
            },
            onError: (err) => {
                const errorMessage = err?.error || t('create_failed');
                toast.error(errorMessage);
            }
        });
    };

    const handleCheckHeadset = () => {
        if (audioRef.current) {
            audioRef.current.currentTime = 0;
            audioRef.current.play().then(() => {
                toast.success(`✅ ${t('headset_working')}`);
            }).catch((err) => {
                console.error(err);
                toast.error(t('unable_play_sound'));
            });
        }
    };

    const handleStopSound = () => {
        if (audioRef.current) {
            audioRef.current.pause();
            audioRef.current.currentTime = 0;
            toast.info(`🔇 ${t('sound_stopped')}`);
        }
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <button
                    className="flex items-center gap-2 px-6 py-3 bg-glass-subtle text-brand font-bold rounded-full shadow-glass-pill hover:bg-primary hover:text-primary-foreground transition-all duration-300 border border-glass-edge active:scale-95 group/btn"
                >
                    <FaCirclePlay className="w-5 h-5 group-hover/btn:scale-110 transition-transform duration-300" aria-hidden="true" />
                    <span className="tracking-tight">{t('start')}</span>
                </button>
            </DialogTrigger>

            <DialogContent className="max-h-[90vh] overflow-y-auto">
                <DialogTitle>{t('start_with_name', { name: test.name })}</DialogTitle>
                <DialogDescription className="space-y-2 text-foreground/80" asChild>
                    <div className="space-y-2 text-foreground/80 text-sm">
                        <p>{t('begin_test_warning')}</p>
                        <p>{t('test_start_warning')}</p>
                        <p>{t('do_not_refresh')}</p>
                        <p>{t('good_luck')}</p>
                    </div>
                </DialogDescription>

                {/* Check headset buttons */}
                <div className="mt-4 flex gap-2">
                    <Button type="button" variant="outline" onClick={handleCheckHeadset}>
                        🎧 {t('check_headset')}
                    </Button>
                    <Button type="button" variant="destructive" onClick={handleStopSound}>
                        🔇 {t('stop')}
                    </Button>
                    {/* Hidden audio tag */}
                    <audio ref={audioRef} src="/audio/test-sound.mp3" preload="auto" />
                </div>

                <form onSubmit={submit} className="space-y-4">
                    {mock && (
                        <div className="space-y-2">
                            <label htmlFor="name" className="text-sm font-medium text-foreground/80">
                                {t('attempt_name')} <span className="text-rose-700 dark:text-rose-300">*</span>
                            </label>
                            <input
                                id="name"
                                type="text"
                                value={data.name}
                                onChange={(e) => setData('name', e.target.value)}
                                placeholder={t('enter_attempt_name')}
                                required
                                className={`w-full rounded-xl border bg-glass-subtle text-foreground py-2 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-ring ${
                                    errors.name 
                                    ? 'border-rose-500 focus:ring-rose-500' 
                                    : 'border-input'
                                }`}
                            />
                            {errors.name && (
                                <p className="text-xs text-rose-700 dark:text-rose-300">{errors.name}</p>
                            )}
                            {!data.name && (
                                <p className="text-xs text-warning">{t('name_is_required_for_mock')}</p>
                            )}
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
                            {t('start')}
                        </Button>
                    </DialogFooter>

                </form>
            </DialogContent>
        </Dialog>
    );
}
