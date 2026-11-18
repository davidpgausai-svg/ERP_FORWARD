# ERP Forward agent runner (optional)

> **Optional.** ERP Forward now runs job agents itself, in its API server
> (`artifacts/api-server/src/workers/agentRuns.ts`), with pinned copies of the
> skills. Use this runner only to run agents outside ERP Forward, for example
> against a test instance. It needs `AGENT_RUNNER_SECRET` set on ERP Forward;
> without it ERP Forward's runner routes stay closed.

An external runner for the agents of ERP Forward **jobs**. It reads the skills
here directly, so it can try a skill change before ERP Forward pins it.

```
person presses Run in ERP Forward ──► run is queued
runner claims it ──► gets a key that works only while the run is going
runner ──► Claude (instructions = the agent's skills + the job + the focus)
Claude asks for a tool ──► runner calls ERP Forward's MCP endpoint with the key
ERP Forward ──► allows only the agent's tools, checks the job's scope,
                records every call as a run step, acts as the person who pressed Run
runner reports spend after each turn ──► ERP Forward says continue or stop
Claude finishes ──► ERP Forward runs its finishing checks and closes the run
```

Everything that must be trusted (who the agent acts as, which tools it gets, what
it may change, the spend cap, the step record and the finishing checks) is
enforced by ERP Forward, not here.

## What each agent follows

| Agent | Skills (from `plugins/erp-program/skills/`) |
|---|---|
| Design | `process-and-decision-modeling`, `decision-drafting`, `raid-capture` |
| Config | `erp-module-build-guide`, `guided-configuration` (agent not enabled yet) |
| Test | not written yet (agent not enabled yet) |

Plus `plugins/erp-program/references/output-conventions.md` and ERP Forward's own
server instructions. Change an agent's method by changing its skills here,
through a pull request, as for any skill.

## Running it

Node 20 or later.

```bash
cd runner
npm install
```

```bash
ERP_FORWARD_URL=https://your-erp-forward-host \
AGENT_RUNNER_SECRET=<same value as on ERP Forward> \
ANTHROPIC_API_KEY=<Claude API key> \
npm start
```

| Variable | Meaning |
|---|---|
| `ERP_FORWARD_URL` | ERP Forward's base URL |
| `AGENT_RUNNER_SECRET` | Shared secret, at least 32 characters, set to the same value on ERP Forward |
| `ANTHROPIC_API_KEY` | Claude API key |
| `POLL_SECONDS` | How often to look for queued runs (default 15) |

It runs one agent at a time and stops cleanly on `SIGTERM`. Model:
`claude-opus-5-5`, adaptive thinking at high effort, with prompt caching and the
server-side refusal fallback.

## Tests

```bash
npm test
```

The tests script Claude and fake ERP Forward's runner API, so they never call
either service.
