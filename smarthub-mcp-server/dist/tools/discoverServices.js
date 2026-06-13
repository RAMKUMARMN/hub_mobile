import * as fs from 'fs';
import * as path from 'path';
export function discoverServices() {
    const servicesDir = path.join(process.cwd(), 'lib', 'services');
    if (!fs.existsSync(servicesDir)) {
        return {
            success: false,
            message: 'services folder not found'
        };
    }
    const services = fs.readdirSync(servicesDir);
    return {
        success: true,
        services
    };
}
