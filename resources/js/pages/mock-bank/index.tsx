import { EmptyState, fmtDateTime, inputClass, ModuleBadge, PageHeader, Panel, selectClass, useAutoRefresh } from '@/components/exam-admin/shared';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import AppLayout from '@/layouts/app-layout';
import { cn } from '@/lib/utils';
import { type BreadcrumbItem } from '@/types';
import { Head, Link, router, useForm, usePage } from '@inertiajs/react';
import { AlertTriangle, Archive, ArrowRightLeft, CheckCircle2, FileUp, Info, Library, Loader2, Pencil, Plus, RotateCcw, Search, XCircle } from 'lucide-react';
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

type ImportStatus = 'queued' | 'running' | 'done' | 'failed';

interface ImportModuleRow {
    type: string;
    status: ImportStatus;
    message: string | null;
    warnings: string[];
    parts: number | null;
    questions: number | null;
}

interface ImportRow {
    id: number;
    status: ImportStatus;
    created_at: string | null;
    finished_at: string | null;
    modules: ImportModuleRow[];
}

interface BankTestRow {
    id: number;
    name: string;
    folder: { id: number; name: string } | null;
    bank_status: 'draft' | 'ready' | 'archived';
    created_at: string;
    modules: BankModuleRow[];
    edit_module_id: number | null;
    can_be_ready: boolean;
    import: ImportRow | null;
}

interface PageProps {
    tests: BankTestRow[];
    folders: { id: number; name: string }[];
    reuseDays: number;
    filters: { status?: string | null; search?: string };
    [key: string]: unknown;
}

const statusTone: Record<string, string> = {
    draft: 'bg-muted text-foreground/80',
    ready: 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300',
    archived: 'bg-rose-50 text-rose-700 dark:bg-rose-950/40 dark:text-rose-300',
};

function CreateMockTestDialog() {
    const { t } = useTranslation();
    const [open, setOpen] = useState(false);
    // Mock Bank tests have no folder.
    const { data, setData, post, processing, errors, reset } = useForm({
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
                        <Label htmlFor="test_name">{t('exam_admin.common.name')}</Label>
                        <input id="test_name" className={inputClass} value={data.name} onChange={(e) => setData('name', e.target.value)} />
                        <InputError message={errors.name} />
                    </div>
                    <div>
                        <Label htmlFor="test_comment">{t('exam_admin.common.comment')}</Label>
                        <input id="test_comment" className={inputClass} value={data.comment} onChange={(e) => setData('comment', e.target.value)} />
                    </div>
                    <DialogFooter>
                        <Button type="submit" disabled={processing || !data.name} className="rounded-xl bg-indigo-600 text-white hover:bg-indigo-700">
                            {t('exam_admin.common.save')}
                        </Button>
                    </DialogFooter>
                </form>
            </DialogContent>
        </Dialog>
    );
}

const importTone: Record<ImportStatus, string> = {
    queued: 'bg-muted text-foreground/80',
    running: 'bg-indigo-50 text-indigo-700 dark:bg-indigo-950/40 dark:text-indigo-300',
    done: 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300',
    failed: 'bg-rose-50 text-rose-700 dark:bg-rose-950/40 dark:text-rose-300',
};

function ImportStatusIcon({ status }: { status: ImportStatus }) {
    if (status === 'done') return <CheckCircle2 className="h-3.5 w-3.5" />;
    if (status === 'failed') return <XCircle className="h-3.5 w-3.5" />;
    return <Loader2 className={cn('h-3.5 w-3.5', status === 'running' && 'animate-spin')} />;
}

function FileField({ id, label, hint, accept, error, onChange }: { id: string; label: string; hint?: string; accept: string; error?: string; onChange: (file: File | null) => void }) {
    return (
        <div>
            <Label htmlFor={id} className="text-xs font-bold">
                {label}
            </Label>
            <input id={id} type="file" accept={accept} className={cn(inputClass, 'mt-1 cursor-pointer py-1.5 file:mr-3 file:rounded-lg file:border-0 file:bg-indigo-50 file:px-2 file:py-1 file:text-xs file:font-bold file:text-indigo-700')} onChange={(e) => onChange(e.target.files?.[0] ?? null)} />
            {hint && <p className="mt-1 text-[11px] text-muted-foreground">{hint}</p>}
            <InputError message={error} />
        </div>
    );
}

function ImportPdfDialog({ test }: { test: BankTestRow }) {
    const { t } = useTranslation();
    const [open, setOpen] = useState(false);
    const { data, setData, post, processing, errors, reset, clearErrors, progress } = useForm<{
        listening_file: File | null;
        reading_file: File | null;
        writing_file: File | null;
        answers_file: File | null;
        listening_audio: File | null;
        replace: boolean;
    }>({ listening_file: null, reading_file: null, writing_file: null, answers_file: null, listening_audio: null, replace: false });

    const running = test.import?.status === 'queued' || test.import?.status === 'running';
    const filled = test.modules.filter((m) => ['Listening', 'Reading', 'Writing'].includes(m.type) && m.parts_count > 0).map((m) => m.type);
    const hasFile = Boolean(data.listening_file || data.reading_file || data.writing_file);
    const docs = '.pdf,.docx,.txt';

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        post(route('mock-bank.import', test.id), {
            forceFormData: true,
            preserveScroll: true,
            onSuccess: () => {
                reset();
                setOpen(false);
            },
        });
    };

    return (
        <Dialog
            open={open}
            onOpenChange={(next) => {
                setOpen(next);
                if (!next) clearErrors();
            }}
        >
            <DialogTrigger asChild>
                <Button size="sm" disabled={running} className="rounded-xl bg-indigo-600 text-xs font-bold text-white hover:bg-indigo-700">
                    <FileUp className="h-3.5 w-3.5" />
                    {t('exam_admin.bank.import.button')}
                </Button>
            </DialogTrigger>
            <DialogContent className="max-h-[90vh] overflow-y-auto rounded-2xl sm:max-w-lg">
                <DialogHeader>
                    <DialogTitle>
                        {t('exam_admin.bank.import.title')} — {test.name}
                    </DialogTitle>
                    <DialogDescription className="text-xs">{t('exam_admin.bank.import.description')}</DialogDescription>
                </DialogHeader>
                <form onSubmit={submit} className="space-y-3">
                    <FileField id={`listening_file_${test.id}`} label={t('exam_admin.bank.import.listening_file')} hint={t('exam_admin.bank.import.file_types')} accept={docs} error={errors.listening_file} onChange={(f) => setData('listening_file', f)} />
                    <FileField id={`reading_file_${test.id}`} label={t('exam_admin.bank.import.reading_file')} accept={docs} error={errors.reading_file} onChange={(f) => setData('reading_file', f)} />
                    <FileField id={`writing_file_${test.id}`} label={t('exam_admin.bank.import.writing_file')} hint={t('exam_admin.bank.import.writing_hint')} accept={docs} error={errors.writing_file} onChange={(f) => setData('writing_file', f)} />
                    <FileField id={`answers_file_${test.id}`} label={t('exam_admin.bank.import.answers_file')} hint={t('exam_admin.bank.import.answers_hint')} accept={docs} error={errors.answers_file} onChange={(f) => setData('answers_file', f)} />
                    <FileField id={`listening_audio_${test.id}`} label={t('exam_admin.bank.import.listening_audio')} accept="audio/*,.mp3" error={errors.listening_audio} onChange={(f) => setData('listening_audio', f)} />

                    <div className="rounded-xl border border-border p-3">
                        <div className="flex items-center gap-2">
                            <Checkbox id={`replace_${test.id}`} checked={data.replace} onCheckedChange={(v) => setData('replace', v === true)} />
                            <Label htmlFor={`replace_${test.id}`} className="text-xs font-bold">
                                {t('exam_admin.bank.import.replace')}
                            </Label>
                        </div>
                        <p className="mt-1 text-[11px] text-muted-foreground">{t('exam_admin.bank.import.replace_hint')}</p>
                        {filled.length > 0 && (
                            <p className="mt-1 flex items-center gap-1 text-[11px] font-semibold text-amber-600 dark:text-amber-400">
                                <AlertTriangle className="h-3 w-3" />
                                {t('exam_admin.bank.import.has_content', { modules: filled.join(', ') })}
                            </p>
                        )}
                    </div>

                    <p className="flex gap-1.5 rounded-xl bg-amber-50 p-2.5 text-[11px] text-amber-800 dark:bg-amber-950/40 dark:text-amber-200">
                        <Info className="mt-0.5 h-3.5 w-3.5 shrink-0" />
                        {t('exam_admin.bank.import.writing_note')}
                    </p>

                    {progress && (
                        <div className="h-1.5 overflow-hidden rounded-full bg-muted">
                            <div className="h-full bg-indigo-600 transition-all" style={{ width: `${progress.percentage ?? 0}%` }} />
                        </div>
                    )}

                    <DialogFooter>
                        <Button
                            type="submit"
                            disabled={processing || !hasFile}
                            title={!hasFile ? t('exam_admin.bank.import.need_file') : undefined}
                            className="rounded-xl bg-indigo-600 text-white hover:bg-indigo-700"
                        >
                            {processing && <Loader2 className="h-4 w-4 animate-spin" />}
                            {t('exam_admin.bank.import.submit')}
                        </Button>
                    </DialogFooter>
                </form>
            </DialogContent>
        </Dialog>
    );
}

function ImportStatusPanel({ data }: { data: ImportRow }) {
    const { t } = useTranslation();

    return (
        <div className="rounded-xl border border-border bg-gray-50/60 p-3 text-xs dark:bg-gray-900/40">
            <div className="flex flex-wrap items-center gap-2">
                <span className="font-bold text-foreground/80">{t('exam_admin.bank.import.heading')}</span>
                <span className={cn('inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-bold', importTone[data.status])}>
                    <ImportStatusIcon status={data.status} />
                    {t(`exam_admin.bank.import.status.${data.status}`)}
                </span>
                <span className="text-[11px] text-muted-foreground">{fmtDateTime(data.finished_at ?? data.created_at)}</span>
            </div>
            <div className="mt-2 space-y-2">
                {data.modules.map((module) => (
                    <div key={module.type}>
                        <div className="flex flex-wrap items-center gap-2">
                            <ModuleBadge type={module.type} />
                            <span className={cn('inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-bold', importTone[module.status])}>
                                <ImportStatusIcon status={module.status} />
                                {t(`exam_admin.bank.import.status.${module.status}`)}
                            </span>
                            {module.status === 'done' && (
                                <span className="text-[11px] text-muted-foreground">{t('exam_admin.bank.import.summary', { parts: module.parts ?? 0, questions: module.questions ?? 0 })}</span>
                            )}
                        </div>
                        {module.message && <p className="mt-1 text-[11px] font-semibold text-rose-600 dark:text-rose-400">{module.message}</p>}
                        {module.warnings.length > 0 && (
                            <ul className="mt-1 space-y-0.5 text-[11px] text-amber-700 dark:text-amber-300">
                                {module.warnings.map((warning, i) => (
                                    <li key={i}>• {warning}</li>
                                ))}
                            </ul>
                        )}
                    </div>
                ))}
            </div>
            {data.status === 'done' && <p className="mt-2 text-[11px] text-muted-foreground">{t('exam_admin.bank.import.review_hint')}</p>}
        </div>
    );
}

function MoveToPracticeDialog({ test, folders }: { test: BankTestRow; folders: PageProps['folders'] }) {
    const { t } = useTranslation();
    const [open, setOpen] = useState(false);
    const { data, setData, post, processing, errors, clearErrors } = useForm<{ folder_id: number | '' }>({
        folder_id: test.folder?.id ?? '',
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        post(route('mock-bank.to-practice', test.id), {
            preserveScroll: true,
            onSuccess: () => setOpen(false),
        });
    };

    return (
        <Dialog
            open={open}
            onOpenChange={(next) => {
                setOpen(next);
                if (!next) clearErrors();
            }}
        >
            <DialogTrigger asChild>
                <Button size="sm" variant="outline" className="rounded-xl text-xs">
                    <ArrowRightLeft className="h-3.5 w-3.5" />
                    {t('exam_admin.bank.to_practice')}
                </Button>
            </DialogTrigger>
            <DialogContent className="rounded-2xl sm:max-w-md">
                <DialogHeader>
                    <DialogTitle>{t('exam_admin.bank.move.title', { name: test.name })}</DialogTitle>
                    <DialogDescription className="text-xs">{t('exam_admin.bank.move.description')}</DialogDescription>
                </DialogHeader>
                <form onSubmit={submit} className="space-y-3">
                    <div>
                        <Label htmlFor={`move_folder_${test.id}`}>{t('exam_admin.bank.folder')}</Label>
                        {folders.length === 0 ? (
                            <p className="mt-1 text-xs text-amber-600 dark:text-amber-400">{t('exam_admin.bank.move.no_folders')}</p>
                        ) : (
                            <select
                                id={`move_folder_${test.id}`}
                                required
                                className={`${selectClass} w-full`}
                                value={data.folder_id}
                                onChange={(e) => setData('folder_id', e.target.value ? Number(e.target.value) : '')}
                            >
                                <option value="">{t('exam_admin.bank.move.choose')}</option>
                                {folders.map((f) => (
                                    <option key={f.id} value={f.id}>
                                        {f.name}
                                    </option>
                                ))}
                            </select>
                        )}
                        <InputError message={errors.folder_id} />
                    </div>
                    <DialogFooter>
                        <Button type="submit" disabled={processing || !data.folder_id} className="rounded-xl bg-indigo-600 text-white hover:bg-indigo-700">
                            {t('exam_admin.bank.move.submit')}
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

    // Imports run in the queue: refresh the cards while one is in progress.
    const importing = tests.some((test) => test.import?.status === 'queued' || test.import?.status === 'running');
    useAutoRefresh(['tests'], 5000, importing);

    const breadcrumbs: BreadcrumbItem[] = [{ title: t('exam_admin.nav.mock_bank'), href: route('mock-bank.index') }];

    const applyFilters = (next: Partial<PageProps['filters']>) => {
        router.get(route('mock-bank.index'), { status: filters.status ?? undefined, search, ...next }, { preserveState: true, replace: true });
    };

    const setStatus = (test: BankTestRow, status: string) => {
        router.post(route('mock-bank.status', test.id), { status }, { preserveScroll: true });
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
                    actions={<CreateMockTestDialog />}
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
                                        : 'bg-muted text-foreground/80 hover:bg-gray-200 dark:hover:bg-gray-700',
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
                        <Search className="absolute top-1/2 left-3 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
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
                                            <h3 className="text-base font-black text-foreground">{test.name}</h3>
                                            <span className={cn('rounded-full px-2.5 py-0.5 text-[10px] font-bold', statusTone[test.bank_status])}>
                                                {t(`exam_admin.bank.status.${test.bank_status}`)}
                                            </span>
                                        </div>
                                        <p className="mt-0.5 text-[11px] text-muted-foreground">
                                            #{test.id} · {fmtDateTime(test.created_at, 'dd.MM.yyyy')}
                                        </p>
                                    </div>
                                    <div className="flex flex-wrap items-center gap-1.5">
                                        <ImportPdfDialog test={test} />
                                        <Link
                                            href={test.edit_module_id ? route('test-type.show', test.edit_module_id) : route('test.show', test.id)}
                                            className="inline-flex items-center gap-1 rounded-xl bg-muted px-3 py-1.5 text-xs font-bold text-foreground/80 hover:bg-gray-200 dark:hover:bg-gray-700"
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
                                        <MoveToPracticeDialog test={test} folders={folders} />
                                    </div>
                                </div>

                                {test.import && <ImportStatusPanel data={test.import} />}

                                <div className="grid gap-2 md:grid-cols-3">
                                    {test.modules.length === 0 && <p className="text-xs text-muted-foreground">{t('exam_admin.bank.no_modules')}</p>}
                                    {test.modules.map((module) => (
                                        <Link
                                            key={module.id}
                                            href={route('test-type.show', module.id)}
                                            title={t('exam_admin.bank.edit_module')}
                                            className={cn(
                                                'block rounded-xl border p-3 text-xs transition hover:border-indigo-300 hover:shadow-sm',
                                                module.parts_count === 0
                                                    ? 'border-dashed border-border opacity-60'
                                                    : module.ready
                                                      ? 'border-emerald-200 dark:border-emerald-900/50'
                                                      : 'border-amber-200 dark:border-amber-900/50',
                                            )}
                                        >
                                            <div className="flex items-center justify-between">
                                                <ModuleBadge type={module.type} />
                                                {module.parts_count > 0 &&
                                                    (module.ready ? (
                                                        <span className="flex items-center gap-1 text-[10px] font-bold text-emerald-600 dark:text-emerald-400">
                                                            <CheckCircle2 className="h-3 w-3" /> {t('exam_admin.bank.module_ready')}
                                                        </span>
                                                    ) : (
                                                        <span className="flex items-center gap-1 text-[10px] font-bold text-amber-600 dark:text-amber-400">
                                                            <AlertTriangle className="h-3 w-3" /> {t('exam_admin.bank.module_not_ready')}
                                                        </span>
                                                    ))}
                                            </div>
                                            <div className="mt-2 space-y-0.5 text-[11px] text-muted-foreground">
                                                <div>
                                                    {t('exam_admin.bank.parts')}: <b>{module.parts_count}</b> · {t('exam_admin.bank.used')}: <b>{module.uses}</b>
                                                </div>
                                                <div className={module.recently_used ? 'font-semibold text-amber-600 dark:text-amber-400' : ''}>
                                                    {t('exam_admin.bank.last_used')}: <b>{fmtDateTime(module.last_used_at, 'dd.MM.yyyy')}</b>
                                                </div>
                                                {module.parts_count > 0 &&
                                                    module.issues.map((issue) => (
                                                        <div key={issue} className="text-rose-600 dark:text-rose-400">
                                                            • {issueLabel(issue)}
                                                        </div>
                                                    ))}
                                            </div>
                                            <div className="mt-2 text-[10px] font-bold text-indigo-600 dark:text-indigo-400">{t('exam_admin.bank.edit_module')} →</div>
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
