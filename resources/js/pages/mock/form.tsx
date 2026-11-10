import { fmtDateTime, ModuleBadge, MODULE_TYPES, PageHeader, Panel, selectClass } from '@/components/exam-admin/shared';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import AppLayout from '@/layouts/app-layout';
import { type BreadcrumbItem, type Mock } from '@/types';
import { Head, Link, useForm, usePage } from '@inertiajs/react';
import { format } from 'date-fns';
import { AlertTriangle, ArrowLeft, GraduationCap, Monitor, Wand2 } from 'lucide-react';
import { FormEventHandler, useMemo } from 'react';
import DatePicker from 'react-datepicker';
import 'react-datepicker/dist/react-datepicker.css';
import { useTranslation } from 'react-i18next';

interface BankModule {
    id: number;
    type: string;
    type_id: number;
    test_id: number;
    test_name: string;
    last_used_at: string | null;
    recently_used: boolean;
    uses: number;
}

interface FormProps {
    mock: Mock | null;
    modules: BankModule[];
    autoPick: Record<string, number | null>;
    reuseDays: number;
    [key: string]: unknown;
}

type ModuleKey = 'Listening' | 'Reading' | 'Writing';

function toInput(value?: string | null): string {
    if (!value) return '';
    const date = new Date(value.replace(' ', 'T'));
    return Number.isNaN(date.getTime()) ? '' : format(date, 'yyyy-MM-dd HH:mm');
}

function DateTimeField({ id, value, onChange }: { id: string; value: string; onChange: (value: string) => void }) {
    return (
        <DatePicker
            id={id}
            selected={value ? new Date(value.replace(' ', 'T')) : null}
            onChange={(date: Date | null) => onChange(date ? format(date, 'yyyy-MM-dd HH:mm') : '')}
            showTimeSelect
            timeFormat="HH:mm"
            timeIntervals={5}
            dateFormat="yyyy-MM-dd HH:mm"
            className="h-9 w-full rounded-xl border border-input bg-glass-subtle px-3 text-sm text-foreground focus:border-ring focus:ring-2 focus:ring-ring/40"
            wrapperClassName="w-full"
        />
    );
}

export default function MockForm() {
    const { mock, modules, autoPick, reuseDays } = usePage<FormProps>().props;
    const { t } = useTranslation();
    const isEdit = !!mock;
    const isLegacy = isEdit && (!mock.modules || mock.modules.length === 0);

    const current = (type: ModuleKey) => mock?.modules?.find((m) => m.type?.name === type)?.test_type_id ?? '';

    const { data, setData, post, put, processing, errors, transform } = useForm({
        name: mock?.name ?? '',
        comment: mock?.comment ?? '',
        started_at: toInput(mock?.started_at),
        finished_at: toInput(mock?.finished_at),
        active: mock ? Number(mock.active) : 1,
        require_desktop: mock ? !!mock.require_desktop : true,
        speaking_starts_at: toInput(mock?.speaking_starts_at),
        speaking_slot_minutes: mock?.speaking_slot_minutes ?? 15,
        Listening: current('Listening') as number | '',
        Reading: current('Reading') as number | '',
        Writing: current('Writing') as number | '',
    });

    const byType = useMemo(() => {
        const map: Record<string, BankModule[]> = {};
        modules.forEach((m) => {
            (map[m.type] ??= []).push(m);
        });
        // Assigned modules that are no longer "ready" stay selectable while editing.
        mock?.modules?.forEach((m) => {
            const type = m.type?.name;
            if (type && !(map[type] ?? []).some((x) => x.id === m.test_type_id)) {
                (map[type] ??= []).push({
                    id: m.test_type_id,
                    type,
                    type_id: m.type_id,
                    test_id: m.test_type?.test_id ?? 0,
                    test_name: m.test_type?.test?.name ?? `#${m.test_type_id}`,
                    last_used_at: m.test_type?.last_used_at ?? null,
                    recently_used: false,
                    uses: 0,
                });
            }
        });
        return map;
    }, [modules, mock]);

    const applyAutoPick = () => {
        MODULE_TYPES.forEach((type) => {
            const id = autoPick[type];
            if (id) setData(type, id);
        });
    };

    // Send the selected modules as one flat id list.
    transform((d) => ({
        name: d.name,
        comment: d.comment,
        started_at: d.started_at,
        finished_at: d.finished_at,
        active: d.active,
        require_desktop: d.require_desktop ? 1 : 0,
        speaking_starts_at: d.speaking_starts_at || null,
        speaking_slot_minutes: d.speaking_slot_minutes,
        modules: MODULE_TYPES.map((type) => d[type]).filter((id): id is number => !!id),
    }) as never);

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        if (isEdit) {
            put(route('mock.update', mock.id), { preserveScroll: true });
        } else {
            post(route('mock.store'), { preserveScroll: true });
        }
    };

    const breadcrumbs: BreadcrumbItem[] = [
        { title: t('mock'), href: route('mock.index') },
        { title: isEdit ? mock.name : t('exam_admin.mock_form.create_title'), href: '#' },
    ];

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title={isEdit ? mock.name : t('exam_admin.mock_form.create_title')} />
            <form onSubmit={submit} className="mx-auto max-w-5xl space-y-5 p-4 md:p-6">
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

                <Panel className="grid gap-4 md:grid-cols-2">
                    <div className="md:col-span-2">
                        <Label htmlFor="name">{t('exam_admin.common.name')}</Label>
                        <Input id="name" value={data.name} onChange={(e) => setData('name', e.target.value)} />
                        <InputError message={errors.name} />
                    </div>
                    <div className="md:col-span-2">
                        <Label htmlFor="comment">{t('exam_admin.common.comment')}</Label>
                        <Input id="comment" value={data.comment ?? ''} onChange={(e) => setData('comment', e.target.value)} />
                        <InputError message={errors.comment} />
                    </div>
                    <div>
                        <Label htmlFor="started_at">{t('exam_admin.mock_form.starts')}</Label>
                        <DateTimeField id="started_at" value={data.started_at} onChange={(v) => setData('started_at', v)} />
                        <InputError message={errors.started_at} />
                    </div>
                    <div>
                        <Label htmlFor="finished_at">{t('exam_admin.mock_form.ends')}</Label>
                        <DateTimeField id="finished_at" value={data.finished_at} onChange={(v) => setData('finished_at', v)} />
                        <InputError message={errors.finished_at} />
                    </div>
                    <label className="glass-subtle flex cursor-pointer items-center gap-3 rounded-[18px] p-3">
                        <input type="checkbox" className="h-4 w-4 accent-primary" checked={data.require_desktop} onChange={(e) => setData('require_desktop', e.target.checked)} />
                        <span>
                            <span className="flex items-center gap-1.5 text-sm font-bold">
                                <Monitor className="h-4 w-4 text-brand" />
                                {t('exam_admin.mock_form.require_desktop')}
                            </span>
                            <span className="text-[11px] text-muted-foreground">{t('exam_admin.mock_form.require_desktop_hint')}</span>
                        </span>
                    </label>
                    <label className="glass-subtle flex cursor-pointer items-center gap-3 rounded-[18px] p-3">
                        <input type="checkbox" className="h-4 w-4 accent-primary" checked={data.active === 1} onChange={(e) => setData('active', e.target.checked ? 1 : 0)} />
                        <span className="text-sm font-bold">{t('exam_admin.mock_form.active')}</span>
                    </label>
                </Panel>

                <Panel className="space-y-4">
                    <div className="flex flex-wrap items-center justify-between gap-2">
                        <div>
                            <h2 className="text-sm font-black text-foreground">{t('exam_admin.mock_form.modules')}</h2>
                            <p className="text-[11px] text-muted-foreground">{t('exam_admin.mock_form.modules_hint', { days: reuseDays })}</p>
                        </div>
                        <Button type="button" variant="outline" className="rounded-full text-xs" onClick={applyAutoPick}>
                            <Wand2 className="h-4 w-4 text-brand" />
                            {t('exam_admin.mock_form.auto_pick')}
                        </Button>
                    </div>

                    {isLegacy && (
                        <div className="rounded-[18px] border border-amber-500/25 bg-amber-500/15 p-3 text-xs text-amber-800 dark:text-amber-200">
                            {t('exam_admin.mock_form.legacy', { test: mock?.test?.name ?? '' })}
                        </div>
                    )}

                    <div className="grid gap-4 md:grid-cols-3">
                        {MODULE_TYPES.map((type) => {
                            const options = byType[type] ?? [];
                            const selected = options.find((m) => m.id === data[type]);
                            return (
                                <div key={type} className="space-y-2">
                                    <ModuleBadge type={type} />
                                    <select className={`${selectClass} w-full`} value={data[type] || ''} onChange={(e) => setData(type, e.target.value ? Number(e.target.value) : '')}>
                                        <option value="">{t('exam_admin.mock_form.no_module')}</option>
                                        {options.map((m) => (
                                            <option key={m.id} value={m.id}>
                                                {m.test_name}
                                                {m.recently_used ? ' ⚠' : ''}
                                                {autoPick[type] === m.id ? ` (${t('exam_admin.mock_form.suggested')})` : ''}
                                            </option>
                                        ))}
                                    </select>
                                    {selected && (
                                        <div className="space-y-1 text-[11px] text-muted-foreground">
                                            <div>
                                                {t('exam_admin.bank.used')}: <b>{selected.uses}</b> · {t('exam_admin.bank.last_used')}: <b>{fmtDateTime(selected.last_used_at, 'dd.MM.yyyy')}</b>
                                            </div>
                                            {selected.recently_used && (
                                                <div className="flex items-center gap-1 font-semibold text-amber-700 dark:text-amber-300">
                                                    <AlertTriangle className="h-3.5 w-3.5" />
                                                    {t('exam_admin.mock_form.recent_warning', { days: reuseDays })}
                                                </div>
                                            )}
                                        </div>
                                    )}
                                    {options.length === 0 && <p className="text-[11px] text-rose-700 dark:text-rose-300">{t('exam_admin.mock_form.no_ready_modules')}</p>}
                                </div>
                            );
                        })}
                    </div>
                    <InputError message={(errors as Record<string, string | undefined>).modules} />
                </Panel>

                <Panel className="grid gap-4 md:grid-cols-2">
                    <div>
                        <Label htmlFor="speaking_starts_at">{t('exam_admin.mock_form.speaking_starts')}</Label>
                        <DateTimeField id="speaking_starts_at" value={data.speaking_starts_at} onChange={(v) => setData('speaking_starts_at', v)} />
                        <InputError message={errors.speaking_starts_at} />
                    </div>
                    <div>
                        <Label htmlFor="speaking_slot_minutes">{t('exam_admin.mock_form.slot_minutes')}</Label>
                        <Input
                            id="speaking_slot_minutes"
                            type="number"
                            min={5}
                            max={120}
                            value={data.speaking_slot_minutes}
                            onChange={(e) => setData('speaking_slot_minutes', Number(e.target.value))}
                        />
                        <InputError message={errors.speaking_slot_minutes} />
                    </div>
                </Panel>

                <div className="flex justify-end">
                    <Button type="submit" disabled={processing} className="rounded-full px-6 font-bold">
                        {t('exam_admin.common.save')}
                    </Button>
                </div>
            </form>
        </AppLayout>
    );
}
