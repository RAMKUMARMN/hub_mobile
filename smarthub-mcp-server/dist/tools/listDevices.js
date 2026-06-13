import { devices } from "../data/devices.js";
export async function listDevicesHandler() {
    return {
        content: [
            {
                type: "text",
                text: JSON.stringify(devices, null, 2),
            },
        ],
    };
}
