import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

import { listAlertsHandler } from "./tools/listAlerts.js";
import { listDevicesHandler } from "./tools/listDevices.js";
import { createEventHandler } from "./tools/createEvent.js";
import { getSystemStatusHandler } from "./tools/getSystemStatus.js";

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
