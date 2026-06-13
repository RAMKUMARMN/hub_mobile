import { alerts } from "../data/alerts.js";
export async function listAlertsHandler() {
    return {
        content: [
            {
                type: "text",
                text: JSON.stringify(alerts, null, 2),
            },
        ],
    };
}
