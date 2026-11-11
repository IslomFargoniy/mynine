import { type BreadcrumbItem, type Test } from '@/types';
import { type TFunction } from 'i18next';

/**
 * Leading breadcrumbs of the content editor pages (module, part): Test Bank -> folder -> test for
 * practice tests, Mock Bank -> test for Mock Bank tests (which have no folder).
 */
export function contentBreadcrumbs(test: Test | null | undefined, t: TFunction): BreadcrumbItem[] {
    const testName = test?.name || t('test');
    const folder = test?.folder;

    if (test?.purpose === 'mock' || (test && !folder)) {
        const bank = route('mock-bank.index');
        return [
            { title: t('exam_admin.nav.mock_bank'), href: bank },
            ...(test ? [{ title: testName, href: route('mock-bank.index', { search: test.name }) }] : []),
        ];
    }

    const bank = route('test-bank.index');
    const folderHref = folder?.id ? route('test-bank.index', { folder_id: folder.id }) : bank;
    return [
        { title: t('test_bank.title'), href: bank },
        ...(folder?.id ? [{ title: folder.name || t('folder'), href: folderHref }] : []),
        ...(test?.id ? [{ title: testName, href: folderHref }] : []),
    ];
}
