import MockFormFields, { type MockFormData } from '@/components/mock/mock-form';
import { PageHeader } from '@/components/exam-admin/shared';
import AppLayout from '@/layouts/app-layout';
import { type BreadcrumbItem } from '@/types';
import { Head, Link, usePage } from '@inertiajs/react';
import { ArrowLeft, GraduationCap } from 'lucide-react';
import { useTranslation } from 'react-i18next';

/** Direct link to /mock/create or /mock/{id}/edit; the app itself opens the same form in a modal (MockFormModal). */
export default function MockForm() {
    const props = usePage<MockFormData & Record<string, unknown>>().props;
    const { mock } = props;
    const { t } = useTranslation();
    const isEdit = !!mock;

    const breadcrumbs: BreadcrumbItem[] = [
        { title: t('mock'), href: route('mock.index') },
        { title: isEdit ? mock.name : t('exam_admin.mock_form.create_title'), href: '#' },
    ];

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={isEdit ? mock.name : t('exam_admin.mock_form.create_title')} />
            <div className="mx-auto w-full max-w-7xl p-4 md:p-6 space-y-5">
                <PageHeader
                    icon={<GraduationCap className="h-5 w-5" />}
                    title={isEdit ? t('exam_admin.mock_form.edit_title') : t('exam_admin.mock_form.create_title')}
                    description={t('exam_admin.mock_form.description')}
                    actions={
                        <Link
                            href={isEdit ? route('mock.show', mock.id) : route('mock.index')}
                            className="inline-flex items-center gap-1.5 rounded-full border border-glass-edge bg-glass-subtle px-4 py-2 text-xs font-bold text-foreground hover:bg-accent"
                        >
                            <ArrowLeft className="h-4 w-4" />
                            {t('exam_admin.common.back')}
                        </Link>
                    }
                />
                <MockFormFields
                    mock={mock}
                    modules={props.modules}
                    autoPick={props.autoPick}
                    reuseDays={props.reuseDays}
                    modulesLocked={props.modulesLocked}
                />
            </div>
        </AppLayout>
    );
}
