import { alerts } from "../data/alerts.js";

export async function listAlertsHandler() {
  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(alerts, null, 2),
      },
    ],
  };
}