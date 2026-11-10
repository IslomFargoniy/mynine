import { type BreadcrumbItem, type Test } from '@/types';
import { type TFunction } from 'i18next';

/**
 * Leading breadcrumbs of the content editor pages (module, part): Folders -> folder -> test for
 * practice tests, Mock Bank -> test for Mock Bank tests (which have no folder).
 */
export function contentBreadcrumbs(test: Test | null | undefined, t: TFunction): BreadcrumbItem[] {
    const testName = test?.name || t('test') || 'Test';
    const folder = test?.folder;

    if (test?.purpose === 'mock' || (test && !folder)) {
        const bank = route('mock-bank.index');
        return [
            { title: t('exam_admin.nav.mock_bank'), href: bank },
            ...(test ? [{ title: testName, href: route('mock-bank.index', { search: test.name }) }] : []),
        ];
    }

    const folderList = route('folder.index');
    return [
        { title: t('folders') || 'Jildlar', href: folderList },
        ...(folder?.id ? [{ title: folder.name || t('folder') || 'Jild', href: route('folder.show', folder.id) }] : []),
        ...(test?.id ? [{ title: testName, href: folder?.id ? route('folder.show', folder.id) : folderList }] : []),
    ];
}
