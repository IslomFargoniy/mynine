import CreateAttemptModal from '@/components/attempt/create-attempt-modal';
import { IconAction } from '@/components/ui/icon-action';
import { type Test } from '@/types';
import { Icon } from '@iconify/react';
import { Link } from '@inertiajs/react';
import { Headphones, Lock, LockOpen, PencilIcon, Power, TrashIcon } from 'lucide-react';
import { useTranslation } from 'react-i18next';

interface TestCardProps {
    test: Test;
    isAdmin: boolean;
    onEdit?: (test: Test) => void;
    onDelete?: (test: Test) => void;
    onToggle?: (test: Test, field: 'active' | 'open') => void;
}

const chipClass =
    'inline-flex items-center rounded-full border border-glass-edge bg-muted px-2 py-0.5 text-[10px] font-bold text-foreground';

/**
 * One practice test in the Test Bank. Everyone gets Start and the attempts count; admins also get
 * module chips linking to the module editor, status badges and edit / toggle / delete actions.
 */
export default function TestCard({ test, isAdmin, onEdit, onDelete, onToggle }: TestCardProps) {
    const { t } = useTranslation();
    const isActive = Number(test.active) === 1;
    const isOpen = Number(test.open) === 1;
    const hidden = !isActive || !isOpen;

    return (
        <div
            className={`group flex min-w-0 flex-col justify-between rounded-[22px] border border-glass-edge bg-card p-5 shadow-glass-pill transition-all duration-300 hover:-translate-y-1 hover:bg-accent ${
                isAdmin && hidden ? 'opacity-75' : ''
            }`}
        >
            <div className="mb-4 min-w-0">
                <div className="mb-2 flex items-start justify-between gap-2">
                    <h3 className="line-clamp-2 min-w-0 text-lg font-bold break-words text-foreground transition-colors group-hover:text-brand">
                        {test.name}
                    </h3>
                    <CreateAttemptModal test={test} />
                </div>

                {isAdmin && hidden && (
                    <div className="mb-2 flex flex-wrap gap-1" title={t('test_bank.hidden_hint')}>
                        {!isActive && <span className={`${chipClass} text-muted-foreground`}>{t('inactive')}</span>}
                        {!isOpen && <span className={`${chipClass} text-muted-foreground`}>{t('closed')}</span>}
                    </div>
                )}

                {test.comment && <p className="mb-4 line-clamp-1 text-xs font-medium text-muted-foreground">{test.comment}</p>}

                {/* Modules: admins open the module editor, students only see what the test contains */}
                <div className="mb-1 flex flex-wrap gap-1.5">
                    {test.types.map((module) =>
                        isAdmin ? (
                            <Link
                                key={module.id}
                                href={route('test-type.show', module.id)}
                                aria-label={t('test_bank.module_editor', { module: module.type?.name })}
                                title={t('test_bank.module_editor', { module: module.type?.name })}
                                className={`${chipClass} transition-colors hover:border-ring hover:text-brand`}
                            >
                                {module.type?.name}
                            </Link>
                        ) : (
                            <span key={module.id} className={chipClass}>
                                {module.type?.name}
                            </span>
                        ),
                    )}
                </div>
            </div>

            <div className="flex items-center justify-between gap-2 border-t border-divider pt-3">
                <div className="flex min-w-0 items-center gap-1.5 text-xs font-bold tracking-tighter text-muted-foreground uppercase">
                    <Icon icon="solar:users-group-rounded-linear" className="shrink-0 text-lg" />
                    <span className="truncate">
                        {test.attempts_count} {t('total_attempts')}
                    </span>
                    {isAdmin && test.audio_path && (
                        <span title={t('audio_path')} aria-label={t('audio_path')} role="img" className="shrink-0">
                            <Headphones className="size-3.5" />
                        </span>
                    )}
                </div>

                {isAdmin ? (
                    <div className="-mr-1.5 flex shrink-0 items-center">
                        <IconAction label={t('test_bank.edit_test')} tone="brand" onClick={() => onEdit?.(test)}>
                            <PencilIcon />
                        </IconAction>
                        <IconAction
                            label={isActive ? t('test_bank.deactivate') : t('test_bank.activate')}
                            tone={isActive ? 'success' : 'default'}
                            aria-pressed={isActive}
                            onClick={() => onToggle?.(test, 'active')}
                        >
                            <Power />
                        </IconAction>
                        <IconAction
                            label={isOpen ? t('test_bank.make_closed') : t('test_bank.make_open')}
                            tone={isOpen ? 'brand' : 'warning'}
                            aria-pressed={isOpen}
                            onClick={() => onToggle?.(test, 'open')}
                        >
                            {isOpen ? <LockOpen /> : <Lock />}
                        </IconAction>
                        <IconAction label={t('test_bank.delete_test')} tone="danger" onClick={() => onDelete?.(test)}>
                            <TrashIcon />
                        </IconAction>
                    </div>
                ) : (
                    <div className="h-2 w-2 rounded-full bg-primary animate-pulse" />
                )}
            </div>
        </div>
    );
}
