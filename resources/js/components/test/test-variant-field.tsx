import { useTranslation } from 'react-i18next';

import InputError from '@/components/input-error';
import { Label } from '@/components/ui/label';

export type TestVariant = 'academic' | 'general';

/** IELTS variant of a test: General Training Reading uses its own band table. */
export default function TestVariantField({
    value,
    onChange,
    error,
}: {
    value: TestVariant;
    onChange: (value: TestVariant) => void;
    error?: string;
}) {
    const { t } = useTranslation();

    return (
        <div className="space-y-1">
            <Label htmlFor="variant" className="text-sm font-semibold text-foreground/80">
                {t('test_variant.label')}
            </Label>
            <select
                id="variant"
                value={value}
                onChange={(e) => onChange(e.target.value as TestVariant)}
                className="h-9 w-full rounded-md border border-input bg-transparent px-3 text-sm text-foreground shadow-xs outline-none focus-visible:ring-2 focus-visible:ring-ring/50"
            >
                <option value="academic">{t('test_variant.academic')}</option>
                <option value="general">{t('test_variant.general')}</option>
            </select>
            <p className="text-[11px] text-muted-foreground">{t('test_variant.hint')}</p>
            <InputError message={error} />
        </div>
    );
}
