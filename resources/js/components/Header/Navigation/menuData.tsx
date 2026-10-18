import { HeaderItem } from '@/types/menu';

export const headerData: HeaderItem[] = [
    { label: 'header.menu.home', href: '#' },
    { label: 'header.menu.tests', href: '/all-test' },
    { label: 'header.menu.mock_test', href: '/ielts-mock-test', external: true },
    { label: 'header.menu.blog', href: '/blog', external: true },
    { label: 'header.menu.contact', href: '#contact' }
];
