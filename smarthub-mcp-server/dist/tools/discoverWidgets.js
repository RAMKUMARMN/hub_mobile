import * as fs from 'fs';
import * as path from 'path';
export function discoverWidgets() {
    const widgetsDir = path.join(process.cwd(), 'lib', 'widgets');
    if (!fs.existsSync(widgetsDir)) {
        return {
            success: false,
            message: 'widgets folder not found'
        };
    }
    const widgets = fs.readdirSync(widgetsDir);
    return {
        success: true,
        widgets
    };
}
