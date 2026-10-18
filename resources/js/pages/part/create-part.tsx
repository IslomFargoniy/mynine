import AppLayout from '@/layouts/app-layout';
import { Head, usePage, useForm, router } from '@inertiajs/react';
import { type BreadcrumbItem, TestType } from '@/types';
import { FormEventHandler, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { toast } from 'sonner';
import TextareaEditor from '@/components/textarea-editor';
import { route } from 'ziggy-js';

export default function CreatePart() {
    const { testType } = usePage<{ testType: TestType }>().props;
    const { t } = useTranslation();  // Using the translation hook


    // const logContent = () => {
    //     if (editorRef.current) {
    //         console.log(editorRef.current.getContent());
    //     }
    // };

    const folder = testType?.test?.folder;
    const test = testType?.test;
    const folderName = folder?.name || t('folder') || 'Jild';
    const testName = test?.name || t('test') || 'Test';
    const typeName = testType?.type?.name || 'Module';

    const breadcrumbs: BreadcrumbItem[] = [
        {
            title: t('folders') || 'Jildlar',
            href: route('folder.index'),
        },
        ...(folder?.id
            ? [
                  {
                      title: folderName,
                      href: route('folder.show', folder.id),
                  },
              ]
            : []),
        ...(test?.id
            ? [
                  {
                      title: testName,
                      href: folder?.id ? route('folder.show', folder.id) : route('folder.index'),
                  },
              ]
            : []),
        ...(testType?.id
            ? [
                  {
                      title: typeName,
                      href: route('test-type.show', testType.id),
                  },
              ]
            : []),
        {
            title: t('create_part') || 'Part yaratish',
            href: '#',
        },
    ];

    const nameInput = useRef<HTMLInputElement>(null);

    const { data, setData, post, processing, reset, errors, clearErrors } = useForm<{
        test_type_id: number;
        name: string;
        textarea: string;
        minute: number | null;
        comment: string;
    }>({
        test_type_id: testType?.id,
        name: '',
        textarea: '',
        minute: null,
        comment: ''
    });


    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        post(route('part.store'), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                toast.success(t('created_successfully'));
            },
            onError: (err) => {
                console.log(err);
                nameInput.current?.focus();
                // Display a friendly error message if available
                const errorMessage = err?.error || t('create_failed'); // Use fallback error message
                toast.error(errorMessage); // Display error message
            }
        });
    };


    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={`${t('create_part') || 'Part yaratish'} - ${testName}`} />
            <div className="flex h-full flex-1 flex-col gap-4 rounded-xl p-4 overflow-y-auto">
                <div className="flex items-center justify-between pb-2 border-b border-gray-100 dark:border-gray-800">
                    <h1 className="text-base font-bold text-gray-900 dark:text-gray-100">
                        {t('create_part') || 'Part yaratish'}
                    </h1>
                </div>

                {/* Table */}
                <div className="overflow-x-auto">

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
                            <Label htmlFor="comment">{t('comment')}</Label>
                            <Input
                                id="comment"
                                ref={nameInput}
                                value={data.comment}
                                onChange={(e) => setData('comment', e.target.value)}
                            />
                            <InputError message={errors.comment} />
                        </div>


                        {/*<div>*/}
                        {/*    <Label htmlFor="minute">{t('minute')}</Label>*/}
                        {/*    <Input*/}
                        {/*        type="number"*/}
                        {/*        id="minute"*/}
                        {/*        value={data.minute ?? ''}*/}
                        {/*        onChange={(e) => setData('minute', Number(e.target.value))}*/}
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
                                className="bg-blue-600 text-white hover:bg-blue-700
                   dark:bg-blue-500 dark:hover:bg-blue-600
                   disabled:opacity-50"
                            >
                                {t('save')}
                            </Button>

                            {/* Secondary Cancel */}
                            <Button
                                type="button"
                                onClick={() => router.visit(route('test-type.show', testType?.id))}
                                className="bg-gray-100 text-gray-800 hover:bg-gray-200
                   dark:bg-gray-800 dark:text-gray-200 dark:hover:bg-gray-700"
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
