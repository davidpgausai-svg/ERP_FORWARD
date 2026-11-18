// One Claude turn, and the cost estimate for a run.
import Anthropic from "@anthropic-ai/sdk";

export const MODEL = "claude-opus-5-5";
/** Claude Opus 5.5 list prices, USD per million tokens. ERP Forward caps spend on this estimate. */
const PRICE = { input: 4, output: 20, cacheWrite: 5, cacheRead: 0.2 };

/** A function that takes {system, tools, messages} and returns Claude's next message. */
export function anthropicTurn(client = new Anthropic()) {
  return async ({ system, tools, messages }) =>
    client.beta.messages
      .stream({
        model: MODEL,
        max_tokens: 64000,
        thinking: { type: "adaptive" },
        output_config: { effort: "high" },
        // The instructions and tool list are the same on every turn of a run,
        // so they are written to the cache once and read cheaply afterwards.
        cache_control: { type: "ephemeral" },
        // If a turn is declined by a safety classifier, the API retries it on
        // a fallback model instead of stopping the run.
        betas: ["server-side-fallback-2026-07-01"],
        fallbacks: "default",
        system,
        tools,
        messages,
      })
      .finalMessage();
}

export function emptyTotals() {
  return { inputTokens: 0, outputTokens: 0, cacheReadTokens: 0, cacheWriteTokens: 0, costUsd: 0 };
}

export function addUsage(totals, usage) {
  if (!usage) return totals;
  totals.inputTokens += usage.input_tokens ?? 0;
  totals.outputTokens += usage.output_tokens ?? 0;
  totals.cacheReadTokens += usage.cache_read_input_tokens ?? 0;
  totals.cacheWriteTokens += usage.cache_creation_input_tokens ?? 0;
  totals.costUsd =
    (totals.inputTokens * PRICE.input +
      totals.outputTokens * PRICE.output +
      totals.cacheWriteTokens * PRICE.cacheWrite +
      totals.cacheReadTokens * PRICE.cacheRead) /
    1_000_000;
  return totals;
}
