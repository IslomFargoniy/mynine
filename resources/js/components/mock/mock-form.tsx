import { fmtDateTime, ModuleBadge, MODULE_TYPES, Panel, selectClass } from '@/components/exam-admin/shared';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { type Mock } from '@/types';
import { useForm } from '@inertiajs/react';
import { formatServerTime, serverInstant, serverNow } from '@/lib/server-time';
import { format } from 'date-fns';
import { AlertTriangle, Monitor, Wand2 } from 'lucide-react';
import React, { FormEventHandler, useMemo } from 'react';
import { useTranslation } from 'react-i18next';

export interface BankModule {
    id: number;
    type: string;
    type_id: number;
    test_id: number;
    test_name: string;
    last_used_at: string | null;
    recently_used: boolean;
    /** Exam dates of the other mocks using this module (reuse rule, re-checked when the date changes). */
    used_on?: string[];
    uses: number;
}

export interface MockFormData {
    mock: Mock | null;
    modules: BankModule[];
    autoPick: Record<string, number | null>;
    reuseDays: number;
    /** A candidate already started a module: the modules cannot change any more. */
    modulesLocked?: boolean;
}

type ModuleKey = 'Listening' | 'Reading' | 'Writing';

/** Server value → "yyyy-MM-dd HH:mm" in center (Tashkent) time; the server reads it back as Tashkent time. */
function toInput(value?: string | null): string {
    return formatServerTime(value, 'yyyy-MM-dd HH:mm', '');
}

/** New mock: starts now (next 5 minutes), ends the same evening (at least 4 hours later). */
function defaultTimes(): { start: string; end: string } {
    const start = serverNow();
    start.setSeconds(0, 0);
    start.setMinutes(Math.ceil(start.getMinutes() / 5) * 5);
    const end = new Date(start);
    end.setHours(23, 55, 0, 0);
    if (end.getTime() - start.getTime() < 4 * 3600000) end.setTime(start.getTime() + 4 * 3600000);
    return { start: format(start, 'yyyy-MM-dd HH:mm'), end: format(end, 'yyyy-MM-dd HH:mm') };
}

function DateTimeField({ id, value, onChange }: { id: string; value: string; onChange: (value: string) => void }) {
    return (
        <input
            id={id}
            type="datetime-local"
            step={300}
            value={value ? value.replace(' ', 'T') : ''}
            onChange={(e) => onChange(e.target.value ? e.target.value.replace('T', ' ').slice(0, 16) : '')}
            className="h-9 w-full rounded-xl border border-input bg-glass-subtle px-3 text-sm text-foreground focus:border-ring focus:ring-2 focus:ring-ring/40"
        />
    );
}

interface MockFormProps extends MockFormData {
    /** Shown left of Save (e.g. Cancel in the modal). */
    secondaryAction?: React.ReactNode;
    /** Edit in a modal: stay on the current page after saving. */
    stay?: boolean;
    onSaved?: () => void;
}

/** Mock create / edit form (used by the mock modal and the full page). */
export default function MockFormFields({ mock, modules, autoPick, reuseDays, modulesLocked = false, secondaryAction, stay = false, onSaved }: MockFormProps) {
    const { t } = useTranslation();
    const isEdit = !!mock;
    const isLegacy = isEdit && (!mock.modules || mock.modules.length === 0);

    const current = (type: ModuleKey) => mock?.modules?.find((m) => m.type?.name === type)?.test_type_id ?? '';

    const defaults = useMemo(defaultTimes, []);

    const { data, setData, post, put, processing, errors, transform } = useForm({
        name: mock?.name ?? '',
        comment: mock?.comment ?? '',
        started_at: mock ? toInput(mock.started_at) : defaults.start,
        finished_at: mock ? toInput(mock.finished_at) : defaults.end,
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

    // Reuse rule against the chosen exam date (both directions); the server value is for "now".
    const isRecent = (m: BankModule): boolean => {
        const target = serverInstant(data.started_at);
        if (!m.used_on || Number.isNaN(target)) return m.recently_used;
        return m.used_on.some((d) => Math.abs(new Date(d).getTime() - target) < reuseDays * 86400000);
    };

    // Same rule as MockBankService::autoPick, for the exam date chosen in the form (the server's pick is
    // for the date the form was opened with): least recently used module outside the reuse window.
    const suggested = useMemo(() => {
        const target = serverInstant(data.started_at);
        if (Number.isNaN(target)) return autoPick;
        const lastUse = (m: BankModule) => Math.max(0, ...(m.used_on ?? []).map((d) => new Date(d).getTime()));
        const picks: Record<string, number | null> = {};
        MODULE_TYPES.forEach((type) => {
            const best = (byType[type] ?? [])
                .filter((m) => modules.some((x) => x.id === m.id) && !isRecent(m))
                .sort((a, b) => lastUse(a) - lastUse(b) || a.id - b.id)[0];
            picks[type] = best?.id ?? null;
        });
        return picks;
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [data.started_at, byType, modules, autoPick, reuseDays]);

    const applyAutoPick = () => {
        MODULE_TYPES.forEach((type) => {
            const id = suggested[type];
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
        ...(stay ? { stay: 1 } : {}),
    }) as never);

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        if (isEdit) {
            put(route('mock.update', mock.id), { preserveScroll: true, onSuccess: () => onSaved?.() });
        } else {
            post(route('mock.store'), { preserveScroll: true, onSuccess: () => onSaved?.() });
        }
    };

    return (
            <form onSubmit={submit} className="space-y-3">
                <Panel className="grid gap-x-4 gap-y-3 md:grid-cols-4">
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

                    {/* Left: exam window. Right: who can enter. */}
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
                    <label
                        title={t('exam_admin.mock_form.require_desktop_hint')}
                        className="flex h-9 cursor-pointer items-center gap-2 self-end rounded-xl border border-input bg-glass-subtle px-3"
                    >
                        <input type="checkbox" className="h-4 w-4 shrink-0 accent-primary" checked={data.require_desktop} onChange={(e) => setData('require_desktop', e.target.checked)} />
                        <Monitor className="h-4 w-4 shrink-0 text-brand" />
                        <span className="truncate text-sm font-bold">{t('exam_admin.mock_form.require_desktop')}</span>
                    </label>
                    <label className="flex h-9 cursor-pointer items-center gap-2 self-end rounded-xl border border-input bg-glass-subtle px-3">
                        <input type="checkbox" className="h-4 w-4 shrink-0 accent-primary" checked={data.active === 1} onChange={(e) => setData('active', e.target.checked ? 1 : 0)} />
                        <span className="truncate text-sm font-bold">{t('exam_admin.mock_form.active')}</span>
                    </label>

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
                    <p className="self-end pb-2 text-[11px] text-muted-foreground md:col-span-2">
                        {data.require_desktop ? t('exam_admin.mock_form.require_desktop_hint') : ''}
                    </p>
                </Panel>

                <Panel className="space-y-3">
                    <div className="flex flex-wrap items-center justify-between gap-2">
                        <div>
                            <h2 className="text-sm font-black text-foreground">{t('exam_admin.mock_form.modules')}</h2>
                            <p className="text-[11px] text-muted-foreground">{t('exam_admin.mock_form.modules_hint', { days: reuseDays })}</p>
                        </div>
                        <Button type="button" variant="outline" className="rounded-full text-xs" onClick={applyAutoPick} disabled={modulesLocked}>
                            <Wand2 className="h-4 w-4 text-brand" />
                            {t('exam_admin.mock_form.auto_pick')}
                        </Button>
                    </div>

                    {modulesLocked && (
                        <div className="rounded-xl border border-amber-500/25 bg-amber-500/15 px-3 py-2 text-xs text-amber-800 dark:text-amber-200">
                            {t('exam_admin.mock_form.modules_locked')}
                        </div>
                    )}

                    {isLegacy && (
                        <div className="rounded-xl border border-amber-500/25 bg-amber-500/15 px-3 py-2 text-xs text-amber-800 dark:text-amber-200">
                            {t('exam_admin.mock_form.legacy', { test: mock?.test?.name ?? '' })}
                        </div>
                    )}

                    <div className="grid gap-x-4 gap-y-3 md:grid-cols-3">
                        {MODULE_TYPES.map((type) => {
                            const options = byType[type] ?? [];
                            const selected = options.find((m) => m.id === data[type]);
                            return (
                                <div key={type} className="space-y-2">
                                    <ModuleBadge type={type} />
                                    <select disabled={modulesLocked} className={`${selectClass} w-full`} value={data[type] || ''} onChange={(e) => setData(type, e.target.value ? Number(e.target.value) : '')}>
                                        <option value="">{t('exam_admin.mock_form.no_module')}</option>
                                        {options.map((m) => (
                                            <option key={m.id} value={m.id}>
                                                {m.test_name}
                                                {isRecent(m) ? ' ⚠' : ''}
                                                {suggested[type] === m.id ? ` (${t('exam_admin.mock_form.suggested')})` : ''}
                                            </option>
                                        ))}
                                    </select>
                                    {selected && (
                                        <div className="space-y-1 text-[11px] text-muted-foreground">
                                            <div>
                                                {t('exam_admin.bank.used')}: <b>{selected.uses}</b> · {t('exam_admin.bank.last_used')}: <b>{fmtDateTime(selected.last_used_at, 'dd.MM.yyyy')}</b>
                                            </div>
                                            {isRecent(selected) && (
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


                <div className="flex justify-end gap-2">
                    {secondaryAction}
                    <Button type="submit" disabled={processing} className="rounded-full px-6 font-bold">
                        {t('exam_admin.common.save')}
                    </Button>
                </div>
            </form>
    );
}
