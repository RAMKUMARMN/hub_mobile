/// <reference types="node" />
import * as fs from 'fs';
import * as path from 'path';

export function discoverApiServices() {

    const servicesDir =
        path.join(
            process.cwd(),
            'lib',
            'services'
        );

    if (!fs.existsSync(servicesDir)) {

        return {
            success: false,
            message:
                'services folder not found'
        };
    }

    const files =
        fs.readdirSync(
            servicesDir
        );

    const apiServices =
        files.filter(
            file =>
                file.endsWith('.dart')
        );

    return {

        success: true,

        apiServices:
            apiServices.map(
                file => ({
                    file,
                    type:
                        'API Service'
                })
            )
    };
}