/// <reference types="node" />
import * as fs from 'fs';
import * as path from 'path';
import * as process from 'process';

export async function discoverModelsHandler() {

    const HUB_MOBILE_ROOT = path.resolve(
    process.cwd(),
    ".."
);

const modelsDir = path.join(
    HUB_MOBILE_ROOT,
    "lib",
    "models"
);

    if (!fs.existsSync(modelsDir)) {

        return {
            success: false,
            message:
                'models folder not found'
        };
    }

    const models =
        fs.readdirSync(
            modelsDir
        );

    return {
        success: true,
        models
    };
}