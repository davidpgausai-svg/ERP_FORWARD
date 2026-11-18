// The agent loop: Claude decides each step, ERP Forward carries it out.
//
// A manual loop rather than the SDK's tool runner, because after every turn the
// runner must report spend to ERP Forward and stop when told to. Scope, the
// tool allowlist, the step record and the finishing checks are enforced by
// ERP Forward itself, not here.
import { addUsage, emptyTotals } from "./claude.mjs";

function finalText(message) {
  return message.content
    .filter((block) => block.type === "text")
    .map((block) => block.text)
    .join("\n")
    .trim();
}

/**
 * @param {object} input
 * @param {(params: {system: string, tools: object[], messages: object[]}) => Promise<object>} input.turn
 * @param {{tools: object[], callTool: (name: string, args: object) => Promise<{text: string, isError: boolean}>}} input.erp
 * @param {string} input.system
 * @param {string} input.kickoff
 * @param {(totals: object) => Promise<{continue: boolean, reason: string | null}>} input.onProgress
 * @returns {Promise<{summary: string, failed: boolean, stopped: boolean, totals: object}>}
 */
export async function runAgentLoop({ turn, erp, system, kickoff, onProgress }) {
  const totals = emptyTotals();
  const messages = [{ role: "user", content: kickoff }];

  for (;;) {
    const message = await turn({ system, tools: erp.tools, messages });
    addUsage(totals, message.usage);
    const answer = await onProgress({ ...totals });
    if (!answer.continue) {
      return { summary: answer.reason ?? "Stopped by ERP Forward.", failed: false, stopped: true, totals };
    }

    if (message.stop_reason === "refusal") {
      return { summary: "Claude declined to continue this run. Nothing more was changed.", failed: true, stopped: false, totals };
    }
    // Content goes back unchanged, thinking blocks included.
    messages.push({ role: "assistant", content: message.content });
    if (message.stop_reason === "pause_turn") continue;

    const toolUses = message.content.filter((block) => block.type === "tool_use");
    if (!toolUses.length) return { summary: finalText(message) || "Finished.", failed: false, stopped: false, totals };
    if (message.stop_reason === "max_tokens") {
      return {
        summary: "A response was cut off before its tool call finished. Run again with a narrower focus.",
        failed: true,
        stopped: false,
        totals,
      };
    }

    // Tool calls in one turn run in order: ERP Forward checks each write
    // against the scope as it stands after the previous one.
    const results = [];
    for (const use of toolUses) {
      const args = use.input && typeof use.input === "object" ? use.input : {};
      let result;
      try {
        result = await erp.callTool(use.name, args);
      } catch (error) {
        result = { text: `The call could not be completed: ${error instanceof Error ? error.message : String(error)}`, isError: true };
      }
      results.push({ type: "tool_result", tool_use_id: use.id, is_error: result.isError, content: result.text });
    }
    messages.push({ role: "user", content: results });
  }
}
