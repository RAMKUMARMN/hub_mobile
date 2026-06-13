export async function getSystemStatusHandler() {
    return {
        content: [
            {
                type: "text",
                text: JSON.stringify({
                    activeAlerts: 2,
                    onlineDevices: 24,
                    offlineDevices: 3,
                    pendingEvents: 5,
                }, null, 2),
            },
        ],
    };
}
