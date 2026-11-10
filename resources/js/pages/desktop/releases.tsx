import { EmptyState, fmtDateTime, inputClass, PageHeader, Panel } from '@/components/exam-admin/shared';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import AppLayout from '@/layouts/app-layout';
import { cn } from '@/lib/utils';
import { type BreadcrumbItem } from '@/types';
import { Head, router, useForm, usePage } from '@inertiajs/react';
import { Package, Power, PowerOff, Trash2, Upload } from 'lucide-react';
import { FormEventHandler } from 'react';
import { useTranslation } from 'react-i18next';

interface ReleaseRow {
    id: number;
    version: string;
    notes: string | null;
    mandatory: boolean;
    is_active: boolean;
    is_latest: boolean;
    file_size: number;
    sha256: string;
    publisher: string | null;
    created_at: string | null;
    devices: string[];
}

interface PageProps {
    releases: ReleaseRow[];
    otherVersions: Record<string, string[]>;
    minVersion: string | null;
    [key: string]: unknown;
}

function fmtSize(bytes: number): string {
    if (bytes >= 1024 * 1024) return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
    if (bytes >= 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${bytes} B`;
}

export default function ReleasesIndex() {
    const { releases, otherVersions, minVersion } = usePage<PageProps>().props;
    const { t } = useTranslation();

    const { data, setData, post, processing, errors, progress, reset } = useForm<{
        version: string;
        notes: string;
        mandatory: boolean;
        is_active: boolean;
        file: File | null;
    }>({ version: '', notes: '', mandatory: false, is_active: true, file: null });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        post(route('desktop.releases.store'), {
            forceFormData: true,
            preserveScroll: true,
            onSuccess: () => reset(),
        });
    };

    const update = (release: ReleaseRow, payload: Partial<ReleaseRow>, confirmText?: string) => {
        if (confirmText && !confirm(confirmText)) return;
        router.patch(route('desktop.releases.update', release.id), payload, { preserveScroll: true });
    };

    const breadcrumbs: BreadcrumbItem[] = [{ title: t('exam_admin.nav.releases'), href: route('desktop.releases.index') }];

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={t('exam_admin.nav.releases')} />
            <div className="mx-auto max-w-6xl space-y-5 p-4 md:p-6">
                <PageHeader
                    icon={<Package className="h-5 w-5" />}
                    title={t('exam_admin.nav.releases')}
                    description={t('exam_admin.releases.description', { min: minVersion ?? '—' })}
                />

                <Panel>
                    <form onSubmit={submit} className="grid gap-3 md:grid-cols-4">
                        <div>
                            <Label htmlFor="version">{t('exam_admin.releases.version')}</Label>
                            <input id="version" placeholder="1.2.0" className={inputClass} value={data.version} onChange={(e) => setData('version', e.target.value)} />
                            <InputError message={errors.version} />
                        </div>
                        <div className="md:col-span-3">
                            <Label htmlFor="file">{t('exam_admin.releases.installer')}</Label>
                            <input
                                id="file"
                                type="file"
                                accept=".exe"
                                className="block w-full text-xs file:mr-3 file:rounded-lg file:border-0 file:bg-indigo-50 file:px-3 file:py-2 file:text-xs file:font-bold file:text-indigo-700"
                                onChange={(e) => setData('file', e.target.files?.[0] ?? null)}
                            />
                            <InputError message={errors.file} />
                        </div>
                        <div className="md:col-span-4">
                            <Label htmlFor="notes">{t('exam_admin.releases.notes')}</Label>
                            <textarea
                                id="notes"
                                rows={2}
                                className="w-full rounded-xl border border-gray-200 bg-white p-2 text-xs dark:border-gray-700 dark:bg-gray-900"
                                value={data.notes}
                                onChange={(e) => setData('notes', e.target.value)}
                            />
                        </div>
                        <div className="flex flex-wrap items-center gap-4 md:col-span-4">
                            <label className="flex items-center gap-2 text-xs font-semibold">
                                <input type="checkbox" className="accent-indigo-600" checked={data.mandatory} onChange={(e) => setData('mandatory', e.target.checked)} />
                                {t('exam_admin.releases.mandatory')}
                            </label>
                            <label className="flex items-center gap-2 text-xs font-semibold">
                                <input type="checkbox" className="accent-indigo-600" checked={data.is_active} onChange={(e) => setData('is_active', e.target.checked)} />
                                {t('exam_admin.releases.active')}
                            </label>
                            {progress && <span className="text-xs text-indigo-600">{progress.percentage}%</span>}
                            <Button type="submit" disabled={processing || !data.file || !data.version} className="ml-auto rounded-xl bg-indigo-600 text-xs font-bold text-white hover:bg-indigo-700">
                                <Upload className="h-4 w-4" />
                                {t('exam_admin.releases.upload')}
                            </Button>
                        </div>
                    </form>
                </Panel>

                {releases.length === 0 ? (
                    <EmptyState>{t('exam_admin.releases.empty')}</EmptyState>
                ) : (
                    <div className="space-y-3">
                        {releases.map((r) => (
                            <Panel key={r.id} className={cn('space-y-2', !r.is_active && 'opacity-60')}>
                                <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                                    <div className="flex flex-wrap items-center gap-2">
                                        <span className="font-mono text-lg font-black">{r.version}</span>
                                        {r.is_latest && (
                                            <span className="rounded-full bg-indigo-600 px-2 py-0.5 text-[10px] font-bold text-white">{t('exam_admin.releases.served')}</span>
                                        )}
                                        {r.mandatory && (
                                            <span className="rounded-full bg-rose-50 px-2 py-0.5 text-[10px] font-bold text-rose-700 dark:bg-rose-950/40 dark:text-rose-300">
                                                {t('exam_admin.releases.mandatory')}
                                            </span>
                                        )}
                                        {!r.is_active && (
                                            <span className="rounded-full bg-gray-100 px-2 py-0.5 text-[10px] font-bold text-gray-600 dark:bg-gray-800">{t('exam_admin.releases.inactive')}</span>
                                        )}
                                    </div>
                                    <div className="flex flex-wrap gap-1.5">
                                        {r.is_active ? (
                                            <Button
                                                size="sm"
                                                variant="outline"
                                                className="h-7 rounded-lg px-2 text-[11px]"
                                                onClick={() =>
                                                    update(r, { is_active: false }, r.is_latest ? t('exam_admin.releases.rollback_confirm', { version: r.version }) : undefined)
                                                }
                                            >
                                                <PowerOff className="h-3.5 w-3.5" />
                                                {r.is_latest ? t('exam_admin.releases.rollback') : t('exam_admin.releases.deactivate')}
                                            </Button>
                                        ) : (
                                            <Button size="sm" variant="outline" className="h-7 rounded-lg px-2 text-[11px]" onClick={() => update(r, { is_active: true })}>
                                                <Power className="h-3.5 w-3.5 text-emerald-600" />
                                                {t('exam_admin.releases.activate')}
                                            </Button>
                                        )}
                                        <Button size="sm" variant="outline" className="h-7 rounded-lg px-2 text-[11px]" onClick={() => update(r, { mandatory: !r.mandatory })}>
                                            {r.mandatory ? t('exam_admin.releases.make_optional') : t('exam_admin.releases.make_mandatory')}
                                        </Button>
                                        <Button
                                            size="sm"
                                            variant="outline"
                                            className="h-7 rounded-lg px-2 text-rose-600"
                                            onClick={() =>
                                                confirm(t('exam_admin.releases.delete_confirm', { version: r.version })) &&
                                                router.delete(route('desktop.releases.destroy', r.id), { preserveScroll: true })
                                            }
                                        >
                                            <Trash2 className="h-3.5 w-3.5" />
                                        </Button>
                                    </div>
                                </div>
                                {r.notes && <p className="text-xs whitespace-pre-wrap text-gray-600 dark:text-gray-300">{r.notes}</p>}
                                <div className="grid gap-1 text-[11px] text-gray-500 md:grid-cols-2">
                                    <div>
                                        {fmtSize(r.file_size)} · {r.publisher ?? '—'} · {fmtDateTime(r.created_at)}
                                    </div>
                                    <div className="truncate font-mono" title={r.sha256}>
                                        SHA-256: {r.sha256}
                                    </div>
                                </div>
                                <div className="text-[11px]">
                                    <b>{t('exam_admin.releases.pcs', { count: r.devices.length })}</b>
                                    {r.devices.length > 0 && <span className="text-gray-500">: {r.devices.join(', ')}</span>}
                                </div>
                            </Panel>
                        ))}
                    </div>
                )}

                {Object.keys(otherVersions).length > 0 && (
                    <Panel className="text-[11px]">
                        <b>{t('exam_admin.releases.other_versions')}</b>
                        {Object.entries(otherVersions).map(([version, names]) => (
                            <div key={version}>
                                <span className="font-mono">{version}</span>: {names.join(', ')}
                            </div>
                        ))}
                    </Panel>
                )}
            </div>
        </AppLayout>
    );
}
