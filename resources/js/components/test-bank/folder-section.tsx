import CreateTestModal from '@/components/test/create-test-modal';
import TestCard from '@/components/test-bank/test-card';
import { IconAction } from '@/components/ui/icon-action';
import { type Folder, type Test } from '@/types';
import { PencilIcon, TrashIcon } from 'lucide-react';
import { useTranslation } from 'react-i18next';

interface FolderSectionProps {
    folder: Folder;
    isAdmin: boolean;
    highlighted?: boolean;
    onChanged: () => void;
    onEditFolder: (folder: Folder) => void;
    onDeleteFolder: (folder: Folder) => void;
    onEditTest: (test: Test) => void;
    onDeleteTest: (test: Test) => void;
    onToggleTest: (test: Test, field: 'active' | 'open') => void;
}

/**
 * A folder of the Test Bank: header (name, comment, admin actions) and its test cards.
 */
export default function FolderSection({
    folder,
    isAdmin,
    highlighted = false,
    onChanged,
    onEditFolder,
    onDeleteFolder,
    onEditTest,
    onDeleteTest,
    onToggleTest,
}: FolderSectionProps) {
    const { t } = useTranslation();
    const tests = folder.tests ?? [];
    const folderActive = Number(folder.active) === 1;

    return (
        <section id={`folder-${folder.id}`} aria-labelledby={`folder-${folder.id}-title`} className="relative scroll-mt-24">
            <div
                className={`mb-6 flex flex-col gap-3 border-l-4 pl-4 sm:flex-row sm:items-start sm:justify-between ${
                    highlighted ? 'border-brand' : 'border-primary'
                }`}
            >
                <div className="flex min-w-0 flex-col gap-1">
                    <div className="flex flex-wrap items-center gap-2">
                        <h2 id={`folder-${folder.id}-title`} className="text-2xl font-black tracking-tight break-words text-foreground uppercase">
                            {folder.name}
                        </h2>
                        {isAdmin && !folderActive && (
                            <span
                                className="inline-flex items-center rounded-full border border-glass-edge bg-muted px-2 py-0.5 text-[10px] font-bold text-muted-foreground"
                                title={t('test_bank.hidden_hint')}
                            >
                                {t('inactive')}
                            </span>
                        )}
                    </div>
                    {folder.comment && <p className="text-sm font-medium text-muted-foreground italic">{folder.comment}</p>}
                </div>

                {isAdmin && (
                    <div className="flex shrink-0 items-center gap-1">
                        <CreateTestModal folder_id={folder.id} compact onSuccess={onChanged} />
                        <IconAction label={t('test_bank.edit_folder')} tone="brand" onClick={() => onEditFolder(folder)}>
                            <PencilIcon />
                        </IconAction>
                        <IconAction label={t('test_bank.delete_folder')} tone="danger" onClick={() => onDeleteFolder(folder)}>
                            <TrashIcon />
                        </IconAction>
                    </div>
                )}
            </div>

            {tests.length > 0 ? (
                <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                    {tests.map((test) => (
                        <TestCard
                            key={test.id}
                            test={test}
                            isAdmin={isAdmin}
                            onEdit={onEditTest}
                            onDelete={onDeleteTest}
                            onToggle={onToggleTest}
                        />
                    ))}
                </div>
            ) : (
                isAdmin && (
                    <p className="rounded-[18px] border border-dashed border-glass-dash px-4 py-6 text-center text-sm text-muted-foreground">
                        {t('test_bank.empty_folder')}
                    </p>
                )
            )}
        </section>
    );
}
