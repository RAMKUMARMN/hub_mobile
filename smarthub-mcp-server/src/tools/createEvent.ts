export async function createEventHandler({
  name,
  date,
}: {
  name: string;
  date: string;
}) {
  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(
          {
            success: true,
            eventId: "EVT-123",
            name,
            date,
          },
          null,
          2
        ),
      },
    ],
  };
}