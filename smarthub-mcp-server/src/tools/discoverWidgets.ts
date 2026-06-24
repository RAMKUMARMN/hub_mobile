import * as fs from 'fs';
import * as path from 'path';

export function discoverWidgets() {
	const HUB_MOBILE_ROOT = path.resolve(
    process.cwd(),
    ".."
);

const widgetsDir = path.join(
    HUB_MOBILE_ROOT,
    "lib",
    "widgets"
);

    if (!fs.existsSync(widgetsDir)) {

        return {
            success: false,
            message:
                'widgets folder not found'
        };
    }

    const widgets =
        fs.readdirSync(
            widgetsDir
        );

    return {
        success: true,
        widgets
    };
}