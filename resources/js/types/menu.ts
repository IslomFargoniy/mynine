export type SubmenuItem = {
    label: string;
    href: string;
  };    
  
  export type HeaderItem = {
    label: string;
    href: string;
    /** Server-rendered (non-Inertia) page: navigate with a full page load. */
    external?: boolean;
    submenu?: SubmenuItem[];
  };