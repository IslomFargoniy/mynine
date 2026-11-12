import React, { useState } from 'react';
import { Search, Filter, X, Calendar, ListOrdered, ShieldCheck, User as UserIcon, BookOpen, Layers, Folder as FolderIcon } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { format } from 'date-fns';
import { serverWallClock } from '@/lib/server-time';
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
    mocks?: Mock[];
    tests?: Test[];
    folders?: Folder[];
    forceExpand?: boolean;
    isAdmin?: boolean;
    /** What the from/to dates filter on (e.g. "Exam date"); defaults to the generic date range label. */
    dateLabel?: string;
}

const PremiumFilters = ({ handleSubmit, setData, data, roles, users, mocks, tests, folders, forceExpand = false, isAdmin = false, dateLabel }: PremiumFiltersProps) => {
    const { t } = useTranslation();
    const [isExpanded, setIsExpanded] = useState(forceExpand);

    const hasActiveFilters = !!(
        data.from || 
        data.to || 
        data.role || 
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
                <div className="flex flex-col lg:flex-row items-stretch lg:items-center gap-2 glass p-1.5 lg:p-1 rounded-[22px] lg:rounded-full">
                    
                    {/* Search Input - Main Field */}
                    <div className="relative flex-1 min-w-[140px]">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground" />
                        <Input
                            type="text"
                            value={data.search || ''}
                            onChange={(e) => setData('search', e.target.value)}
                            placeholder={t('search_placeholder')}
                            className="pl-9 pr-8 h-9 rounded-full border-none shadow-none focus:ring-0 bg-transparent text-xs font-medium"
                        />
                        {data.search && (
                            <button
                                type="button"
                                onClick={() => setData('search', '')}
                                className="absolute right-2 top-1/2 -translate-y-1/2 p-1 hover:bg-accent rounded-full transition-colors"
                            >
                                <X className="h-3 w-3 text-muted-foreground" />
                            </button>
                        )}
                    </div>

                    <div className="hidden lg:flex items-center gap-1.5 h-6 px-1 border-l border-divider" />

                    {/* Integrated Filters - Single Row on Desktop */}
                    <div className="flex flex-wrap lg:flex-nowrap items-center gap-1 lg:gap-2 flex-grow">
                        
                        {/* Desktop Selects - Compact with Icons */}
                        <div className="hidden lg:flex items-center gap-2 flex-grow justify-end">

                            {users && (
                                <Select value={String(data.user_id || '0')} onValueChange={(val) => setData('user_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-8 w-auto min-w-[100px] max-w-[140px] rounded-full border-glass-edge bg-glass-subtle text-[10px] font-bold px-3">
                                        <div className="flex items-center gap-1 truncate">
                                            <UserIcon className="h-3 w-3 text-brand shrink-0" />
                                            <SelectValue placeholder={t('user')} />
                                        </div>
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {users.map((u) => <SelectItem key={u.id} value={String(u.id)}>{u.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            )}

                            {mocks && (
                                <Select value={String(data.mock_id || '0')} onValueChange={(val) => setData('mock_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-8 w-auto min-w-[100px] max-w-[140px] rounded-full border-glass-edge bg-glass-subtle text-[10px] font-bold px-3">
                                        <div className="flex items-center gap-1 truncate">
                                            <Layers className="h-3 w-3 text-amber-700 dark:text-amber-300 shrink-0" />
                                            <SelectValue placeholder={t('mock')} />
                                        </div>
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {mocks.map((m) => <SelectItem key={m.id} value={String(m.id)}>{m.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            )}

                            {tests && (
                                <Select value={String(data.test_id || '0')} onValueChange={(val) => setData('test_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-8 w-auto min-w-[100px] max-w-[140px] rounded-full border-glass-edge bg-glass-subtle text-[10px] font-bold px-3">
                                        <div className="flex items-center gap-1 truncate">
                                            <BookOpen className="h-3 w-3 text-emerald-700 dark:text-emerald-300 shrink-0" />
                                            <SelectValue placeholder={t('test')} />
                                        </div>
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {tests.map((t) => <SelectItem key={t.id} value={String(t.id)}>{t.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            )}

                            {folders && (
                                <Select value={String(data.folder_id || '0')} onValueChange={(val) => setData('folder_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-8 w-auto min-w-[100px] max-w-[140px] rounded-full border-glass-edge bg-glass-subtle text-[10px] font-bold px-3">
                                        <div className="flex items-center gap-1 truncate">
                                            <FolderIcon className="h-3 w-3 text-violet-700 dark:text-violet-300 shrink-0" />
                                            <SelectValue placeholder={t('folder')} />
                                        </div>
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {folders.map((f) => <SelectItem key={f.id} value={String(f.id)}>{f.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            )}

                            {roles && isAdmin && (
                                <Select value={String(data.role || '0')} onValueChange={(val) => setData('role', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-8 w-auto min-w-[80px] rounded-full border-glass-edge bg-glass-subtle text-[10px] font-bold px-3">
                                        <div className="flex items-center gap-1 truncate">
                                            <ShieldCheck className="h-3 w-3 text-rose-700 dark:text-rose-300 shrink-0" />
                                            <SelectValue placeholder={t('role')} />
                                        </div>
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {roles.map((r) => <SelectItem key={r.id} value={r.name}>{r.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            )}

                            {/* Per Page Selector */}
                            <Select value={String(data.per_page || '10')} onValueChange={(val) => setData('per_page', val)}>
                                <SelectTrigger className="h-8 w-[70px] rounded-full border-glass-edge bg-glass-subtle text-[10px] font-bold px-3">
                                    <div className="flex items-center gap-1 truncate">
                                        <ListOrdered className="h-3 w-3 text-brand shrink-0" />
                                        <SelectValue placeholder="10" />
                                    </div>
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="10">10</SelectItem>
                                    <SelectItem value="20">20</SelectItem>
                                    <SelectItem value="50">50</SelectItem>
                                    <SelectItem value="all">{t('all')}</SelectItem>
                                </SelectContent>
                            </Select>

                            {/* Ultra Compact Date Pickers */}
                            <div className="flex items-center gap-1 bg-glass-subtle border border-glass-edge rounded-full px-3 h-8" title={dateLabel ?? t('date_range')}>
                                <Calendar className="h-3 w-3 text-brand shrink-0" />
                                {dateLabel && <span className="shrink-0 text-[10px] font-bold text-muted-foreground">{dateLabel}</span>}
                                <DatePicker
                                    selected={serverWallClock(data.from)}
                                    onChange={(date) => setData('from', date ? format(date, 'yyyy-MM-dd') : '')}
                                    placeholderText={t('from')}
                                    className="w-[65px] bg-transparent border-none p-0 text-[10px] font-bold focus:ring-0 h-full"
                                />
                                <span className="text-muted-foreground mx-0.5">-</span>
                                <DatePicker
                                    selected={serverWallClock(data.to)}
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
                                    "h-10 px-4 flex-1 border rounded-full transition-all gap-2 font-bold text-[11px] uppercase tracking-wider",
                                    isExpanded || hasActiveFilters 
                                        ? "border-glass-edge bg-glass-thumb text-brand shadow-glass-pill" 
                                        : "border-glass-edge text-muted-foreground"
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
                                    className="h-8 px-2 rounded-full text-rose-700 dark:text-rose-300 hover:text-rose-800 dark:hover:text-rose-200 hover:bg-rose-500/12 dark:hover:bg-rose-400/15 text-[9px] font-black uppercase tracking-widest transition-all"
                                >
                                    <X className="h-3 w-3" />
                                </Button>
                            )}
                            
                            <Button 
                                type="submit" 
                                className="h-8 px-4 rounded-full btn-glass-primary hover:brightness-110 font-black text-[10px] uppercase tracking-widest active:scale-95 transition-all"
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
                    <div className="glass p-4 rounded-[22px] grid grid-cols-1 sm:grid-cols-2 gap-4">

                        {users && (
                            <div className="space-y-1.5">
                                <label className="text-[9px] font-black uppercase tracking-widest text-muted-foreground flex items-center gap-1.5 ml-1">
                                    <UserIcon className="h-3 w-3" /> {t('user')}
                                </label>
                                <Select value={String(data.user_id || '0')} onValueChange={(val) => setData('user_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-10 rounded-xl bg-glass-subtle font-bold text-xs">
                                        <SelectValue placeholder={t('select_user')} />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {users.map((u) => <SelectItem key={u.id} value={String(u.id)}>{u.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            </div>
                        )}

                        {mocks && (
                            <div className="space-y-1.5">
                                <label className="text-[9px] font-black uppercase tracking-widest text-muted-foreground flex items-center gap-1.5 ml-1">
                                    <Layers className="h-3 w-3" /> {t('mock')}
                                </label>
                                <Select value={String(data.mock_id || '0')} onValueChange={(val) => setData('mock_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-10 rounded-xl bg-glass-subtle font-bold text-xs">
                                        <SelectValue placeholder={t('select_mock')} />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {mocks.map((m) => <SelectItem key={m.id} value={String(m.id)}>{m.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            </div>
                        )}

                        {tests && (
                            <div className="space-y-1.5">
                                <label className="text-[9px] font-black uppercase tracking-widest text-muted-foreground flex items-center gap-1.5 ml-1">
                                    <BookOpen className="h-3 w-3" /> {t('test')}
                                </label>
                                <Select value={String(data.test_id || '0')} onValueChange={(val) => setData('test_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-10 rounded-xl bg-glass-subtle font-bold text-xs">
                                        <SelectValue placeholder={t('select_test')} />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {tests.map((t) => <SelectItem key={t.id} value={String(t.id)}>{t.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            </div>
                        )}

                        {folders && (
                            <div className="space-y-1.5">
                                <label className="text-[9px] font-black uppercase tracking-widest text-muted-foreground flex items-center gap-1.5 ml-1">
                                    <FolderIcon className="h-3 w-3" /> {t('folder')}
                                </label>
                                <Select value={String(data.folder_id || '0')} onValueChange={(val) => setData('folder_id', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-10 rounded-xl bg-glass-subtle font-bold text-xs">
                                        <SelectValue placeholder={t('select_folder')} />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {folders.map((f) => <SelectItem key={f.id} value={String(f.id)}>{f.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            </div>
                        )}

                        {roles && isAdmin && (
                            <div className="space-y-1.5">
                                <label className="text-[9px] font-black uppercase tracking-widest text-muted-foreground flex items-center gap-1.5 ml-1">
                                    <ShieldCheck className="h-3 w-3" /> {t('role')}
                                </label>
                                <Select value={String(data.role || '0')} onValueChange={(val) => setData('role', val === '0' ? '' : val)}>
                                    <SelectTrigger className="h-10 rounded-xl bg-glass-subtle font-bold text-xs">
                                        <SelectValue placeholder={t('select_role')} />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="0">{t('all')}</SelectItem>
                                        {roles.map((r) => <SelectItem key={r.id} value={r.name}>{r.name}</SelectItem>)}
                                    </SelectContent>
                                </Select>
                            </div>
                        )}

                        <div className="space-y-1.5">
                            <label className="text-[9px] font-black uppercase tracking-widest text-muted-foreground flex items-center gap-1.5 ml-1">
                                <Calendar className="h-3 w-3" /> {dateLabel ?? t('date_range')}
                            </label>
                            <div className="flex items-center gap-2">
                                <DatePicker
                                    selected={serverWallClock(data.from)}
                                    onChange={(date) => setData('from', date ? format(date, 'yyyy-MM-dd') : '')}
                                    placeholderText={t('from')}
                                    className="flex-1 h-10 rounded-xl border border-input bg-glass-subtle px-3 text-foreground text-xs font-bold"
                                />
                                <DatePicker
                                    selected={serverWallClock(data.to)}
                                    onChange={(date) => setData('to', date ? format(date, 'yyyy-MM-dd') : '')}
                                    placeholderText={t('to')}
                                    className="flex-1 h-10 rounded-xl border border-input bg-glass-subtle px-3 text-foreground text-xs font-bold"
                                />
                            </div>
                        </div>

                        <div className="space-y-1.5">
                            <label className="text-[9px] font-black uppercase tracking-widest text-muted-foreground flex items-center gap-1.5 ml-1">
                                <ListOrdered className="h-3 w-3" /> {t('per_page')}
                            </label>
                            <Select value={String(data.per_page || '10')} onValueChange={(val) => setData('per_page', val)}>
                                <SelectTrigger className="h-10 rounded-xl bg-glass-subtle font-bold text-xs">
                                    <SelectValue placeholder="10" />
                                </SelectTrigger>
                                <SelectContent>
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
