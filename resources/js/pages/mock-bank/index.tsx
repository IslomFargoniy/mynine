import { EmptyState, fmtDateTime, inputClass, ModuleBadge, PageHeader, Panel, selectClass } from '@/components/exam-admin/shared';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import AppLayout from '@/layouts/app-layout';
import { cn } from '@/lib/utils';
import { type BreadcrumbItem } from '@/types';
import { Head, Link, router, useForm, usePage } from '@inertiajs/react';
import { AlertTriangle, Archive, ArrowRightLeft, CheckCircle2, Library, Pencil, Plus, RotateCcw, Search } from 'lucide-react';
import { FormEventHandler, useState } from 'react';
import { useTranslation } from 'react-i18next';

interface BankModuleRow {
    id: number;
    type: string;
    parts_count: number;
    issues: string[];
    ready: boolean;
    uses: number;
    last_used_at: string | null;
    recently_used: boolean;
}

interface BankTestRow {
    id: number;
    name: string;
    folder: { id: number; name: string } | null;
    bank_status: 'draft' | 'ready' | 'archived';
    created_at: string;
    modules: BankModuleRow[];
    can_be_ready: boolean;
}

interface PageProps {
    tests: BankTestRow[];
    folders: { id: number; name: string }[];
    reuseDays: number;
    filters: { status?: string | null; search?: string };
    [key: string]: unknown;
}

const statusTone: Record<string, string> = {
    draft: 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-300',
    ready: 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300',
    archived: 'bg-rose-50 text-rose-700 dark:bg-rose-950/40 dark:text-rose-300',
};

function CreateMockTestDialog({ folders }: { folders: PageProps['folders'] }) {
    const { t } = useTranslation();
    const [open, setOpen] = useState(false);
    const { data, setData, post, processing, errors, reset } = useForm({
        folder_id: folders[0]?.id ?? '',
        name: '',
        comment: '',
        active: 1,
        purpose: 'mock',
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        post(route('test.store'), {
            preserveScroll: true,
            onSuccess: () => {
                reset('name', 'comment');
                setOpen(false);
            },
        });
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <Button className="rounded-xl bg-indigo-600 text-xs font-bold text-white hover:bg-indigo-700">
                    <Plus className="h-4 w-4" />
                    {t('exam_admin.bank.create_test')}
                </Button>
            </DialogTrigger>
            <DialogContent className="rounded-2xl sm:max-w-md">
                <DialogHeader>
                    <DialogTitle>{t('exam_admin.bank.create_test')}</DialogTitle>
                    <DialogDescription className="text-xs">{t('exam_admin.bank.create_test_hint')}</DialogDescription>
                </DialogHeader>
                <form onSubmit={submit} className="space-y-3">
                    <div>
                        <Label htmlFor="folder_id">{t('exam_admin.bank.folder')}</Label>
                        <select id="folder_id" className={`${selectClass} w-full`} value={data.folder_id} onChange={(e) => setData('folder_id', Number(e.target.value))}>
                            {folders.map((f) => (
                                <option key={f.id} value={f.id}>
                                    {f.name}
                                </option>
                            ))}
                        </select>
                        <InputError message={errors.folder_id} />
                    </div>
                    <div>
                        <Label htmlFor="test_name">{t('exam_admin.common.name')}</Label>
                        <input id="test_name" className={inputClass} value={data.name} onChange={(e) => setData('name', e.target.value)} />
                        <InputError message={errors.name} />
                    </div>
                    <div>
                        <Label htmlFor="test_comment">{t('exam_admin.common.comment')}</Label>
                        <input id="test_comment" className={inputClass} value={data.comment} onChange={(e) => setData('comment', e.target.value)} />
                    </div>
                    <DialogFooter>
                        <Button type="submit" disabled={processing || !data.name || !data.folder_id} className="rounded-xl bg-indigo-600 text-white hover:bg-indigo-700">
                            {t('exam_admin.common.save')}
                        </Button>
                    </DialogFooter>
                </form>
            </DialogContent>
        </Dialog>
    );
}

export default function MockBankIndex() {
    const { tests, folders, reuseDays, filters } = usePage<PageProps>().props;
    const { t } = useTranslation();
    const [search, setSearch] = useState(filters.search ?? '');

    const breadcrumbs: BreadcrumbItem[] = [{ title: t('exam_admin.nav.mock_bank'), href: route('mock-bank.index') }];

    const applyFilters = (next: Partial<PageProps['filters']>) => {
        router.get(route('mock-bank.index'), { status: filters.status ?? undefined, search, ...next }, { preserveState: true, replace: true });
    };

    const setStatus = (test: BankTestRow, status: string) => {
        router.post(route('mock-bank.status', test.id), { status }, { preserveScroll: true });
    };

    const toPractice = (test: BankTestRow) => {
        if (!confirm(t('exam_admin.bank.to_practice_confirm', { name: test.name }))) return;
        router.post(route('mock-bank.to-practice', test.id), {}, { preserveScroll: true });
    };

    const issueLabel = (issue: string) => {
        const [code, count] = issue.split(':');
        return t(`exam_admin.bank.issue.${code}`, { count: Number(count ?? 0) });
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('exam_admin.nav.mock_bank')} />
            <div className="mx-auto max-w-7xl space-y-5 p-4 md:p-6">
                <PageHeader
                    icon={<Library className="h-5 w-5" />}
                    title={t('exam_admin.nav.mock_bank')}
                    description={t('exam_admin.bank.description', { days: reuseDays })}
                    actions={<CreateMockTestDialog folders={folders} />}
                />

                <Panel className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                    <div className="flex flex-wrap gap-1.5">
                        {['', 'draft', 'ready', 'archived'].map((status) => (
                            <button
                                key={status || 'all'}
                                type="button"
                                onClick={() => applyFilters({ status: status || undefined })}
                                className={cn(
                                    'rounded-xl px-3 py-1.5 text-xs font-bold transition-colors',
                                    (filters.status ?? '') === status
                                        ? 'bg-indigo-600 text-white'
                                        : 'bg-gray-100 text-gray-600 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300',
                                )}
                            >
                                {status ? t(`exam_admin.bank.status.${status}`) : t('exam_admin.common.all')}
                            </button>
                        ))}
                    </div>
                    <form
                        className="relative w-full sm:w-72"
                        onSubmit={(e) => {
                            e.preventDefault();
                            applyFilters({});
                        }}
                    >
                        <Search className="absolute top-1/2 left-3 h-3.5 w-3.5 -translate-y-1/2 text-gray-400" />
                        <input className={`${inputClass} pl-8`} value={search} onChange={(e) => setSearch(e.target.value)} placeholder={t('exam_admin.common.search')} />
                    </form>
                </Panel>

                {tests.length === 0 ? (
                    <EmptyState>{t('exam_admin.bank.empty')}</EmptyState>
                ) : (
                    <div className="space-y-3">
                        {tests.map((test) => (
                            <Panel key={test.id} className="space-y-3">
                                <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
                                    <div>
                                        <div className="flex flex-wrap items-center gap-2">
                                            <h3 className="text-base font-black text-gray-900 dark:text-white">{test.name}</h3>
                                            <span className={cn('rounded-full px-2.5 py-0.5 text-[10px] font-bold', statusTone[test.bank_status])}>
                                                {t(`exam_admin.bank.status.${test.bank_status}`)}
                                            </span>
                                        </div>
                                        <p className="mt-0.5 text-[11px] text-gray-500">
                                            {test.folder?.name} · #{test.id} · {fmtDateTime(test.created_at, 'dd.MM.yyyy')}
                                        </p>
                                    </div>
                                    <div className="flex flex-wrap items-center gap-1.5">
                                        <Link
                                            href={
                                                test.folder
                                                    ? route('folder.show', { folder: test.folder.id, search: test.name })
                                                    : route('test.show', test.id)
                                            }
                                            className="inline-flex items-center gap-1 rounded-xl bg-gray-100 px-3 py-1.5 text-xs font-bold text-gray-700 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-200"
                                        >
                                            <Pencil className="h-3.5 w-3.5" />
                                            {t('exam_admin.bank.edit_content')}
                                        </Link>
                                        {test.bank_status !== 'ready' && (
                                            <Button
                                                size="sm"
                                                disabled={!test.can_be_ready}
                                                title={!test.can_be_ready ? t('exam_admin.bank.not_ready_hint') : undefined}
                                                onClick={() => setStatus(test, 'ready')}
                                                className="rounded-xl bg-emerald-600 text-xs font-bold text-white hover:bg-emerald-700"
                                            >
                                                <CheckCircle2 className="h-3.5 w-3.5" />
                                                {t('exam_admin.bank.mark_ready')}
                                            </Button>
                                        )}
                                        {test.bank_status !== 'draft' && (
                                            <Button size="sm" variant="outline" onClick={() => setStatus(test, 'draft')} className="rounded-xl text-xs">
                                                <RotateCcw className="h-3.5 w-3.5" />
                                                {t('exam_admin.bank.to_draft')}
                                            </Button>
                                        )}
                                        {test.bank_status !== 'archived' && (
                                            <Button size="sm" variant="outline" onClick={() => setStatus(test, 'archived')} className="rounded-xl text-xs">
                                                <Archive className="h-3.5 w-3.5" />
                                                {t('exam_admin.bank.archive')}
                                            </Button>
                                        )}
                                        <Button size="sm" variant="outline" onClick={() => toPractice(test)} className="rounded-xl text-xs">
                                            <ArrowRightLeft className="h-3.5 w-3.5" />
                                            {t('exam_admin.bank.to_practice')}
                                        </Button>
                                    </div>
                                </div>

                                <div className="grid gap-2 md:grid-cols-3">
                                    {test.modules.length === 0 && <p className="text-xs text-gray-400">{t('exam_admin.bank.no_modules')}</p>}
                                    {test.modules.map((module) => (
                                        <Link
                                            key={module.id}
                                            href={route('test-type.show', module.id)}
                                            title={t('exam_admin.bank.edit_module')}
                                            className={cn(
                                                'block rounded-xl border p-3 text-xs transition hover:border-indigo-300 hover:shadow-sm',
                                                module.parts_count === 0
                                                    ? 'border-dashed border-gray-200 opacity-60 dark:border-gray-800'
                                                    : module.ready
                                                      ? 'border-emerald-200 dark:border-emerald-900/50'
                                                      : 'border-amber-200 dark:border-amber-900/50',
                                            )}
                                        >
                                            <div className="flex items-center justify-between">
                                                <ModuleBadge type={module.type} />
                                                {module.parts_count > 0 &&
                                                    (module.ready ? (
                                                        <span className="flex items-center gap-1 text-[10px] font-bold text-emerald-600">
                                                            <CheckCircle2 className="h-3 w-3" /> {t('exam_admin.bank.module_ready')}
                                                        </span>
                                                    ) : (
                                                        <span className="flex items-center gap-1 text-[10px] font-bold text-amber-600">
                                                            <AlertTriangle className="h-3 w-3" /> {t('exam_admin.bank.module_not_ready')}
                                                        </span>
                                                    ))}
                                            </div>
                                            <div className="mt-2 space-y-0.5 text-[11px] text-gray-500">
                                                <div>
                                                    {t('exam_admin.bank.parts')}: <b>{module.parts_count}</b> · {t('exam_admin.bank.used')}: <b>{module.uses}</b>
                                                </div>
                                                <div className={module.recently_used ? 'font-semibold text-amber-600' : ''}>
                                                    {t('exam_admin.bank.last_used')}: <b>{fmtDateTime(module.last_used_at, 'dd.MM.yyyy')}</b>
                                                </div>
                                                {module.parts_count > 0 &&
                                                    module.issues.map((issue) => (
                                                        <div key={issue} className="text-rose-600">
                                                            • {issueLabel(issue)}
                                                        </div>
                                                    ))}
                                            </div>
                                            <div className="mt-2 text-[10px] font-bold text-indigo-600">{t('exam_admin.bank.edit_module')} →</div>
                                        </Link>
                                    ))}
                                </div>
                            </Panel>
                        ))}
                    </div>
                )}
            </div>
        </AppLayout>
    );
}
