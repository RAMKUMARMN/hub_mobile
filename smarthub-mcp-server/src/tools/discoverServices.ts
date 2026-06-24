import * as fs from 'fs';
import * as path from 'path';

export function discoverServices() {

    const HUB_MOBILE_ROOT = path.resolve(
    process.cwd(),
    ".."
);

const servicesDir = path.join(
    HUB_MOBILE_ROOT,
    "lib",
    "services"
);

    if (!fs.existsSync(servicesDir)) {

        return {
            success: false,
            message:
                'services folder not found'
        };
    }

    const services =
        fs.readdirSync(
            servicesDir
        );

    return {
        success: true,
        services
    };
}