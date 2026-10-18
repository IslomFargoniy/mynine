import { useForm } from '@inertiajs/react';
import { FormEventHandler, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';

import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { toast } from 'sonner';

import DatePicker from 'react-datepicker';
import 'react-datepicker/dist/react-datepicker.css';
import { format } from 'date-fns';

import {
    Dialog,
    DialogClose,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
    DialogTrigger
} from '@/components/ui/dialog';
import { IoCreate } from 'react-icons/io5';

import { Test } from '@/types';
import { Select, SelectContent, SelectItem, SelectTrigger } from '@/components/ui/select';

export default function CreateMockModal({ tests }: { tests: Test[] }) {
    const { t } = useTranslation();
    const [open, setOpen] = useState(false);

    const nameInput = useRef<HTMLInputElement>(null);

    const { data, setData, post, processing, reset, errors, clearErrors } = useForm({
        name: '',
        comment: '',
        started_at: '',
        finished_at: '',
        test_id: 0,
        active: 0
    });

    const submit: FormEventHandler = (e) => {
        e.preventDefault();

        post(route('mock.store'), {
            preserveScroll: true,
            onSuccess: () => {
                reset();
                clearErrors();
                setOpen(false); // 🔒 CLOSE MODAL HERE
                toast.success(t('created_successfully'));
            },
            onError: (err) => {
                nameInput.current?.focus();
                // Display a friendly error message if available
                const errorMessage = err?.error || t('create_failed'); // Use fallback error message
                toast.error(errorMessage); // Display error message
            }
        });
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <button
                    type="button"
                    className="inline-flex items-center gap-2 px-4 py-2.5 bg-blue-600 hover:bg-blue-700 active:scale-95 text-white font-bold text-xs rounded-xl shadow-xs transition-all cursor-pointer"
                >
                    <IoCreate className="w-4 h-4" />
                    {t('create')} {t('mock')}
                </button>
            </DialogTrigger>

            <DialogContent className="sm:max-w-lg w-full rounded-2xl border border-gray-200 dark:border-gray-800 shadow-2xl bg-white dark:bg-gray-900">
                <DialogHeader className="space-y-1 pb-2 border-b border-gray-100 dark:border-gray-800">
                    <DialogTitle className="text-lg font-bold text-gray-900 dark:text-gray-100">
                        {t('modal.create_mock_title')}
                    </DialogTitle>
                    <DialogDescription className="text-xs text-gray-500 dark:text-gray-400">
                        {t('modal.create_mock_desc')}
                    </DialogDescription>
                </DialogHeader>

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
                            value={data.comment}
                            onChange={(e) => setData('comment', e.target.value)}
                        />
                        <InputError message={errors.comment} />
                    </div>


                    <div>

                        <Label htmlFor="started_at">{t('started_at')}</Label>

                        <DatePicker
                            selected={data.started_at ? new Date(data.started_at) : null}
                            onChange={(date: Date | null) => {
                                if (date) {
                                    setData('started_at', format(date, 'yyyy-MM-dd HH:mm')); // ✅ always Y-m-d H:i
                                }
                            }}
                            showTimeSelect
                            timeFormat="HH:mm"          // ✅ 24-hour format
                            timeIntervals={15}          // steps: 00, 15, 30, 45
                            dateFormat="yyyy-MMMM-dd HH:mm" // ✅ force display format
                            className="border p-2 rounded w-full"
                            wrapperClassName="w-full"               // ✅ force wrapper to be full width
                        />

                        <InputError message={errors.started_at} />
                    </div>

                    <div>
                        <Label htmlFor="finished_at">{t('finished_at')}</Label>

                        <DatePicker
                            selected={data.finished_at ? new Date(data.finished_at) : null}
                            onChange={(date: Date | null) => {
                                if (date) {
                                    setData('finished_at', format(date, 'yyyy-MM-dd HH:mm')); // ✅ always Y-m-d H:i
                                }
                            }}
                            showTimeSelect
                            timeFormat="HH:mm"          // ✅ 24-hour format
                            timeIntervals={15}          // steps: 00, 15, 30, 45
                            dateFormat="yyyy-MMMM-dd HH:mm" // ✅ force display format
                            className="border p-2 rounded w-full"
                            wrapperClassName="w-full"               // ✅ force wrapper to be full width
                        />

                        <InputError message={errors.finished_at} />
                    </div>


                    {/*select option tests*/}

                    <div>
                        <Label htmlFor="test_id">{t('select_test')}</Label>
                        <Select
                            value={String(data.test_id || '')}
                            onValueChange={(value) => setData('test_id', Number(value))}
                        >
                            <SelectTrigger className="w-full">
                                   <span>
                                        {data.test_id
                                            ? (() => {
                                                const selTest = tests.find((t) => t.id === data.test_id);
                                                if (!selTest) return t('select_test');
                                                return selTest.folder?.name ? `${selTest.folder.name} / ${selTest.name}` : selTest.name;
                                              })()
                                            : t('select_test')}
                                    </span>
                            </SelectTrigger>

                            <SelectContent>
                                {tests.map((test) => (
                                    <SelectItem key={test.id} value={String(test.id)}>
                                        {test.folder?.name ? `${test.folder.name} / ${test.name}` : test.name}
                                    </SelectItem>
                                ))}
                            </SelectContent>
                        </Select>

                        <InputError message={errors.test_id} />
                    </div>


                    <div>
                        <Label htmlFor="status" className="mb-3 block">
                            {t('status')}
                        </Label>
                        <label className="inline-flex items-center cursor-pointer">
                            <input
                                type="checkbox"
                                id="status"
                                className="sr-only peer"
                                checked={data.active === 1}
                                onChange={(e) => setData('active', e.target.checked ? 1 : 0)}
                            />
                            <div
                                className="relative w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 dark:peer-focus:ring-blue-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:w-5 after:h-5 after:transition-all dark:border-gray-600 peer-checked:bg-blue-600 dark:peer-checked:bg-blue-600"></div>
                        </label>
                        <InputError message={errors.active} />
                    </div>

                    <DialogFooter className="flex justify-end gap-3 pt-4 border-t border-gray-200 dark:border-gray-700">
                        <DialogClose asChild>
                            <Button
                                variant="secondary"
                                className="bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                                onClick={() => {
                                    reset();
                                    clearErrors();
                                    setOpen(false);
                                }}
                            >
                                {t('cancel')}
                            </Button>
                        </DialogClose>

                        <Button
                            type="submit"
                            disabled={processing}
                            className="bg-blue-600 text-white hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 disabled:opacity-50"
                        >
                            {t('save')}
                        </Button>
                    </DialogFooter>

                </form>
            </DialogContent>
        </Dialog>
    );
}
