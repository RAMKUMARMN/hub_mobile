import * as fs from 'fs';
import * as path from 'path';

export function getTools(
    extensionPath: string
) {

    const filePath = path.join(
        extensionPath,
        'registries',
        'toolRegistry.json'
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