import React, { useState } from 'react';
import { useForm, router } from '@inertiajs/react';
import { Users, Plus, Copy, Check, Trash2, Printer, CheckCircle2, Clock } from 'lucide-react';
import { toast } from 'sonner';

import { Button } from '@/components/ui/button';
import { Dialog, DialogClose, DialogContent, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';

import { Label } from '@/components/ui/label';

export interface MockStudentItem {
    id: number;
    name: string;
    code: string;
    attended: boolean;
    phone?: string | null;
    attempt?: any;
}

interface MockStudentManagerProps {
    mockId: number;
    mockName: string;
    students?: MockStudentItem[];
}

export default function MockStudentManager({ mockId, mockName, students = [] }: MockStudentManagerProps) {
    const [open, setOpen] = useState(false);
    const [copiedCode, setCopiedCode] = useState<string | null>(null);

    const { data, setData, post, processing, reset } = useForm({
        mock_id: mockId,
        names: '',
        phone: '',
    });

    const handleAddStudents = (e: React.FormEvent) => {
        e.preventDefault();
        post(route('mock-student.store'), {
            preserveScroll: true,
            onSuccess: () => {
                reset('names', 'phone');
                toast.success("O'quvchilar ro'yxatga qo'shildi!");
            },
            onError: (err) => {
                toast.error(err?.error || "Qo'shishda xatolik yuz berdi!");
            }
        });
    };

    const handleDelete = (studentId: number) => {
        if (!confirm("Ushbu o'quvchini o'chirishga ishonchingiz komilmi?")) return;
        router.delete(route('mock-student.destroy', studentId), {
            preserveScroll: true,
            onSuccess: () => toast.success("O'quvchi o'chirildi!"),
        });
    };

    const copyCode = (code: string) => {
        navigator.clipboard.writeText(code);
        setCopiedCode(code);
        toast.success(`Kod nusxalandi: ${code}`);
        setTimeout(() => setCopiedCode(null), 2000);
    };

    const handlePrintPasses = () => {
        const printWindow = window.open('', '_blank');
        if (!printWindow) return;

        const html = `
            <!DOCTYPE html>
            <html>
            <head>
                <title>Mock Exam Passes - ${mockName}</title>
                <style>
                    body { font-family: sans-serif; padding: 20px; }
                    h2 { margin-bottom: 5px; }
                    .pass-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; margin-top: 20px; }
                    .pass-card { border: 2px dashed #4f46e5; padding: 15px; border-radius: 12px; }
                    .pass-title { font-size: 14px; font-weight: bold; color: #4f46e5; }
                    .candidate-name { font-size: 18px; font-weight: bold; margin: 8px 0; }
                    .code-box { background: #f3f4f6; font-family: monospace; font-size: 20px; font-weight: bold; padding: 8px; border-radius: 6px; text-align: center; letter-spacing: 2px; }
                    .instructions { font-size: 11px; color: #6b7280; margin-top: 8px; }
                </style>
            </head>
            <body>
                <h2>Mynine Academy - Mock Exam Access Passes</h2>
                <p>Mock Test: <strong>${mockName}</strong> | Jami: ${students.length} ta o'quvchi</p>
                <div class="pass-grid">
                    ${students.map(s => `
                        <div class="pass-card">
                            <div class="pass-title">MYNINE MOCK EXAM PASS</div>
                            <div class="candidate-name">${s.name}</div>
                            <div class="code-box">${s.code}</div>
                            <div class="instructions">mynine.uz saytiga kiring, [IMTIHON] tugmasini bosing va ushbu kodingizni kiriting.</div>
                        </div>
                    `).join('')}
                </div>
                <script>
                    window.onload = function() {
                        window.print();
                        setTimeout(function() {
                            window.close();
                        }, 300);
                    };
                    window.onafterprint = function() {
                        window.close();
                    };
                </script>
            </body>
            </html>
        `;

        printWindow.document.write(html);
        printWindow.document.close();
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <button
                    type="button"
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold text-indigo-700 bg-indigo-50 hover:bg-indigo-100 dark:bg-indigo-950/50 dark:text-indigo-300 dark:hover:bg-indigo-900/60 rounded-xl transition-all shadow-xs border border-indigo-200 dark:border-indigo-800"
                >
                    <Users className="w-3.5 h-3.5" />
                    <span>O'quvchilar ({students.length})</span>
                </button>
            </DialogTrigger>

            <DialogContent className="sm:max-w-2xl w-full p-0 overflow-hidden rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-2xl flex flex-col max-h-[88vh]">
                {/* Header */}
                <DialogHeader className="p-5 border-b border-gray-100 dark:border-gray-800 flex items-center justify-between">
                    <div>
                        <DialogTitle className="text-lg font-bold text-gray-900 dark:text-gray-100 flex items-center gap-2">
                            <Users className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
                            Mock O'quvchilari Boshqaruvi
                        </DialogTitle>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                            {mockName} (Jami {students.length} o'quvchi)
                        </p>
                    </div>
                </DialogHeader>

                {/* Body Content */}
                <div className="flex-1 overflow-y-auto p-5 space-y-5">
                    {/* Add Students Form */}
                    <form onSubmit={handleAddStudents} className="p-4 rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-800/40 space-y-3">
                        <Label htmlFor="names-input" className="text-xs font-bold text-gray-800 dark:text-gray-200">
                            Yangi O'quvchilar Ismlarini Qo'shish (Har bir ismni yangi qatorga yozing)
                        </Label>
                        <textarea
                            id="names-input"
                            rows={3}
                            placeholder="Masalan:&#10;Anvar Karimov&#10;Malika Aliyeva&#10;Sardor Qodirov"
                            className="w-full rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 p-3 text-xs font-medium focus:ring-2 focus:ring-indigo-500/20 text-gray-900 dark:text-white"
                            value={data.names}
                            onChange={(e) => setData('names', e.target.value)}
                            required
                        />

                        <div className="flex items-center justify-between pt-1">
                            <span className="text-[11px] text-gray-500 dark:text-gray-400">
                                * Tizim har biriga avtomatik unikal imtihon kodi generatsiya qiladi.
                            </span>
                            <Button
                                type="submit"
                                disabled={processing || !data.names}
                                className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs rounded-xl shadow-xs active:scale-95"
                            >
                                <Plus className="w-3.5 h-3.5 mr-1" />
                                Qo'shish
                            </Button>
                        </div>
                    </form>

                    {/* Students List Toolbar */}
                    <div className="flex items-center justify-between">
                        <h4 className="text-xs font-bold text-gray-800 dark:text-gray-200 uppercase tracking-wider">
                            Ro'yxatga Olinganlar ({students.length})
                        </h4>
                        {students.length > 0 && (
                            <Button
                                type="button"
                                variant="outline"
                                onClick={handlePrintPasses}
                                className="rounded-xl text-xs font-semibold flex items-center gap-1.5 border-gray-200 dark:border-gray-700"
                            >
                                <Printer className="w-3.5 h-3.5 text-indigo-500" />
                                Kodlarni Chop Etish (Print)
                            </Button>
                        )}
                    </div>

                    {/* Table */}
                    {students.length === 0 ? (
                        <div className="text-center py-8 border border-dashed border-gray-200 dark:border-gray-800 rounded-xl text-xs text-gray-400">
                            Hali o'quvchilar qo'shilmagan. Yuqoridagi maydonga ismlarni kiriting.
                        </div>
                    ) : (
                        <div className="rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
                            <table className="w-full text-xs text-left border-collapse">
                                <thead className="bg-gray-100 dark:bg-gray-800/80 text-gray-500 dark:text-gray-400 font-bold uppercase text-[10px]">
                                    <tr>
                                        <th className="px-3.5 py-2.5">O'quvchi Ismi</th>
                                        <th className="px-3.5 py-2.5">Nomzod Kodi</th>
                                        <th className="px-3.5 py-2.5 text-center">Davomat</th>
                                        <th className="px-3.5 py-2.5 text-right">Amal</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-gray-100 dark:divide-gray-800/60 bg-white dark:bg-gray-900">
                                    {students.map(item => (
                                        <tr key={item.id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/40">
                                            <td className="px-3.5 py-2.5 font-bold text-gray-900 dark:text-gray-100">
                                                {item.name}
                                            </td>
                                            <td className="px-3.5 py-2.5 font-mono font-bold text-indigo-600 dark:text-indigo-400">
                                                <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-indigo-50 dark:bg-indigo-950/40 border border-indigo-200 dark:border-indigo-800/40">
                                                    <span>{item.code}</span>
                                                    <button
                                                        type="button"
                                                        onClick={() => copyCode(item.code)}
                                                        className="hover:text-indigo-800 dark:hover:text-indigo-200 transition-colors cursor-pointer"
                                                        title="Nusxalash"
                                                    >
                                                        {copiedCode === item.code ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
                                                    </button>
                                                </div>
                                            </td>
                                            <td className="px-3.5 py-2.5 text-center">
                                                <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                                                    item.attended
                                                        ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-400'
                                                        : 'bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-400'
                                                }`}>
                                                    {item.attended ? <CheckCircle2 className="w-3 h-3" /> : <Clock className="w-3 h-3" />}
                                                    {item.attended ? 'Qatnashdi' : 'Kutilmoqda'}
                                                </span>
                                            </td>
                                            <td className="px-3.5 py-2.5 text-right">
                                                <button
                                                    type="button"
                                                    onClick={() => handleDelete(item.id)}
                                                    className="p-1.5 text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-950/40 rounded-lg transition-colors cursor-pointer"
                                                    title="O'chirish"
                                                >
                                                    <Trash2 className="w-3.5 h-3.5" />
                                                </button>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>

                <DialogFooter className="p-4 border-t border-gray-100 dark:border-gray-800">
                    <DialogClose asChild>
                        <Button type="button" variant="outline" className="rounded-xl text-xs font-semibold">
                            Yopish
                        </Button>
                    </DialogClose>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
