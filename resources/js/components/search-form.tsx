import React, {} from 'react';
import { Role, SearchData } from '@/types';
import { Search } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { format } from 'date-fns';
import DatePicker from 'react-datepicker';


interface SearchFormProps {
    handleSubmit: (e: React.FormEvent<HTMLFormElement>) => void;
    setData: <K extends keyof SearchData>(key: K, value: SearchData[K]) => void;
    data: SearchData;
    roles?: Role[];
}

const SearchForm = ({ handleSubmit, setData, data, roles }: SearchFormProps) => {

    const { t } = useTranslation(); // Hook to access translations

    const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
        setData('search', e.target.value);
    };

    const handleMonth = (e: React.ChangeEvent<HTMLInputElement>) => {
        setData('month', e.target.value);
    };

    const handlePerPageChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
        setData('per_page', parseInt(e.target.value, 10));  // parse as number
    };

    const handleRoleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
        const role = e.target.value;
        setData('role', role);
    };


    return (
        <form onSubmit={handleSubmit}>
            {/*<div className="inline-flex rounded shadow-xs flex-wrap gap-y-1" role="group">*/}
            <div
                className="flex flex-col lg:gap-0 gap-2 sm:gap-2 lg:flex-row lg:inline-flex lg:flex-wrap lg:gap-y-1 rounded shadow-xs"
                role="group">

                {/* Search Bar */}
                <input
                    type="text"
                    value={data.search}
                    onChange={handleSearch}
                    className="px-4 py-2 text-sm font-medium text-gray-900 bg-white border border-gray-200
                    rounded
                    hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-2 focus:ring-blue-700
                    focus:text-blue-700 dark:bg-gray-800 dark:border-gray-700
                    dark:text-white dark:hover:text-white
                    dark:hover:bg-gray-700 dark:focus:ring-blue-500 dark:focus:text-white"
                    placeholder={t('search')}
                />

                {roles &&
                    <select
                        value={data.role || ''}
                        onChange={handleRoleChange}
                        className="px-4 py-2 text-sm font-medium text-gray-900 bg-white  border rounded  border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:bg-gray-800 dark:border-gray-700 dark:text-white dark:hover:text-white dark:hover:bg-gray-700 dark:focus:ring-blue-500 dark:focus:text-white"
                    >
                        {data.role}
                        <option value="0">{t('role')}</option>
                        {roles.map((role) => (
                            <option key={role.id} value={role.name}>
                                {role.name}
                            </option>
                        ))}
                    </select>
                }

                {typeof data.total === 'number' &&
                    <select
                        value={data.per_page}
                        onChange={handlePerPageChange}
                        className="px-4 py-2 text-sm font-medium text-gray-900 bg-white border rounded border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:bg-gray-800 dark:border-gray-700 dark:text-white dark:hover:text-white dark:hover:bg-gray-700 dark:focus:ring-blue-500 dark:focus:text-white">

                        <option value={10}>10</option>
                        <option value={25}>25</option>
                        <option value={50}>50</option>
                        <option value={data.total}>{t('pagination_optionAll')}</option>
                    </select>
                }

                <div className={'flex-column justify-between items-center'}>
                    {typeof data.from === 'string' &&
                        <DatePicker
                            id="from-date"
                            placeholderText={t('from')}
                            value={data.from}
                            onChange={(from) => {
                                setData('from', from ? format(from, 'yyyy-MM-dd') : '');
                            }}
                            className="px-4 py-2 text-sm font-medium text-gray-900 bg-white
                        border rounded border-gray-200 hover:bg-gray-100 hover:text-blue-700
                        focus:z-10 focus:ring-2 focus:ring-blue-700 focus:text-blue-700
                        dark:bg-gray-800 dark:border-gray-700 dark:text-white dark:hover:text-white dark:hover:bg-gray-700
                        dark:focus:ring-blue-500 dark:focus:text-white"
                        />
                    }

                    {typeof data.to === 'string' &&
                        <DatePicker
                            id="to-date"
                            placeholderText={t('to')}
                            value={data.to}
                            onChange={(to) => {
                                setData('to', to ? format(to, 'yyyy-MM-dd') : '');
                            }}
                            className="px-4 py-2 text-sm font-medium text-gray-900 bg-white  border rounded  border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:bg-gray-800 dark:border-gray-700 dark:text-white dark:hover:text-white dark:hover:bg-gray-700 dark:focus:ring-blue-500 dark:focus:text-white"
                        />
                    }
                </div>


                {typeof data.month === 'string' &&
                    <input
                        type="month"
                        value={data.month}
                        max={format(new Date(), 'yyyy-MM')}
                        onChange={handleMonth}
                        className="px-4 py-2 text-sm font-medium text-gray-900 bg-white  border rounded  border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:bg-gray-800 dark:border-gray-700 dark:text-white dark:hover:text-white dark:hover:bg-gray-700 dark:focus:ring-blue-500 dark:focus:text-white"
                        placeholder={t('month')}
                    />
                }

                {typeof data.date === 'string' &&
                    <DatePicker
                        id="date"
                        placeholderText={t('date')}
                        value={data.date}
                        onChange={(date) => {
                            setData('date', date ? format(date, 'yyyy-MM-dd') : '');
                        }}
                        className="px-4 py-2 text-sm font-medium text-gray-900 bg-white  border rounded  border-gray-200 hover:bg-gray-100 hover:text-blue-700 focus:z-10 focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:bg-gray-800 dark:border-gray-700 dark:text-white dark:hover:text-white dark:hover:bg-gray-700 dark:focus:ring-blue-500 dark:focus:text-white"
                    />
                }


                {/* Submit button to apply filter */}
                <button
                    type="submit"
                    className="flex items-center justify-center gap-2 bg-blue-700 hover:bg-blue-800 focus:outline-none dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800 px-4 py-2 text-sm font-medium text-gray-900 border border-gray-200 rounded hover:text-blue-700 focus:z-10 focus:ring-2 focus:ring-blue-700 focus:text-blue-700 dark:border-gray-700 dark:text-white dark:hover:text-white dark:focus:text-white"
                >
                    <Search className="text-white dark:text-white" size={20} />
                    <span className="lg:hidden">{t('search')}</span>
                </button>

            </div>
        </form>

    );
};

export default SearchForm;
