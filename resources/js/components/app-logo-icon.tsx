import { ImgHTMLAttributes } from 'react';

/** The Mynine M9 mark (public/images/icons/mynine-icon.png), used wherever the app shows its icon. */
export default function AppLogoIcon({ className = '', alt = 'Mynine', ...props }: ImgHTMLAttributes<HTMLImageElement>) {
    return <img src="/images/icons/mynine-icon.png" alt={alt} className={`aspect-square w-auto rounded-xl object-contain ${className}`} {...props} />;
}
