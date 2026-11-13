// Builds an agent's instructions from the skills in this plugin, the job's
// description and the run's focus. The skills here are the single source of
// the agents' method: people's Claude and the agents read the same text.
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const PLUGIN = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../plugins/erp-program");

/** The skills each agent type follows, in order. */
export const AGENT_SKILLS = {
  DESIGN: ["process-and-decision-modeling", "decision-drafting", "raid-capture"],
  CONFIG: ["erp-module-build-guide", "guided-configuration"],
  TEST: [],
};

const SHARED_REFERENCES = ["output-conventions.md"];

function stripFrontmatter(markdown) {
  return markdown.startsWith("---") ? markdown.replace(/^---\n[\s\S]*?\n---\n/, "") : markdown;
}

export async function loadSkill(name, root = PLUGIN) {
  const text = await readFile(path.join(root, "skills", name, "SKILL.md"), "utf8");
  return stripFrontmatter(text).trim();
}

async function loadReference(name, root = PLUGIN) {
  return (await readFile(path.join(root, "references", name), "utf8")).trim();
}

/**
 * The system prompt: stable for every turn of a run, so it is cached.
 * Order: who you are and the rules of running unattended, the server's own
 * rules, then the skills, then the job.
 */
export async function buildInstructions(run, serverInstructions = "", { root = PLUGIN } = {}) {
  const skills = await Promise.all((AGENT_SKILLS[run.agentType] ?? []).map((name) => loadSkill(name, root)));
  const references = await Promise.all(SHARED_REFERENCES.map((name) => loadReference(name, root)));
  const job = run.job;
  const processes = job.processes.map((p) => `- ${p.recordKey} "${p.title}" (${p.status.toLowerCase().replace(/_/g, " ")})`).join("\n");

  return [
    `You are the ${run.agentTitle.toLowerCase()} for the "${job.title}" job on the ERP Forward program. ${run.duty}`,
    "",
    "## Running unattended",
    "- No person is in this conversation. Where a skill says to ask the user, file a draft decision record for the question (the decision-drafting skill) and carry on with the rest of the work.",
    `- You act for ${run.startedBy.name}, with their permissions. Everything you create is a DRAFT a person reviews; you never submit or approve.`,
    `- Work only on this job's scope: the processes listed below, the records linked to them, and records you create. Put new records in workstream ${job.workstreamId}${job.workstreamName ? ` (${job.workstreamName})` : ""}. ERP Forward refuses anything else and tells you why.`,
    "- Before creating a configuration object, search for it: if one exists, link to it, and use record_change_propose for any change you need to an object someone else stewards.",
    "- For every business process you draft or change, call business_process_conflicts_get and policy_compliance_check on it before you finish.",
    `- You have at most ${run.maxToolCalls} tool calls and a $${run.maxCostUsd.toFixed(2)} spend cap. Work in order of value.`,
    "- Finish with a short plain summary: what you created or changed (record keys and titles) and the questions you filed for people.",
    "",
    serverInstructions ? `## ERP Forward's rules\n\n${serverInstructions.trim()}\n` : "",
    ...skills.map((text, i) => `## Skill: ${AGENT_SKILLS[run.agentType][i]}\n\n${text}\n`),
    ...references.map((text, i) => `## Reference: ${SHARED_REFERENCES[i]}\n\n${text}\n`),
    "## The job",
    "",
    `Title: ${job.title} (job description version ${job.version})`,
    `Workstream: ${job.workstreamName ?? job.workstreamId}`,
    "",
    "Essential functions:",
    job.essentialFunctions.trim() || "(none written)",
    "",
    "Business processes in scope:",
    processes || "(none)",
    job.mayBuild.length ? `\nObject types the Config agent may build: ${job.mayBuild.join(", ")}.` : "",
  ]
    .filter((line) => line !== undefined)
    .join("\n");
}

/** The first user message: the run's request, with the person's focus if they gave one. */
export function kickoff(run) {
  return [
    `Start the ${run.agentTitle.toLowerCase()} run for the "${run.job.title}" job.`,
    run.focus ? `Focus for this run, from ${run.startedBy.name}: ${run.focus}` : "Cover all the processes in scope.",
  ].join("\n\n");
}
