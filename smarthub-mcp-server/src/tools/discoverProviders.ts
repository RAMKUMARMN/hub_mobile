import * as fs from 'fs';
import * as path from 'path';

export function discoverProviders() {

    const providersDir =
        path.join(
            process.cwd(),
            'lib',
            'providers'
        );

    if (!fs.existsSync(providersDir)) {

        return {
            success: false,
            message:
                'providers folder not found'
        };
    }

    const providers =
        fs.readdirSync(
            providersDir
        );

    return {
        success: true,
        providers
    };
}