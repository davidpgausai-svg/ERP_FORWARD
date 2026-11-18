import assert from "node:assert/strict";
import { test } from "node:test";
import { erpForwardClient } from "../src/erpForward.mjs";
import { AGENT_SKILLS, buildInstructions, kickoff } from "../src/instructions.mjs";
import { runAgentLoop } from "../src/loop.mjs";

const run = {
  id: "run-1",
  agentType: "DESIGN",
  agentTitle: "Design agent",
  duty: "Draft the future-state processes.",
  maxCostUsd: 10,
  maxToolCalls: 200,
  focus: "Only remote hires",
  startedBy: { name: "Dana Whitfield" },
  job: {
    id: "job-1",
    title: "Preboarding",
    version: 6,
    workstreamId: "ws-1",
    workstreamName: "Core HR",
    essentialFunctions: "Design the pre-hire to Day 1 process.",
    mayBuild: ["Locations"],
    processes: [{ id: "p1", recordKey: "REC-0000000000000001", title: "Pre-hire", status: "DRAFT" }],
  },
};

test("instructions come from the plugin's own skills, the server's rules and the job", async () => {
  const system = await buildInstructions(run, "SERVER RULES: drafts only.");
  assert.match(system, /You are the design agent for the "Preboarding" job/);
  assert.match(system, /No person is in this conversation/);
  assert.match(system, /SERVER RULES: drafts only\./);
  for (const skill of AGENT_SKILLS.DESIGN) assert.match(system, new RegExp(`## Skill: ${skill}`));
  assert.match(system, /# Process and Decision Modeling/, "the skill text itself is included");
  assert.doesNotMatch(system, /^name: process-and-decision-modeling/m, "frontmatter is stripped");
  assert.match(system, /REC-0000000000000001 "Pre-hire" \(draft\)/);
  assert.match(system, /workstream ws-1 \(Core HR\)/);
  assert.match(kickoff(run), /Focus for this run, from Dana Whitfield: Only remote hires/);
});

const toolUse = (id, name, input) => ({ type: "tool_use", id, name, input });
const usage = { input_tokens: 1000, output_tokens: 100, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 };

test("the loop runs each tool through ERP Forward and returns Claude's summary", async () => {
  const replies = [
    { stop_reason: "tool_use", usage, content: [{ type: "thinking", thinking: "" }, toolUse("t1", "record_search", { query: "pre-hire" })] },
    { stop_reason: "end_turn", usage, content: [{ type: "text", text: "Drafted REC-1 Pre-hire. Filed 2 questions." }] },
  ];
  const calls = [];
  const seen = [];
  const outcome = await runAgentLoop({
    turn: async ({ messages }) => {
      seen.push(messages.length);
      return replies.shift();
    },
    erp: { tools: [{ name: "record_search" }], callTool: async (name, args) => (calls.push([name, args]), { text: "{\"items\":[]}", isError: false }) },
    system: "system",
    kickoff: "start",
    onProgress: async () => ({ continue: true, reason: null }),
  });
  assert.deepEqual(calls, [["record_search", { query: "pre-hire" }]]);
  assert.deepEqual(seen, [1, 3], "assistant turn (with its thinking block) and tool results go back");
  assert.equal(outcome.summary, "Drafted REC-1 Pre-hire. Filed 2 questions.");
  assert.equal(outcome.failed, false);
  assert.equal(outcome.totals.inputTokens, 2000);
  assert.ok(Math.abs(outcome.totals.costUsd - (2000 * 4 + 200 * 20) / 1e6) < 1e-9);
});

test("the loop stops when ERP Forward says so, and a refusal fails the run", async () => {
  const stopped = await runAgentLoop({
    turn: async () => ({ stop_reason: "tool_use", usage, content: [toolUse("t1", "record_search", {})] }),
    erp: { tools: [], callTool: async () => assert.fail("no tool runs after a stop") },
    system: "s",
    kickoff: "k",
    onProgress: async () => ({ continue: false, reason: "The spend cap for this run was reached." }),
  });
  assert.equal(stopped.stopped, true);
  assert.equal(stopped.summary, "The spend cap for this run was reached.");

  const refused = await runAgentLoop({
    turn: async () => ({ stop_reason: "refusal", usage, content: [] }),
    erp: { tools: [], callTool: async () => assert.fail() },
    system: "s",
    kickoff: "k",
    onProgress: async () => ({ continue: true, reason: null }),
  });
  assert.equal(refused.failed, true);
});

test("a tool error goes back to Claude instead of ending the run", async () => {
  const replies = [
    { stop_reason: "tool_use", usage, content: [toolUse("t1", "record_update", {})] },
    { stop_reason: "end_turn", usage, content: [{ type: "text", text: "Done." }] },
  ];
  let sent;
  await runAgentLoop({
    turn: async ({ messages }) => {
      sent = messages.at(-1);
      return replies.shift();
    },
    erp: { tools: [], callTool: async () => { throw new Error("socket closed"); } },
    system: "s",
    kickoff: "k",
    onProgress: async () => ({ continue: true, reason: null }),
  });
  assert.equal(sent.content[0].is_error, true);
  assert.match(sent.content[0].content, /socket closed/);
});

test("the ERP Forward client sends the runner secret and reads the claimed run", async () => {
  const requests = [];
  const client = erpForwardClient({
    baseUrl: "https://erp.example.test",
    secret: "x".repeat(40),
    fetchImpl: async (url, init) => {
      requests.push([String(url), init.headers.Authorization]);
      return new Response(JSON.stringify({ run: { id: "r1" }, mcpPath: "/api/mcp" }), { status: 200 });
    },
  });
  assert.deepEqual(await client.claim(), { id: "r1", mcpPath: "/api/mcp" });
  assert.deepEqual(requests, [["https://erp.example.test/api/agent-runner/claim", `Bearer ${"x".repeat(40)}`]]);

  const failing = erpForwardClient({
    baseUrl: "https://erp.example.test",
    secret: "x",
    fetchImpl: async () => new Response(JSON.stringify({ error: "Agent runner credentials are missing or wrong." }), { status: 401 }),
  });
  await assert.rejects(failing.claim(), /answered 401: Agent runner credentials are missing or wrong/);
});
