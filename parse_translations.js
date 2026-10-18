import fs from 'node:fs';
import path from 'node:path';

const tsxRegex = /t\(\s*(['"])(.*?)\1\s*\)/g;
const phpRegex = /__\(\s*(['"])(.*?)\1\s*\)/g;

let allKeys = new Set();

function walk(dir) {
    if(!fs.existsSync(dir)) return;
    const files = fs.readdirSync(dir);
    for (const file of files) {
        if (file === 'vendor' || file === 'node_modules' || file === 'public' || file === 'storage') continue;
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            walk(fullPath);
        } else {
            if (fullPath.match(/\.(ts|tsx|js|jsx|vue)$/)) {
                const content = fs.readFileSync(fullPath, 'utf8');
                let match;
                while ((match = tsxRegex.exec(content)) !== null) {
                    if(!match[2].includes('${'))
                        allKeys.add(match[2]);
                }
            }
            if (fullPath.match(/\.(php)$/)) {
                const content = fs.readFileSync(fullPath, 'utf8');
                let match;
                while ((match = phpRegex.exec(content)) !== null) {
                     if(!match[2].includes('${'))
                        allKeys.add(match[2]);
                }
            }
        }
    }
}

walk('./resources');
walk('./app');
walk('./routes');

const en = JSON.parse(fs.readFileSync('resources/lang/en.json', 'utf8'));
const ru = JSON.parse(fs.readFileSync('resources/lang/ru.json', 'utf8'));
const uz = JSON.parse(fs.readFileSync('resources/lang/uz.json', 'utf8'));

let missingInEn = [];
let missingInRu = [];
let missingInUz = [];

// Also add keys that exist in any of the json files but might be missing in others
Object.keys(en).forEach(k => allKeys.add(k));
Object.keys(ru).forEach(k => allKeys.add(k));
Object.keys(uz).forEach(k => allKeys.add(k));

allKeys.forEach(key => {
    if (key.trim() === '') return;
    if (!en[key]) missingInEn.push(key);
    if (!ru[key]) missingInRu.push(key);
    if (!uz[key]) missingInUz.push(key);
});

console.log('Total keys discovered:', allKeys.size);
console.log('Missing in EN:', missingInEn.length);
console.log('Missing in RU:', missingInRu.length);
console.log('Missing in UZ:', missingInUz.length);

fs.writeFileSync('missing_translations.json', JSON.stringify({
    en: missingInEn,
    ru: missingInRu,
    uz: missingInUz
}, null, 2));

