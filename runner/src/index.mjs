// ERP Forward agent runner. Claims queued job runs and runs them one at a time.
//
//   ERP_FORWARD_URL      e.g. https://erp-forward.example.org
//   AGENT_RUNNER_SECRET  the same value set on ERP Forward (at least 32 characters)
//   ANTHROPIC_API_KEY    the Claude API key
//   POLL_SECONDS         how often to look for queued runs (default 15)
import Anthropic from "@anthropic-ai/sdk";
import { anthropicTurn } from "./claude.mjs";
import { erpForwardClient } from "./erpForward.mjs";
import { buildInstructions, kickoff } from "./instructions.mjs";
import { runAgentLoop } from "./loop.mjs";
import { connectErpForward } from "./mcp.mjs";

function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    console.error(`Set ${name} before starting the runner.`);
    process.exit(1);
  }
  return value;
}

const baseUrl = requireEnv("ERP_FORWARD_URL");
const secret = requireEnv("AGENT_RUNNER_SECRET");
requireEnv("ANTHROPIC_API_KEY");
const pollMs = Number(process.env.POLL_SECONDS ?? 15) * 1000;

const erpForward = erpForwardClient({ baseUrl, secret });
const turn = anthropicTurn(new Anthropic());
let stopping = false;
process.on("SIGTERM", () => (stopping = true));
process.on("SIGINT", () => (stopping = true));

export async function runOnce(run) {
  const label = `${run.job.title} · ${run.agentTitle} · ${run.id}`;
  console.log(`Started ${label}`);
  let erp;
  try {
    erp = await connectErpForward({ baseUrl, mcpPath: run.mcpPath, key: run.key });
    const system = await buildInstructions(run, erp.instructions);
    const outcome = await runAgentLoop({
      turn,
      erp,
      system,
      kickoff: kickoff(run),
      onProgress: (totals) => erpForward.progress(run.id, totals),
    });
    if (!outcome.stopped) await erpForward.finish(run.id, { summary: outcome.summary, failed: outcome.failed });
    console.log(`Ended ${label}: ${outcome.stopped ? "stopped by ERP Forward" : outcome.failed ? "failed" : "finished"} ($${outcome.totals.costUsd.toFixed(2)})`);
  } catch (error) {
    const reason = error instanceof Error ? error.message : String(error);
    console.error(`Failed ${label}: ${reason}`);
    await erpForward.finish(run.id, { summary: `The runner hit an error: ${reason}`, failed: true }).catch(() => {});
  } finally {
    await erp?.close().catch(() => {});
  }
}

async function main() {
  console.log(`Agent runner polling ${baseUrl} every ${pollMs / 1000}s`);
  while (!stopping) {
    let run = null;
    try {
      run = await erpForward.claim();
    } catch (error) {
      console.error(error instanceof Error ? error.message : String(error));
    }
    if (run) await runOnce(run);
    else await new Promise((resolve) => setTimeout(resolve, pollMs));
  }
  console.log("Agent runner stopped.");
}

await main();
