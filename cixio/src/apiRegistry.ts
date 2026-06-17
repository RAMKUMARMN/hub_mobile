import * as fs from 'fs';
import * as path from 'path';

export function getApis(
    extensionPath: string
) {

    const filePath = path.join(
        extensionPath,
        'registries',
        'apiRegistry.json'
    );

    if (!fs.existsSync(filePath)) {
        return [];
    }

    const data = fs.readFileSync(
        filePath,
        'utf8'
    );

    return JSON.parse(data);
}