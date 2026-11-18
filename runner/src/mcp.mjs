// Connects to ERP Forward's MCP endpoint with the run's key. ERP Forward
// offers only the agent type's tools for that key, so the list is used as is.
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";

export async function connectErpForward({ baseUrl, mcpPath, key }) {
  const client = new Client({ name: "erp-forward-agent-runner", version: "0.1.0" });
  const transport = new StreamableHTTPClientTransport(new URL(mcpPath, baseUrl), {
    requestInit: { headers: { Authorization: `Bearer ${key}` } },
  });
  await client.connect(transport);

  const listed = [];
  let cursor;
  do {
    const page = await client.listTools(cursor ? { cursor } : {});
    listed.push(...page.tools);
    cursor = page.nextCursor;
  } while (cursor);

  // Sorted by name so the tool list is byte-stable across turns (prompt cache).
  const tools = listed
    .sort((a, b) => a.name.localeCompare(b.name))
    .map((tool) => ({ name: tool.name, description: tool.description ?? tool.name, input_schema: tool.inputSchema }));

  return {
    tools,
    instructions: client.getInstructions() ?? "",
    async callTool(name, args) {
      const response = await client.callTool({ name, arguments: args });
      const text = (Array.isArray(response.content) ? response.content : [])
        .map((part) => (part && typeof part === "object" && "text" in part ? String(part.text) : ""))
        .join("\n")
        .trim();
      return { text: text || "(no output)", isError: response.isError === true };
    },
    close: () => client.close(),
  };
}
