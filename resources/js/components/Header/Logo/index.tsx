import React from 'react';

import { Link } from '@inertiajs/react';

const Logo: React.FC = () => {

    const domain =
        typeof window !== 'undefined' ? window.location.hostname : 'mynine.uz';

    // domenni capitalize qilish (faqat birinchi harflar katta)
    const capitalizeDomain = domain
        .toLowerCase()
        .replace(/\b\w/g, (char) => char.toUpperCase());

    return (
        <Link href={route('home')} className="flex items-center gap-2">

            <h1 className={'text-3xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500'}>
                {capitalizeDomain}
            </h1>
            {/*<img*/}
            {/*    src={`${getImagePrefix()}images/logo/logo.svg`}*/}
            {/*    alt="logo"*/}
            {/*    width={160}*/}
            {/*    height={50}*/}
            {/*    style={{ width: "auto", height: "auto" }}*/}
            {/*/>*/}
        </Link>
    );
};

export default Logo;
