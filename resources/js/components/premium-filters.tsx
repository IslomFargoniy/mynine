import React, { useState } from 'react';
import { Search, Filter, X, Calendar, ListOrdered, ShieldCheck, User as UserIcon, BookOpen, Layers, Folder as FolderIcon, GraduationCap } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { format } from 'date-fns';
import DatePicker from 'react-datepicker';
import "react-datepicker/dist/react-datepicker.css";
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
import { cn } from '@/lib/utils';
import { SearchData, Role, User, Mock, Test, Folder } from '@/types';

interface PremiumFiltersProps {
    handleSubmit: (e: React.FormEvent) => void;
    setData: (key: keyof SearchData, value: any) => void;
    data: SearchData;
    roles?: Role[];
    users?: User[];
    teachers?: User[];
    mocks?: Mock[];
    tests?: Test[];
    folders?: Folder[];
    forceExpand?: boolean;
    isAdmin?: boolean;
}

const PremiumFilters = ({ handleSubmit, setData, data, roles, users, teachers, mocks, tests, folders, forceExpand = false, isAdmin = false }: PremiumFiltersProps) => {
    const { t } = useTranslation();
    const [isExpanded, setIsExpanded] = useState(forceExpand);

    const hasActiveFilters = !!(
        data.from || 
        data.to || 
        data.role || 
        data.teacher_id || 
        data.user_id || 
        data.mock_id || 
        data.test_id || 
        data.folder_id || 
        (data.per_page && data.per_page !== 10)
    );

    const clearFilters = () => {
        setData('search', '');
        setData('from', '');
        setData('to', '');
        setData('role', '');
        setData('teacher_id', '');
        setData('user_id', '');
        setData('mock_id', '');
        setData('test_id', '');
        setData('folder_id', '');
        setData('per_page', 10);
    };

    return (
        <div className="w-full">
            <form onSubmit={handleSubmit} className="flex flex-col gap-3">
                {/* Single Row Container for Desktop */}
                <div className="flex flex-col lg:flex-row items-stretch lg:items-center gap-2 bg-white dark:bg-gray-950 p-1.5 lg:p-1 rounded-2xl border border-gray-200 dark:border-gray-800 shadow-sm">
                    
                    {/* Search Input - Main Field */}
                    <div className="relative flex-1 min-w-[140px]">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-gray-400" />
                        <Input
                            type="text"
                            value={data.search || ''}
                            onChange={(e) => setData('search', e.target.value)}
                            placeholder={t('search_placeholder') ?? 'Search...'}
                            className="pl-9 pr-8 h-9 border-none focus:ring-0 bg-transparent text-xs font-medium"
                        />
                        {data.search && (
                            <button
                                type="button"
                                onClick={() => setData('search', '')}
                                className="absolute right-2 top-1/2 -translate-y-1/2 p-1 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full transition-colors"
                            >
                                <X className="h-3 w-3 text-gray-400" />
                            </button>
                        )}
                    </div>

                    <div className="hidden lg:flex items-center gap-1.5 h-6 px-1 border-l border-gray-200 dark:border-gray-800" />

                    {/* Integrated Filters - Single Row on Desktop */}
                    <div className="flex flex-wrap lg:flex-nowrap items-center gap-1 lg:gap-2 flex-grow">
                        
                        {/* Desktop Selects - Compact with Icons */}
                        <div className="hidden lg:flex items-center gap-2 flex-grow justify-end">
                            {teachers && isAdmin && (
                                <Select value={String(data.teacher_id || '0')} onValueChange={(val) => setData('teacher_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-8 w-auto min-w-[100px] max-w-[140px] rounded-lg border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-900/50 text-[10px] font-bold px-2">
                                        <div className="flex items-center gap-1 truncate">
                                            <GraduationCap className="h-3 w-3 text-indigo-500 shrink-0" />
                                            <SelectValue placeholder={t('teacher') || "O'qituvchi"} />
                                        </div>
                                    </SelectTrigger>
                                    <SelectContent className="rounded-xl">
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {teachers.map((tch) => <SelectItem key={tch.id} value={String(tch.id)}>{tch.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            )}

                            {users && (
                                <Select value={String(data.user_id || '0')} onValueChange={(val) => setData('user_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-8 w-auto min-w-[100px] max-w-[140px] rounded-lg border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-900/50 text-[10px] font-bold px-2">
                                        <div className="flex items-center gap-1 truncate">
                                            <UserIcon className="h-3 w-3 text-blue-500 shrink-0" />
                                            <SelectValue placeholder={t('user')} />
                                        </div>
                                    </SelectTrigger>
                                    <SelectContent className="rounded-xl">
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {users.map((u) => <SelectItem key={u.id} value={String(u.id)}>{u.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            )}

                            {mocks && (
                                <Select value={String(data.mock_id || '0')} onValueChange={(val) => setData('mock_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-8 w-auto min-w-[100px] max-w-[140px] rounded-lg border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-900/50 text-[10px] font-bold px-2">
                                        <div className="flex items-center gap-1 truncate">
                                            <Layers className="h-3 w-3 text-orange-500 shrink-0" />
                                            <SelectValue placeholder={t('mock')} />
                                        </div>
                                    </SelectTrigger>
                                    <SelectContent className="rounded-xl">
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {mocks.map((m) => <SelectItem key={m.id} value={String(m.id)}>{m.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            )}

                            {tests && (
                                <Select value={String(data.test_id || '0')} onValueChange={(val) => setData('test_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-8 w-auto min-w-[100px] max-w-[140px] rounded-lg border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-900/50 text-[10px] font-bold px-2">
                                        <div className="flex items-center gap-1 truncate">
                                            <BookOpen className="h-3 w-3 text-green-500 shrink-0" />
                                            <SelectValue placeholder={t('test')} />
                                        </div>
                                    </SelectTrigger>
                                    <SelectContent className="rounded-xl">
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {tests.map((t) => <SelectItem key={t.id} value={String(t.id)}>{t.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            )}

                            {folders && (
                                <Select value={String(data.folder_id || '0')} onValueChange={(val) => setData('folder_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-8 w-auto min-w-[100px] max-w-[140px] rounded-lg border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-900/50 text-[10px] font-bold px-2">
                                        <div className="flex items-center gap-1 truncate">
                                            <FolderIcon className="h-3 w-3 text-purple-500 shrink-0" />
                                            <SelectValue placeholder={t('folder')} />
                                        </div>
                                    </SelectTrigger>
                                    <SelectContent className="rounded-xl">
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {folders.map((f) => <SelectItem key={f.id} value={String(f.id)}>{f.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            )}

                            {roles && isAdmin && (
                                <Select value={String(data.role || '0')} onValueChange={(val) => setData('role', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-8 w-auto min-w-[80px] rounded-lg border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-900/50 text-[10px] font-bold px-2">
                                        <div className="flex items-center gap-1 truncate">
                                            <ShieldCheck className="h-3 w-3 text-red-500 shrink-0" />
                                            <SelectValue placeholder={t('role')} />
                                        </div>
                                    </SelectTrigger>
                                    <SelectContent className="rounded-xl">
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {roles.map((r) => <SelectItem key={r.id} value={r.name}>{r.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            )}

                            {/* Per Page Selector */}
                            <Select value={String(data.per_page || '10')} onValueChange={(val) => setData('per_page', val)}>
                                <SelectTrigger className="h-8 w-[70px] rounded-lg border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-900/50 text-[10px] font-bold px-2">
                                    <div className="flex items-center gap-1 truncate">
                                        <ListOrdered className="h-3 w-3 text-purple-500 shrink-0" />
                                        <SelectValue placeholder="10" />
                                    </div>
                                </SelectTrigger>
                                <SelectContent className="rounded-xl">
                                    <SelectItem value="10">10</SelectItem>
                                    <SelectItem value="20">20</SelectItem>
                                    <SelectItem value="50">50</SelectItem>
                                    <SelectItem value="all">{t('all')}</SelectItem>
                                </SelectContent>
                            </Select>

                            {/* Ultra Compact Date Pickers */}
                            <div className="flex items-center gap-1 bg-gray-50/50 dark:bg-gray-900/50 border border-gray-100 dark:border-gray-800 rounded-lg px-2 h-8">
                                <Calendar className="h-3 w-3 text-blue-500 shrink-0" />
                                <DatePicker
                                    selected={data.from ? new Date(data.from) : null}
                                    onChange={(date) => setData('from', date ? format(date, 'yyyy-MM-dd') : '')}
                                    placeholderText={t('from')}
                                    className="w-[65px] bg-transparent border-none p-0 text-[10px] font-bold focus:ring-0 h-full"
                                />
                                <span className="text-gray-300 dark:text-gray-700 mx-0.5">-</span>
                                <DatePicker
                                    selected={data.to ? new Date(data.to) : null}
                                    onChange={(date) => setData('to', date ? format(date, 'yyyy-MM-dd') : '')}
                                    placeholderText={t('to')}
                                    className="w-[65px] bg-transparent border-none p-0 text-[10px] font-bold focus:ring-0 h-full"
                                />
                            </div>
                        </div>

                        {/* Mobile/Compact Expand Button */}
                        <div className="flex items-center gap-1.5 lg:hidden w-full">
                           <Button
                                type="button"
                                variant="outline"
                                onClick={() => setIsExpanded(!isExpanded)}
                                className={cn(
                                    "h-10 px-4 flex-1 border rounded-xl transition-all gap-2 font-bold text-[11px] uppercase tracking-wider",
                                    isExpanded || hasActiveFilters 
                                        ? "border-blue-200 bg-blue-50/50 text-blue-600 dark:border-blue-900/50 dark:bg-blue-900/20 dark:text-blue-400" 
                                        : "border-gray-200 dark:border-gray-800 text-gray-600 dark:text-gray-400"
                                )}
                            >
                                <Filter className="h-4 w-4" />
                                {t('filters')}
                            </Button>
                        </div>

                        {/* Action Buttons */}
                        <div className="flex items-center gap-1.5 shrink-0 ml-auto">
                            {hasActiveFilters && (
                                <Button 
                                    type="button" 
                                    variant="ghost" 
                                    onClick={clearFilters}
                                    className="h-8 px-2 rounded-lg text-red-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 text-[9px] font-black uppercase tracking-widest transition-all"
                                >
                                    <X className="h-3 w-3" />
                                </Button>
                            )}
                            
                            <Button 
                                type="submit" 
                                className="h-8 px-4 rounded-lg bg-blue-600 hover:bg-blue-700 text-white font-black text-[10px] uppercase tracking-widest shadow-md shadow-blue-500/10 active:scale-95 transition-all"
                            >
                                <Search className="h-3.5 w-3.5 lg:hidden" />
                                <span className="hidden lg:inline">{t('apply')}</span>
                            </Button>
                        </div>
                    </div>
                </div>

                {/* Advanced Filters Area - Only for Mobile */}
                <div className={cn(
                    "overflow-hidden transition-all duration-300 ease-in-out lg:hidden",
                    isExpanded ? "max-h-[800px] opacity-100 visible" : "max-h-0 opacity-0 invisible"
                )}>
                    <div className="p-4 rounded-2xl border border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-900/50 grid grid-cols-1 sm:grid-cols-2 gap-4">
                        {teachers && isAdmin && (
                            <div className="space-y-1.5">
                                <label className="text-[9px] font-black uppercase tracking-widest text-gray-400 dark:text-gray-500 flex items-center gap-1.5 ml-1">
                                    <GraduationCap className="h-3 w-3" /> {t('teacher') || "O'qituvchi"}
                                </label>
                                <Select value={String(data.teacher_id || '0')} onValueChange={(val) => setData('teacher_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-10 rounded-xl bg-white dark:bg-gray-950 font-bold text-xs">
                                        <SelectValue placeholder={t('select_teacher') || "O'qituvchini tanlang"} />
                                    </SelectTrigger>
                                    <SelectContent className="rounded-xl">
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {teachers.map((tch) => <SelectItem key={tch.id} value={String(tch.id)}>{tch.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            </div>
                        )}

                        {users && (
                            <div className="space-y-1.5">
                                <label className="text-[9px] font-black uppercase tracking-widest text-gray-400 dark:text-gray-500 flex items-center gap-1.5 ml-1">
                                    <UserIcon className="h-3 w-3" /> {t('user')}
                                </label>
                                <Select value={String(data.user_id || '0')} onValueChange={(val) => setData('user_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-10 rounded-xl bg-white dark:bg-gray-950 font-bold text-xs">
                                        <SelectValue placeholder={t('select_user')} />
                                    </SelectTrigger>
                                    <SelectContent className="rounded-xl">
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {users.map((u) => <SelectItem key={u.id} value={String(u.id)}>{u.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            </div>
                        )}

                        {mocks && (
                            <div className="space-y-1.5">
                                <label className="text-[9px] font-black uppercase tracking-widest text-gray-400 dark:text-gray-500 flex items-center gap-1.5 ml-1">
                                    <Layers className="h-3 w-3" /> {t('mock')}
                                </label>
                                <Select value={String(data.mock_id || '0')} onValueChange={(val) => setData('mock_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-10 rounded-xl bg-white dark:bg-gray-950 font-bold text-xs">
                                        <SelectValue placeholder={t('select_mock')} />
                                    </SelectTrigger>
                                    <SelectContent className="rounded-xl">
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {mocks.map((m) => <SelectItem key={m.id} value={String(m.id)}>{m.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            </div>
                        )}

                        {tests && (
                            <div className="space-y-1.5">
                                <label className="text-[9px] font-black uppercase tracking-widest text-gray-400 dark:text-gray-500 flex items-center gap-1.5 ml-1">
                                    <BookOpen className="h-3 w-3" /> {t('test')}
                                </label>
                                <Select value={String(data.test_id || '0')} onValueChange={(val) => setData('test_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-10 rounded-xl bg-white dark:bg-gray-950 font-bold text-xs">
                                        <SelectValue placeholder={t('select_test')} />
                                    </SelectTrigger>
                                    <SelectContent className="rounded-xl">
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {tests.map((t) => <SelectItem key={t.id} value={String(t.id)}>{t.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            </div>
                        )}

                        {folders && (
                            <div className="space-y-1.5">
                                <label className="text-[9px] font-black uppercase tracking-widest text-gray-400 dark:text-gray-500 flex items-center gap-1.5 ml-1">
                                    <FolderIcon className="h-3 w-3" /> {t('folder')}
                                </label>
                                <Select value={String(data.folder_id || '0')} onValueChange={(val) => setData('folder_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-10 rounded-xl bg-white dark:bg-gray-950 font-bold text-xs">
                                        <SelectValue placeholder={t('select_folder')} />
                                    </SelectTrigger>
                                    <SelectContent className="rounded-xl">
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {folders.map((f) => <SelectItem key={f.id} value={String(f.id)}>{f.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            </div>
                        )}

                        {roles && isAdmin && (
                            <div className="space-y-1.5">
                                <label className="text-[9px] font-black uppercase tracking-widest text-gray-400 dark:text-gray-500 flex items-center gap-1.5 ml-1">
                                    <ShieldCheck className="h-3 w-3" /> {t('role')}
                                </label>
                                <Select value={String(data.role || '0')} onValueChange={(val) => setData('role', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-10 rounded-xl bg-white dark:bg-gray-950 font-bold text-xs">
                                        <SelectValue placeholder={t('select_role')} />
                                    </SelectTrigger>
                                    <SelectContent className="rounded-xl">
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {roles.map((r) => <SelectItem key={r.id} value={r.name}>{r.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            </div>
                        )}

                        <div className="space-y-1.5">
                            <label className="text-[9px] font-black uppercase tracking-widest text-gray-400 dark:text-gray-500 flex items-center gap-1.5 ml-1">
                                <Calendar className="h-3 w-3" /> {t('date_range')}
                            </label>
                            <div className="flex items-center gap-2">
                                <DatePicker
                                    selected={data.from ? new Date(data.from) : null}
                                    onChange={(date) => setData('from', date ? format(date, 'yyyy-MM-dd') : '')}
                                    placeholderText={t('from')}
                                    className="flex-1 h-10 rounded-xl border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-950 text-xs font-bold"
                                />
                                <DatePicker
                                    selected={data.to ? new Date(data.to) : null}
                                    onChange={(date) => setData('to', date ? format(date, 'yyyy-MM-dd') : '')}
                                    placeholderText={t('to')}
                                    className="flex-1 h-10 rounded-xl border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-950 text-xs font-bold"
                                />
                            </div>
                        </div>

                        <div className="space-y-1.5">
                            <label className="text-[9px] font-black uppercase tracking-widest text-gray-400 dark:text-gray-500 flex items-center gap-1.5 ml-1">
                                <ListOrdered className="h-3 w-3" /> {t('per_page') ?? 'Per Page'}
                            </label>
                            <Select value={String(data.per_page || '10')} onValueChange={(val) => setData('per_page', val)}>
                                <SelectTrigger className="h-10 rounded-xl bg-white dark:bg-gray-950 font-bold text-xs">
                                    <SelectValue placeholder="10" />
                                </SelectTrigger>
                                <SelectContent className="rounded-xl">
                                    <SelectItem value="10">10</SelectItem>
                                    <SelectItem value="20">20</SelectItem>
                                    <SelectItem value="50">50</SelectItem>
                                    <SelectItem value="all">{t('all')}</SelectItem>
                                </SelectContent>
                            </Select>
                        </div>
                    </div>
                </div>
            </form>
        </div>
    );
};

export default PremiumFilters;
