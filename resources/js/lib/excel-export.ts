import * as XLSX from 'xlsx';
import { saveAs } from 'file-saver';
import { Attempt } from '@/types';
import { formatServerTime } from '@/lib/server-time';

export const exportAttemptsToExcel = (attempts: Attempt[], fileName: string = 'Attempts_Export') => {
    // 1. Prepare the data for Excel - Flattening nested structures
    const worksheetData = attempts.map((item, index) => {
        const row: any = {
            '#': index + 1,
            'User Name': item?.user?.name || item?.mock_student?.name || (item as any)?.mockStudent?.name || '---',
            'User Email': item?.user?.email || '---',
            'Attempt Name': item.name || item?.mock_student?.name || (item as any)?.mockStudent?.name || item?.user?.name || '---',
            'Test/Mock': item?.mock?.name || item?.test?.folder?.name || '---',
            'Specific Test': item?.test?.name || '---',
            'Status': item.finished_at ? 'Finished' : 'In Progress',
            'Started At': formatServerTime(item.started_at, 'yyyy-MM-dd HH:mm:ss', '---'),
            'Finished At': formatServerTime(item.finished_at, 'yyyy-MM-dd HH:mm:ss', '---'),
        };

        // Add scores from attempt_types
        item.attempt_types?.forEach((at) => {
            const typeName = at.type.name;
            const score = typeName === 'Writing'
                ? (at.band ?? null)
                : typeName === 'Speaking'
                    ? at.score
                    : at.is_correct_count;
            
            row[typeName] = score;
        });

        return row;
    });

    // 2. Create the worksheet
    const worksheet = XLSX.utils.json_to_sheet(worksheetData);

    // 3. Create the workbook
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Attempts');

    // 4. Generate buffer
    const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });

    // 5. Save the file
    const data = new Blob([excelBuffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=UTF-8' });
    saveAs(data, `${fileName}_${formatServerTime(new Date(), 'yyyy-MM-dd')}.xlsx`);
};

/**
 * Generic export: one sheet per entry, each a list of flat rows (column title => value).
 */
export const exportSheetsToExcel = (sheets: { name: string; rows: Record<string, string | number | null>[] }[], fileName: string) => {
    const workbook = XLSX.utils.book_new();
    sheets.forEach((sheet) => {
        XLSX.utils.book_append_sheet(workbook, XLSX.utils.json_to_sheet(sheet.rows), sheet.name.slice(0, 31));
    });

    const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    const data = new Blob([excelBuffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=UTF-8' });
    saveAs(data, `${fileName}.xlsx`);
};
