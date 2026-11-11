import { router } from '@inertiajs/react';
import { AlertTriangle, Check, CheckCircle2, Clock, Copy, FileUp, Plus, Printer, Trash2, Users } from 'lucide-react';
import React, { useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { toast } from 'sonner';

import { postJson } from '@/components/exam-admin/shared';
import { Button } from '@/components/ui/button';
import { Dialog, DialogClose, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { IconAction } from '@/components/ui/icon-action';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow, TruncatedText } from '@/components/ui/table';
import { PrintCodesButton, printCodeTickets } from '@/components/mock/print-codes';

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

/** Same rules as CandidateService::cleanName: drop separators left around the name ("ali :" → "ali"). */
export function cleanName(name: string): string {
    return name.replace(/\s+/g, ' ').replace(/^[\s;,:|.\-–—·]+|[\s;,:|.\-–—·]+$/g, '');
}

const PHONE = '(\\+?\\d[\\d\\s()\\-]{7,}\\d)';
const SEPARATOR = '(?:\\s*[;,:|]\\s*|\\s+-\\s+|\\s+)';
const PHONE_LAST = new RegExp(`^(.*?)${SEPARATOR}${PHONE}\\s*[;,.]?$`);
const PHONE_FIRST = new RegExp(`^${PHONE}${SEPARATOR}(.+)$`);

/**
 * Same rules as CandidateService::parseLine: "Name ; phone", "Name, phone", "Name : phone", "Name<TAB>phone",
 * "Name - phone", "Name phone" or "phone - Name". Hyphens inside names stay.
 */
export function parseLine(raw: string): DraftRow {
    const line = raw.replace(/\t/g, ' ; ').trim();
    let match = line.match(PHONE_LAST);
    if (match) return { name: cleanName(match[1]), phone: match[2].trim() };
    match = line.match(PHONE_FIRST);
    if (match) return { name: cleanName(match[2]), phone: match[1].trim() };
    return { name: cleanName(line), phone: '' };
}

function parseLines(text: string): DraftRow[] {
    return text
        .split(/\r?\n/)
        .map((line) => line.trim())
        .filter(Boolean)
        .map(parseLine);
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
            setText((prev) => [prev.trim(), ...imported.map((r) => `${cleanName(r.name)}; ${r.phone}`)].filter(Boolean).join('\n'));
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
                onError: (errors) => toast.error(Object.values(errors).join('\n') || t('exam_admin.common.error')),
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

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <button
                    type="button"
                    className="inline-flex items-center gap-1.5 rounded-full border border-indigo-500/25 bg-indigo-500/12 px-3.5 py-1.5 text-xs font-bold text-brand transition-all hover:bg-indigo-500/20"
                >
                    <Users className="h-3.5 w-3.5" />
                    <span>{triggerLabel ?? t('exam_admin.candidates.trigger', { count: students.length })}</span>
                </button>
            </DialogTrigger>

            <DialogContent className="flex max-h-[90vh] w-full flex-col overflow-hidden p-0 sm:max-w-3xl">
                <DialogHeader className="border-b border-divider p-5">
                    <DialogTitle className="flex items-center gap-2 text-lg font-bold text-foreground">
                        <Users className="h-5 w-5 text-brand " />
                        {t('exam_admin.candidates.title')}
                    </DialogTitle>
                    <DialogDescription className="text-xs text-muted-foreground">
                        {mockName} · {t('exam_admin.candidates.total', { count: students.length })}
                    </DialogDescription>
                </DialogHeader>

                <div className="flex-1 space-y-5 overflow-y-auto p-5">
                    <form onSubmit={handleAdd} className="glass-subtle space-y-3 rounded-[18px] p-4">
                        <div className="flex flex-wrap items-center justify-between gap-2">
                            <Label htmlFor="candidates-input" className="text-xs font-bold text-foreground">
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
                                <Button type="button" variant="outline" size="sm" className="rounded-full text-xs" onClick={() => fileInput.current?.click()}>
                                    <FileUp className="h-3.5 w-3.5 text-emerald-700 dark:text-emerald-300" />
                                    {t('exam_admin.candidates.import')}
                                </Button>
                            </div>
                        </div>
                        <textarea
                            id="candidates-input"
                            rows={4}
                            placeholder={t('exam_admin.candidates.placeholder')}
                            className="w-full rounded-xl border border-input bg-glass-subtle p-3 font-mono text-xs text-foreground focus:border-ring focus:ring-2 focus:ring-ring/40"
                            value={text}
                            onChange={(e) => setText(e.target.value)}
                        />

                        {rows.length > 0 && (
                            <div className="max-h-56 overflow-y-auto rounded-[14px] border border-divider bg-glass-subtle">
                                <table className="w-full text-left text-xs">
                                    <tbody className="divide-y divide-divider">
                                        {rows.map((row, index) => {
                                            const rowRepeats = row.normalized ? repeats[row.normalized] : undefined;
                                            return (
                                                <tr key={index} className={!row.normalized || !row.name ? 'bg-rose-500/8' : ''}>
                                                    <td className="px-3 py-1.5 font-semibold">{row.name || '—'}</td>
                                                    <td className="px-3 py-1.5 font-mono">
                                                        {row.normalized ?? <span className="text-rose-700 dark:text-rose-300">{row.phone || t('exam_admin.candidates.phone_missing')}</span>}
                                                    </td>
                                                    <td className="px-3 py-1.5">
                                                        {rowRepeats && (
                                                            <span className="inline-flex items-center gap-1 text-[10px] font-bold text-amber-800 dark:text-amber-200">
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
                            <span className="text-[11px] text-muted-foreground">
                                {invalid.length > 0 ? (
                                    <span className="font-semibold text-rose-700 dark:text-rose-300">{t('exam_admin.candidates.invalid_rows', { count: invalid.length })}</span>
                                ) : (
                                    t('exam_admin.candidates.hint')
                                )}
                            </span>
                            <Button
                                type="submit"
                                disabled={processing || rows.length === 0 || invalid.length > 0}
                                className="rounded-full text-xs font-bold"
                            >
                                <Plus className="h-3.5 w-3.5" />
                                {t('exam_admin.candidates.add', { count: rows.length })}
                            </Button>
                        </div>
                    </form>

                    <div className="flex items-center justify-between">
                        <h4 className="text-xs font-bold tracking-wider text-foreground uppercase">
                            {t('exam_admin.candidates.registered', { count: students.length })}
                        </h4>
                        {students.length > 0 && <PrintCodesButton mockId={mockId} />}
                    </div>

                    {students.length === 0 ? (
                        <div className="rounded-[18px] border border-dashed border-glass-dash py-8 text-center text-xs text-muted-foreground">
                            {t('exam_admin.candidates.empty')}
                        </div>
                    ) : (
                        <div className="overflow-hidden rounded-[18px] border border-divider">
                            <Table>
                                <TableHeader>
                                    <TableRow>
                                        <TableHead>{t('exam_admin.common.name')}</TableHead>
                                        <TableHead>{t('exam_admin.common.code')}</TableHead>
                                        <TableHead>{t('exam_admin.candidates.attendance')}</TableHead>
                                        <TableHead className="w-px">
                                            <span className="sr-only">{t('exam_admin.common.actions')}</span>
                                        </TableHead>
                                    </TableRow>
                                </TableHeader>
                                <TableBody>
                                    {students.map((item) => (
                                        <TableRow key={item.id}>
                                            <TableCell>
                                                <TruncatedText className="max-w-[14rem] font-bold text-foreground">{item.name}</TruncatedText>
                                                <div className="font-mono text-[11px] text-muted-foreground">{item.phone ?? '—'}</div>
                                            </TableCell>
                                            <TableCell label={t('exam_admin.common.code')}>
                                                <span className="inline-flex items-center gap-1.5 rounded-full border border-indigo-500/25 bg-indigo-500/12 px-2.5 py-1 font-mono font-bold whitespace-nowrap text-brand">
                                                    {item.code}
                                                    <button
                                                        type="button"
                                                        onClick={() => copyCode(item.code)}
                                                        className="cursor-pointer"
                                                        title={t('exam_admin.common.copy')}
                                                        aria-label={t('exam_admin.common.copy')}
                                                    >
                                                        {copiedCode === item.code ? <Check className="h-3.5 w-3.5 text-emerald-700 dark:text-emerald-300" /> : <Copy className="h-3.5 w-3.5" />}
                                                    </button>
                                                </span>
                                            </TableCell>
                                            <TableCell label={t('exam_admin.candidates.attendance')}>
                                                <span
                                                    className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-bold whitespace-nowrap ${
                                                        item.attended
                                                            ? 'bg-emerald-500/12 text-emerald-800 dark:bg-emerald-400/15 dark:text-emerald-200'
                                                            : 'bg-amber-500/15 text-amber-800 dark:bg-amber-400/15 dark:text-amber-200'
                                                    }`}
                                                >
                                                    {item.attended ? <CheckCircle2 className="h-3 w-3" /> : <Clock className="h-3 w-3" />}
                                                    {item.attended ? t('exam_admin.candidates.attended') : t('exam_admin.candidates.waiting')}
                                                </span>
                                            </TableCell>
                                            <TableCell className="text-right">
                                                <div className="flex items-center justify-end gap-0.5">
                                                    <IconAction label={t('exam_admin.candidates.print_ticket')} tone="brand" onClick={() => printCodeTickets(mockId, [item.id])}>
                                                        <Printer />
                                                    </IconAction>
                                                    {canDelete && (
                                                        <IconAction label={t('exam_admin.common.delete')} tone="danger" onClick={() => handleDelete(item.id)}>
                                                            <Trash2 />
                                                        </IconAction>
                                                    )}
                                                </div>
                                            </TableCell>
                                        </TableRow>
                                    ))}
                                </TableBody>
                            </Table>
                        </div>
                    )}
                </div>

                <DialogFooter className="border-t border-divider p-4">
                    <DialogClose asChild>
                        <Button type="button" variant="outline" className="rounded-full text-xs font-semibold">
                            {t('exam_admin.common.close')}
                        </Button>
                    </DialogClose>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
