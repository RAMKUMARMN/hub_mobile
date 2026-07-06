import { devices } from "../data/devices.js";

export async function listDevicesHandler() {
  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(devices, null, 2),
      },
    ],
  };
}