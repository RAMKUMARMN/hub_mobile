import * as fs from 'fs';
import * as path from 'path';

export function discoverScreens() {

    const HUB_MOBILE_ROOT = path.resolve(
    process.cwd(),
    ".."
);

const screensDir = path.join(
    HUB_MOBILE_ROOT,
    "lib",
    "screens"
);

    if (!fs.existsSync(screensDir)) {

        return {
            success: false,
            message:
                'screens folder not found'
        };
    }

    const screens =
        fs.readdirSync(
            screensDir
        );

    return {
        success: true,
        screens
    };
}