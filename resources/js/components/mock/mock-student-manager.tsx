import { router } from '@inertiajs/react';
import { AlertTriangle, Check, CheckCircle2, Clock, Copy, FileUp, Plus, Printer, Trash2, Users } from 'lucide-react';
import React, { useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { toast } from 'sonner';

import { postJson } from '@/components/exam-admin/shared';
import { Button } from '@/components/ui/button';
import { Dialog, DialogClose, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';

export interface MockStudentItem {
    id: number;
    name: string;
    code: string;
    attended?: boolean;
    phone?: string | null;
    attempt?: unknown;
}

interface MockStudentManagerProps {
    mockId: number;
    mockName: string;
    students?: MockStudentItem[];
    /** Deleting candidates is Admin only. */
    canDelete?: boolean;
    /** Custom trigger label (defaults to "Candidates (n)"). */
    triggerLabel?: string;
}

interface RepeatModule {
    test_type_id: number;
    type: string | null;
    test: string | null;
    mock: string | null;
    date: string | null;
}

interface DraftRow {
    name: string;
    phone: string;
}

/** Same rule as the server: 9 local digits or 998 + 9 digits → +998XXXXXXXXX. */
export function normalizePhone(raw: string): string | null {
    let digits = (raw ?? '').replace(/\D+/g, '');
    if (digits.length === 9) digits = '998' + digits;
    return /^998\d{9}$/.test(digits) ? '+' + digits : null;
}

function parseLines(text: string): DraftRow[] {
    return text
        .split(/\r?\n/)
        .map((line) => line.trim())
        .filter(Boolean)
        .map((line) => {
            // "Name, phone" / "Name; phone" / "Name<TAB>phone" / "Name +998..."
            const parts = line.split(/\t|;|,(?=[^,]*$)/).map((p) => p.trim());
            if (parts.length >= 2) return { name: parts[0], phone: parts.slice(1).join(' ') };
            const match = line.match(/^(.*?)(\+?[\d\s()-]{9,})$/);
            return match ? { name: match[1].trim(), phone: match[2].trim() } : { name: line, phone: '' };
        });
}

export default function MockStudentManager({ mockId, mockName, students = [], canDelete = true, triggerLabel }: MockStudentManagerProps) {
    const { t } = useTranslation();
    const [open, setOpen] = useState(false);
    const [copiedCode, setCopiedCode] = useState<string | null>(null);
    const [text, setText] = useState('');
    const [processing, setProcessing] = useState(false);
    const [repeats, setRepeats] = useState<Record<string, RepeatModule[]>>({});
    const fileInput = useRef<HTMLInputElement>(null);

    const rows = useMemo(() => parseLines(text).map((row) => ({ ...row, normalized: normalizePhone(row.phone) })), [text]);
    const invalid = rows.filter((row) => !row.name || !row.normalized);

    // Repeat-candidate check (debounced) for every valid phone.
    useEffect(() => {
        const phones = Array.from(new Set(rows.map((r) => r.normalized).filter((p): p is string => !!p)));
        if (!open || phones.length === 0) {
            setRepeats({});
            return;
        }
        const id = window.setTimeout(async () => {
            const res = await postJson<{ data?: { phone: string | null; repeats: RepeatModule[] }[] }>(route('mock-student.check-repeats'), {
                mock_id: mockId,
                phones,
            });
            if (!res.ok || !res.data.data) return;
            const map: Record<string, RepeatModule[]> = {};
            res.data.data.forEach((item) => {
                if (item.phone && item.repeats.length > 0) map[item.phone] = item.repeats;
            });
            setRepeats(map);
        }, 500);
        return () => window.clearTimeout(id);
    }, [rows, open, mockId]);

    const handleImport = async (file: File) => {
        try {
            const XLSX = await import('xlsx');
            const workbook = XLSX.read(await file.arrayBuffer(), { type: 'array' });
            const sheet = workbook.Sheets[workbook.SheetNames[0]];
            const data = XLSX.utils.sheet_to_json<(string | number | null)[]>(sheet, { header: 1, raw: false, blankrows: false });
            const imported = data
                .map((cells) => ({ name: String(cells?.[0] ?? '').trim(), phone: String(cells?.[1] ?? '').trim() }))
                .filter((row) => row.name !== '')
                // Skip a header row ("Name | Phone").
                .filter((row, index) => !(index === 0 && !normalizePhone(row.phone)));
            if (imported.length === 0) {
                toast.error(t('exam_admin.candidates.import_empty'));
                return;
            }
            setText((prev) => [prev.trim(), ...imported.map((r) => `${r.name}; ${r.phone}`)].filter(Boolean).join('\n'));
            toast.success(t('exam_admin.candidates.imported', { count: imported.length }));
        } catch {
            toast.error(t('exam_admin.candidates.import_failed'));
        }
    };

    const handleAdd = (e: React.FormEvent) => {
        e.preventDefault();
        if (rows.length === 0 || invalid.length > 0) return;
        setProcessing(true);
        router.post(
            route('mock-student.store'),
            { mock_id: mockId, candidates: rows.map((r) => ({ name: r.name, phone: r.normalized ?? r.phone })) },
            {
                preserveScroll: true,
                onSuccess: () => setText(''),
                onError: (errors) => toast.error(Object.values(errors)[0] ?? t('exam_admin.common.error')),
                onFinish: () => setProcessing(false),
            },
        );
    };

    const handleDelete = (studentId: number) => {
        if (!confirm(t('exam_admin.candidates.delete_confirm'))) return;
        router.delete(route('mock-student.destroy', studentId), { preserveScroll: true });
    };

    const copyCode = (code: string) => {
        navigator.clipboard?.writeText(code);
        setCopiedCode(code);
        setTimeout(() => setCopiedCode(null), 2000);
    };

    const printCards = (ids?: number[]) => {
        window.open(route('mock.code-cards', ids && ids.length > 0 ? { mock: mockId, ids: ids.join(',') } : { mock: mockId }), '_blank');
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <button
                    type="button"
                    className="inline-flex items-center gap-1.5 rounded-xl border border-indigo-200 bg-indigo-50 px-3 py-1.5 text-xs font-bold text-indigo-700 shadow-xs transition-all hover:bg-indigo-100 dark:border-indigo-800 dark:bg-indigo-950/50 dark:text-indigo-300 dark:hover:bg-indigo-900/60"
                >
                    <Users className="h-3.5 w-3.5" />
                    <span>{triggerLabel ?? t('exam_admin.candidates.trigger', { count: students.length })}</span>
                </button>
            </DialogTrigger>

            <DialogContent className="flex max-h-[90vh] w-full flex-col overflow-hidden rounded-2xl border border-gray-100 bg-white p-0 shadow-2xl sm:max-w-3xl dark:border-gray-800 dark:bg-gray-900">
                <DialogHeader className="border-b border-gray-100 p-5 dark:border-gray-800">
                    <DialogTitle className="flex items-center gap-2 text-lg font-bold text-gray-900 dark:text-gray-100">
                        <Users className="h-5 w-5 text-indigo-600 dark:text-indigo-400" />
                        {t('exam_admin.candidates.title')}
                    </DialogTitle>
                    <DialogDescription className="text-xs text-gray-500 dark:text-gray-400">
                        {mockName} · {t('exam_admin.candidates.total', { count: students.length })}
                    </DialogDescription>
                </DialogHeader>

                <div className="flex-1 space-y-5 overflow-y-auto p-5">
                    <form onSubmit={handleAdd} className="space-y-3 rounded-xl border border-gray-200 bg-gray-50/50 p-4 dark:border-gray-800 dark:bg-gray-800/40">
                        <div className="flex flex-wrap items-center justify-between gap-2">
                            <Label htmlFor="candidates-input" className="text-xs font-bold text-gray-800 dark:text-gray-200">
                                {t('exam_admin.candidates.add_label')}
                            </Label>
                            <div className="flex items-center gap-2">
                                <input
                                    ref={fileInput}
                                    type="file"
                                    accept=".xlsx,.xls,.csv"
                                    className="hidden"
                                    onChange={(e) => {
                                        const file = e.target.files?.[0];
                                        if (file) handleImport(file);
                                        e.target.value = '';
                                    }}
                                />
                                <Button type="button" variant="outline" size="sm" className="rounded-xl text-xs" onClick={() => fileInput.current?.click()}>
                                    <FileUp className="h-3.5 w-3.5 text-emerald-600" />
                                    {t('exam_admin.candidates.import')}
                                </Button>
                            </div>
                        </div>
                        <textarea
                            id="candidates-input"
                            rows={4}
                            placeholder={t('exam_admin.candidates.placeholder')}
                            className="w-full rounded-xl border border-gray-200 bg-white p-3 font-mono text-xs text-gray-900 focus:ring-2 focus:ring-indigo-500/20 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
                            value={text}
                            onChange={(e) => setText(e.target.value)}
                        />

                        {rows.length > 0 && (
                            <div className="max-h-56 overflow-y-auto rounded-xl border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900">
                                <table className="w-full text-left text-xs">
                                    <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                                        {rows.map((row, index) => {
                                            const rowRepeats = row.normalized ? repeats[row.normalized] : undefined;
                                            return (
                                                <tr key={index} className={!row.normalized || !row.name ? 'bg-rose-50/60 dark:bg-rose-950/20' : ''}>
                                                    <td className="px-3 py-1.5 font-semibold">{row.name || '—'}</td>
                                                    <td className="px-3 py-1.5 font-mono">
                                                        {row.normalized ?? <span className="text-rose-600">{row.phone || t('exam_admin.candidates.phone_missing')}</span>}
                                                    </td>
                                                    <td className="px-3 py-1.5">
                                                        {rowRepeats && (
                                                            <span className="inline-flex items-center gap-1 text-[10px] font-bold text-amber-700 dark:text-amber-400">
                                                                <AlertTriangle className="h-3 w-3" />
                                                                {t('exam_admin.candidates.repeat')}:{' '}
                                                                {rowRepeats.map((r) => `${r.type} (${r.test}${r.date ? ', ' + r.date : ''})`).join(', ')}
                                                            </span>
                                                        )}
                                                    </td>
                                                </tr>
                                            );
                                        })}
                                    </tbody>
                                </table>
                            </div>
                        )}

                        <div className="flex items-center justify-between gap-3 pt-1">
                            <span className="text-[11px] text-gray-500 dark:text-gray-400">
                                {invalid.length > 0 ? (
                                    <span className="font-semibold text-rose-600">{t('exam_admin.candidates.invalid_rows', { count: invalid.length })}</span>
                                ) : (
                                    t('exam_admin.candidates.hint')
                                )}
                            </span>
                            <Button
                                type="submit"
                                disabled={processing || rows.length === 0 || invalid.length > 0}
                                className="rounded-xl bg-indigo-600 text-xs font-bold text-white hover:bg-indigo-700"
                            >
                                <Plus className="h-3.5 w-3.5" />
                                {t('exam_admin.candidates.add', { count: rows.length })}
                            </Button>
                        </div>
                    </form>

                    <div className="flex items-center justify-between">
                        <h4 className="text-xs font-bold tracking-wider text-gray-800 uppercase dark:text-gray-200">
                            {t('exam_admin.candidates.registered', { count: students.length })}
                        </h4>
                        {students.length > 0 && (
                            <Button type="button" variant="outline" onClick={() => printCards()} className="rounded-xl text-xs font-semibold">
                                <Printer className="h-3.5 w-3.5 text-indigo-500" />
                                {t('exam_admin.candidates.print_cards')}
                            </Button>
                        )}
                    </div>

                    {students.length === 0 ? (
                        <div className="rounded-xl border border-dashed border-gray-200 py-8 text-center text-xs text-gray-400 dark:border-gray-800">
                            {t('exam_admin.candidates.empty')}
                        </div>
                    ) : (
                        <div className="overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-800">
                            <table className="w-full border-collapse text-left text-xs">
                                <thead className="bg-gray-100 text-[10px] font-bold text-gray-500 uppercase dark:bg-gray-800/80 dark:text-gray-400">
                                    <tr>
                                        <th className="px-3.5 py-2.5">{t('exam_admin.common.name')}</th>
                                        <th className="px-3.5 py-2.5">{t('exam_admin.common.code')}</th>
                                        <th className="px-3.5 py-2.5">{t('exam_admin.common.phone')}</th>
                                        <th className="px-3.5 py-2.5 text-center">{t('exam_admin.candidates.attendance')}</th>
                                        <th className="px-3.5 py-2.5 text-right">{t('exam_admin.common.actions')}</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-gray-100 bg-white dark:divide-gray-800/60 dark:bg-gray-900">
                                    {students.map((item) => (
                                        <tr key={item.id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/40">
                                            <td className="px-3.5 py-2.5 font-bold text-gray-900 dark:text-gray-100">{item.name}</td>
                                            <td className="px-3.5 py-2.5 font-mono font-bold text-indigo-600 dark:text-indigo-400">
                                                <span className="inline-flex items-center gap-1.5 rounded-lg border border-indigo-200 bg-indigo-50 px-2.5 py-1 dark:border-indigo-800/40 dark:bg-indigo-950/40">
                                                    {item.code}
                                                    <button type="button" onClick={() => copyCode(item.code)} className="cursor-pointer" title={t('exam_admin.common.copy')}>
                                                        {copiedCode === item.code ? <Check className="h-3.5 w-3.5 text-emerald-600" /> : <Copy className="h-3.5 w-3.5" />}
                                                    </button>
                                                </span>
                                            </td>
                                            <td className="px-3.5 py-2.5 font-mono text-gray-600 dark:text-gray-300">{item.phone ?? '—'}</td>
                                            <td className="px-3.5 py-2.5 text-center">
                                                <span
                                                    className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[10px] font-bold ${
                                                        item.attended
                                                            ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-400'
                                                            : 'bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-400'
                                                    }`}
                                                >
                                                    {item.attended ? <CheckCircle2 className="h-3 w-3" /> : <Clock className="h-3 w-3" />}
                                                    {item.attended ? t('exam_admin.candidates.attended') : t('exam_admin.candidates.waiting')}
                                                </span>
                                            </td>
                                            <td className="px-3.5 py-2.5 text-right whitespace-nowrap">
                                                <button
                                                    type="button"
                                                    onClick={() => printCards([item.id])}
                                                    className="cursor-pointer rounded-lg p-1.5 text-indigo-500 transition-colors hover:bg-indigo-50 dark:hover:bg-indigo-950/40"
                                                    title={t('exam_admin.candidates.print_card')}
                                                >
                                                    <Printer className="h-3.5 w-3.5" />
                                                </button>
                                                {canDelete && (
                                                    <button
                                                        type="button"
                                                        onClick={() => handleDelete(item.id)}
                                                        className="cursor-pointer rounded-lg p-1.5 text-rose-500 transition-colors hover:bg-rose-50 dark:hover:bg-rose-950/40"
                                                        title={t('exam_admin.common.delete')}
                                                    >
                                                        <Trash2 className="h-3.5 w-3.5" />
                                                    </button>
                                                )}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>

                <DialogFooter className="border-t border-gray-100 p-4 dark:border-gray-800">
                    <DialogClose asChild>
                        <Button type="button" variant="outline" className="rounded-xl text-xs font-semibold">
                            {t('exam_admin.common.close')}
                        </Button>
                    </DialogClose>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
