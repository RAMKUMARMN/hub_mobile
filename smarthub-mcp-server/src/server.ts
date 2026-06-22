import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

import { listAlertsHandler } from "./tools/listAlerts.js";
import { listDevicesHandler } from "./tools/listDevices.js";
import { createEventHandler } from "./tools/createEvent.js";
import { getSystemStatusHandler } from "./tools/getSystemStatus.js";
import { discoverApiServices } from "./tools/discoverApiServices.js";
import { discoverModelsHandler } from "./tools/discoverModels.js";
import { discoverProviders } from "./tools/discoverProviders.js";
import { discoverScreens } from "./tools/discoverScreens.js";
import { discoverServices } from "./tools/discoverServices.js";
import { discoverWidgets } from "./tools/discoverWidgets.js";
const server = new McpServer({
	name: "smarthub-mcp",
	version: "1.0.0",
});

server.tool(
	"list_active_alerts",
	"Get all active SmartHub alerts",
	{},
	listAlertsHandler
);
server.tool(
  "discover_api_services",
  "Discover mobile API services",
  {},
  async () => {
    const result = await discoverApiServices();

    return {
      content: [
        {
          type: "text" as const,
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  }
);

server.tool(
  "discover_models",
  "Discover mobile models",
  {},
  async () => {
    const result = await discoverModelsHandler();

    return {
      content: [
        {
          type: "text" as const,
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  }
);

server.tool(
  "discover_providers",
  "Discover Flutter providers",
  {},
  async () => {
    const result = await discoverProviders();

    return {
      content: [
        {
          type: "text" as const,
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  }
);

server.tool(
  "discover_screens",
  "Discover Flutter screens",
  {},
  async () => {
    const result = await discoverScreens();

    return {
      content: [
        {
          type: "text" as const,
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  }
);

server.tool(
  "discover_services",
  "Discover mobile services",
  {},
  async () => {
    const result = await discoverServices();

    return {
      content: [
        {
          type: "text" as const,
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  }
);

server.tool(
  "discover_widgets",
  "Discover Flutter widgets",
  {},
  async () => {
    const result = await discoverWidgets();

    return {
      content: [
        {
          type: "text" as const,
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  }
);
server.tool(
	"list_devices",
	"Get all registered SmartHub devices",
	{},
	listDevicesHandler
);

server.tool(
	"create_event",
	"Create a new SmartHub event",
	{
		name: z.string(),
		date: z.string(),
	},
	createEventHandler
);

server.tool(
	"get_system_status",
	"Get SmartHub system overview",
	{},
	getSystemStatusHandler
);

async function main() {
	const transport = new StdioServerTransport();
	await server.connect(transport);
	console.error("SmartHub MCP Server Running...");
}

main().catch(console.error);
