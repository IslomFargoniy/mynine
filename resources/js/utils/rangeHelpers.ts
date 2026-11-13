// resources/js/utils/rangeHelpers.ts

export function buildRange(fromRaw?: string | null, toRaw?: string | null): string[] {
    if (!fromRaw || !toRaw) return [];
    const from = fromRaw.trim();
    const to = toRaw.trim();

    // numbers
    if (/^\d+$/.test(from) && /^\d+$/.test(to)) {
        const a = parseInt(from, 10), b = parseInt(to, 10);
        const step = a <= b ? 1 : -1;
        const arr: string[] = [];
        for (let i = a; step > 0 ? i <= b : i >= b; i += step) arr.push(String(i));
        return arr;
    }

    // single letters ("i"–"v" / "i"–"x" are heading numbers, roman, not letters I…V / I…X)
    const romanList = from === 'i' && /^[ivx]$/.test(to);
    if (!romanList && /^[A-Za-z]$/.test(from) && /^[A-Za-z]$/.test(to)) {
        const a = from.toUpperCase().charCodeAt(0);
        const b = to.toUpperCase().charCodeAt(0);
        const step = a <= b ? 1 : -1;
        const arr: string[] = [];
        for (let code = a; step > 0 ? code <= b : code >= b; code += step) {
            arr.push(String.fromCharCode(code).toUpperCase());
        }
        return arr;
    }

    // roman numerals
    if (/^[ivxlcdm]+$/i.test(from) && /^[ivxlcdm]+$/i.test(to)) {
        const a = romanToInt(from);
        const b = romanToInt(to);
        if (Number.isNaN(a) || Number.isNaN(b)) return [];
        const step = a <= b ? 1 : -1;
        const arr: string[] = [];
        for (let n = a; step > 0 ? n <= b : n >= b; n += step) {
            arr.push(intToRoman(n).toUpperCase());
        }
        return arr;
    }

    // fallback (comma-separated list)
    return from.includes(",") && from === to
        ? from.split(",").map(s => s.trim().toUpperCase()).filter(Boolean)
        : [];
}

// helper functions
function romanToInt(roman: string): number {
    const map: Record<string, number> = {I:1, V:5, X:10, L:50, C:100, D:500, M:1000};
    let result = 0, prev = 0;
    for (let i = roman.toUpperCase().length - 1; i >= 0; i--) {
        const curr = map[roman.toUpperCase()[i]];
        if (curr < prev) result -= curr; else result += curr;
        prev = curr;
    }
    return result;
}

function intToRoman(num: number): string {
    const map: [number, string][] = [
        [1000,"M"],[900,"CM"],[500,"D"],[400,"CD"],[100,"C"],[90,"XC"],
        [50,"L"],[40,"XL"],[10,"X"],[9,"IX"],[5,"V"],[4,"IV"],[1,"I"]
    ];
    let res = "";
    for (const [val, sym] of map) {
        while (num >= val) { res += sym; num -= val; }
    }
    return res;
}
