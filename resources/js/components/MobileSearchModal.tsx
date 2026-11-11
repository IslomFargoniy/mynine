// components/MobileSearchModal.tsx
import React, { useState } from 'react';
import { Filter } from 'lucide-react';
import { SearchData, Role, User, Mock, Test, Folder } from '@/types';
import PremiumFilters from '@/components/premium-filters';
import { useTranslation } from 'react-i18next';
import { Button } from '@/components/ui/button';
import {
    Sheet,
    SheetContent,
    SheetHeader,
    SheetTitle,
    SheetTrigger,
} from "@/components/ui/sheet";
import { cn } from '@/lib/utils';

interface MobileSearchModalProps {
    data: SearchData;
    setData: (key: keyof SearchData, value: any) => void;
    handleSubmit: (e: React.FormEvent) => void;
    roles?: Role[];
    users?: User[];
    mocks?: Mock[];
    tests?: Test[];
    folders?: Folder[];
    isAdmin?: boolean;
}

const MobileSearchModal = ({ data, setData, handleSubmit, roles, users, mocks, tests, folders, isAdmin = false }: MobileSearchModalProps) => {
    const [isOpen, setIsOpen] = useState(false);
    const { t } = useTranslation();

    const hasActiveFilters = !!(
        data.search || 
        data.from || 
        data.to || 
        data.role || 
        data.user_id || 
        data.mock_id || 
        data.test_id || 
        data.folder_id || 
        (data.per_page && data.per_page !== 10)
    );

    return (
        <div className="lg:hidden">
            <Sheet open={isOpen} onOpenChange={setIsOpen}>
                <SheetTrigger asChild>
                    <Button 
                        variant="outline" 
                        className={cn(
                            "h-10 px-4 border rounded-full transition-all gap-2 font-bold text-xs uppercase tracking-wider relative",
                            hasActiveFilters 
                                ? "border-glass-edge bg-glass-thumb text-brand shadow-glass-pill" 
                                : "border-glass-edge text-muted-foreground"
                        )}
                    >
                        <Filter className="h-4 w-4" />
                        {t('filters')}
                        {hasActiveFilters && (
                            <span className="absolute -top-1 -right-1 flex h-2.5 w-2.5 rounded-full bg-primary border-2 border-background" />
                        )}
                    </Button>
                </SheetTrigger>
                <SheetContent side="bottom" className="rounded-t-[32px] border-t border-glass-edge p-6 min-h-[60vh] focus-visible:outline-none overflow-y-auto max-h-[90vh]">
                    <SheetHeader className="mb-6">
                        <SheetTitle className="text-xl font-black uppercase tracking-tight text-center flex items-center justify-center gap-2">
                            <Filter className="h-5 w-5 text-brand" />
                            {t('search_and_filters')}
                        </SheetTitle>
                    </SheetHeader>
                    
                    <div className="space-y-6 pb-12">
                        <div className="p-1">
                            <PremiumFilters 
                                data={data} 
                                setData={setData} 
                                handleSubmit={(e) => {
                                    handleSubmit(e);
                                    setIsOpen(false);
                                }} 
                                roles={roles}
                                users={users}
                                mocks={mocks}
                                tests={tests}
                                folders={folders}
                                isAdmin={isAdmin}
                                forceExpand={true}
                            />
                        </div>
                    </div>
                </SheetContent>
            </Sheet>
        </div>
    );
};

export default MobileSearchModal;
