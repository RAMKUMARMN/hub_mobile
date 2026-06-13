import * as fs from 'fs';
import * as path from 'path';
export function discoverScreens() {
    const screensDir = path.join(process.cwd(), 'lib', 'screens');
    if (!fs.existsSync(screensDir)) {
        return {
            success: false,
            message: 'screens folder not found'
        };
    }
    const screens = fs.readdirSync(screensDir);
    return {
        success: true,
        screens
    };
}
