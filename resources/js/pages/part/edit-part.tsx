import AppLayout from '@/layouts/app-layout';
import { Head, usePage, useForm, router } from '@inertiajs/react';
import { type BreadcrumbItem, Part } from '@/types';
import { FormEventHandler, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { toast } from 'sonner';
import TextareaEditor from '@/components/textarea-editor';
import { route } from 'ziggy-js';
import { contentBreadcrumbs } from '@/lib/content-breadcrumbs';

export default function EditPart() {
    const { part } = usePage<{ part: Part }>().props;
    const { t } = useTranslation();

    const nameInput = useRef<HTMLInputElement>(null);

    const test = part?.test_type?.test;
    const testType = part?.test_type;
    const testName = test?.name || t('test');
    const typeName = testType?.type?.name || 'Module';

    const breadcrumbs: BreadcrumbItem[] = [
        ...contentBreadcrumbs(test, t),
        ...(testType?.id
            ? [
                  {
                      title: typeName,
                      href: route('test-type.show', testType.id),
                  },
              ]
            : []),
        {
            title: part.name || t('edit_part'),
            href: route('part.show', part.id),
        },
    ];

    const { data, setData, post, processing, reset, errors, clearErrors } = useForm<{
        name: string;
        textarea: string;
        minute: number | null;
        comment: string;
    }>({
        name: part.name,
        textarea: part.textarea,
        minute: part.minute || null,
        comment: part.comment,
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        post(route('part.update', part.id), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                toast.success(t('updated_successfully')); // ✅ correct message
            },
            onError: (err) => {
                console.error(err);
                nameInput.current?.focus();
                toast.error(err?.error || t('update_failed'));
            },
        });
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={`${part.name || t('edit_part')} - ${testName}`} />
            <div className="flex h-full flex-1 flex-col gap-4 rounded-xl p-4 overflow-y-auto">
                <div className="flex items-center justify-between pb-2 border-b border-divider">
                    <h1 className="text-base font-bold text-foreground">
                        {part.name || t('edit_part')}
                    </h1>
                </div>

                {/* Form */}
                <div className="glass-strong overflow-x-auto rounded-[22px] p-4 sm:p-5">
                    <form onSubmit={submit} className="space-y-4">
                        {/* Name */}
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

                        {/* Comment */}
                        <div>
                            <Label htmlFor="comment">{t('comment')}</Label>
                            <Input
                                id="comment"
                                value={data.comment}
                                onChange={(e) => setData('comment', e.target.value)}
                            />
                            <InputError message={errors.comment} />
                        </div>

                        {/* Minute */}
                        {/*<div>*/}
                        {/*    <Label htmlFor="minute">{t('minute')}</Label>*/}
                        {/*    <Input*/}
                        {/*        type="number"*/}
                        {/*        id="minute"*/}
                        {/*        value={data.minute ?? ''} // null yoki undefined bo‘lsa, bo‘sh string chiqadi*/}
                        {/*        onChange={(e) =>*/}
                        {/*            setData('minute', e.target.value === '' ? null : Number(e.target.value))*/}
                        {/*        }*/}
                        {/*    />*/}
                        {/*    <InputError message={errors.minute} />*/}
                        {/*</div>*/}

                        <TextareaEditor
                            value={data.textarea}
                            onChange={(content) => setData('textarea', content)}
                            height={600}
                        />

                        <div className="flex gap-3">
                            {/* Primary Save */}
                            <Button
                                type="submit"
                                disabled={processing}
                                className="disabled:opacity-50"
                            >
                                {t('save')}
                            </Button>

                            {/* Secondary Cancel */}
                            <Button
                                type="button"
                                onClick={() => router.visit(route('test-type.show', part.test_type_id))}
                                variant="outline"
                            >
                                {t('cancel')}
                            </Button>
                        </div>


                    </form>
                </div>
            </div>
        </AppLayout>
    );
}
