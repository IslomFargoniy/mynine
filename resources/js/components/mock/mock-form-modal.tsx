import MockFormFields, { type MockFormData } from '@/components/mock/mock-form';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogTitle } from '@/components/ui/dialog';
import axios from 'axios';
import { GraduationCap, Loader2 } from 'lucide-react';
import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';

interface Props {
    open: boolean;
    onOpenChange: (open: boolean) => void;
    /** Edit this mock; create a new one when empty. */
    mockId?: number | null;
}

/**
 * Mock create / edit in a modal. The form data (ready bank modules, auto pick) comes from the same routes as the
 * full page, as JSON. Create goes on to the new mock's page (its codes); edit stays where it was opened.
 */
export default function MockFormModal({ open, onOpenChange, mockId }: Props) {
    const { t } = useTranslation();
    const [data, setData] = useState<MockFormData | null>(null);
    const [failed, setFailed] = useState(false);
    const isEdit = !!mockId;

    useEffect(() => {
        if (!open) return;
        let cancelled = false;
        setData(null);
        setFailed(false);
        axios
            .get<MockFormData>(isEdit ? route('mock.edit', mockId) : route('mock.create'), { headers: { Accept: 'application/json' } })
            .then((r) => !cancelled && setData(r.data))
            .catch(() => !cancelled && setFailed(true));
        return () => {
            cancelled = true;
        };
    }, [open, mockId, isEdit]);

    return (
        <Dialog open={open} onOpenChange={onOpenChange}>
            <DialogContent className="max-h-[94vh] gap-3 overflow-y-auto p-5 sm:max-w-5xl">
                <DialogTitle className="flex items-center gap-2">
                    <GraduationCap className="h-5 w-5 text-brand" />
                    {isEdit ? t('exam_admin.mock_form.edit_title') : t('exam_admin.mock_form.create_title')}
                </DialogTitle>
                <DialogDescription>{t('exam_admin.mock_form.description')}</DialogDescription>
                {data ? (
                    <MockFormFields
                        key={mockId ?? 'new'}
                        {...data}
                        stay={isEdit}
                        onSaved={() => onOpenChange(false)}
                        secondaryAction={
                            <Button type="button" variant="outline" className="rounded-full" onClick={() => onOpenChange(false)}>
                                {t('cancel')}
                            </Button>
                        }
                    />
                ) : failed ? (
                    <p className="py-8 text-center text-sm text-rose-700 dark:text-rose-300">{t('error_occurred')}</p>
                ) : (
                    <div className="flex justify-center py-12">
                        <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
                    </div>
                )}
            </DialogContent>
        </Dialog>
    );
}
