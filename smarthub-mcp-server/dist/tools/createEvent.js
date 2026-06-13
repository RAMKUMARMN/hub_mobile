export async function createEventHandler({ name, date, }) {
    return {
        content: [
            {
                type: "text",
                text: JSON.stringify({
                    success: true,
                    eventId: "EVT-123",
                    name,
                    date,
                }, null, 2),
            },
        ],
    };
}
