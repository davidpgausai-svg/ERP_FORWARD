// ERP Forward's runner API: claim a queued run, report progress, finish.
// Authenticated with the shared secret AGENT_RUNNER_SECRET. Records are only
// ever touched through ERP Forward's MCP endpoint with the run's own key.

export function erpForwardClient({ baseUrl, secret, fetchImpl = fetch }) {
  async function post(path, body) {
    const response = await fetchImpl(new URL(path, baseUrl), {
      method: "POST",
      headers: { Authorization: `Bearer ${secret}`, "Content-Type": "application/json" },
      body: JSON.stringify(body ?? {}),
    });
    const text = await response.text();
    let json = null;
    try {
      json = text ? JSON.parse(text) : null;
    } catch {
      json = null;
    }
    if (!response.ok) {
      const reason = json?.error ?? text.slice(0, 200) ?? response.statusText;
      throw new Error(`ERP Forward ${path} answered ${response.status}: ${reason}`);
    }
    return json;
  }

  return {
    /** The next queued run with its key, or null when nothing is queued. */
    async claim() {
      const answer = await post("/api/agent-runner/claim");
      return answer?.run ? { ...answer.run, mcpPath: answer.mcpPath ?? "/api/mcp" } : null;
    },
    /** Reports running totals. The answer says whether to keep going. */
    progress(runId, totals) {
      return post(`/api/agent-runner/runs/${runId}/progress`, totals);
    },
    /** Claude is done (or the run failed). ERP Forward runs its finishing checks. */
    finish(runId, { summary, failed = false }) {
      return post(`/api/agent-runner/runs/${runId}/finish`, { summary, failed });
    },
  };
}
