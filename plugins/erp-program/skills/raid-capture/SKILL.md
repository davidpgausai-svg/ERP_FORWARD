---
name: raid-capture
description: Capture ERP program risks, assumptions, issues, and dependencies (RAID) as structured records. Use this whenever the user mentions a risk, problem, blocker, concern, dependency, "we should log this", or when meeting notes/emails/conversation reveal something that could threaten the ERP program — even if the user doesn't ask to log it, offer to capture it.
---

# RAID Capture

Programs don't fail from unknown risks; they fail from known risks nobody wrote down with an owner. The job of this skill is to catch RAID items at the moment they surface — in meeting notes, in a vent, in a side comment — and turn them into records someone owns.

## Recognize the moment

Listen for RAID signals in whatever the user shares: "the vendor is late", "we're assuming IT can...", "nobody owns...", "that depends on...". When you spot one and the user hasn't asked, offer in one line: "That sounds like a risk worth logging — want me to draft it?" Don't nag; offer once per item.

## Classify honestly

- **Risk** — might happen, would hurt (has probability). 
- **Issue** — is happening now (no probability, just impact).
- **Assumption** — treated as true without proof; log it so its failure is detectable.
- **Dependency** — our date relies on someone else's delivery.

Misclassification matters: a risk logged as an issue triggers firefighting; an issue logged as a risk gets ignored. When genuinely ambiguous, ask one short question.

## Draft the record

For each item capture: title (specific — "Vendor extract delayed 3 weeks", never "data concerns"); description with the observable facts; impact (what breaks, in program terms: dates, payroll, go-live scope); probability for risks (H/M/L with a reason); suggested owner role or team; proposed mitigation or next action; source (meeting, document, date). Cite the source — an unattributed risk gets deleted in the next log scrub.

## Confirm an owner

A role or team is a suggestion, not an assigned owner. Never infer a person from a role, team, source author, or similar record.

When connected to MCP, resolve a named person with `users_list({query: "<name, title, team, or workstream>"})`. It returns active people in the signed-in organization; use `workstream_list` first if you need a workstream ID, then pass that ID as `workstreamId` to narrow the search. If there are multiple plausible matches, ask the user which person they mean. Show the candidate's name and title/team, then ask whether to assign that person.

Only after an explicit yes, pass that candidate's `id` as `ownerId` to `record_create_draft`. Do not put a proposed owner in `payload` or another record field. If nobody is confirmed, omit `ownerId` so the capturing user remains Owner, and append this exact line at the end of the description: `Suggested owner: <role or team> (not confirmed).`

Check for duplicates first: call `record_search` with `search: "<RAID title or key terms>"`, or search the current RAID log file. If a similar item exists, propose updating it instead — duplicate risks fragment ownership.

## Landing the output

Per `../../references/output-conventions.md`: call `schema_get` with `recordType: "raid_item"` first, then create a `raid_item` DRAFT with `record_create_draft` when connected; otherwise append to the RAID log file/CSV in the standard finding format. Confirm the assigned Owner in the response. State that the record remains a draft and a human must submit it for review in ERP Forward; do not submit it through MCP. Severity-1 items (payroll, go-live date, legal/union exposure): tell the user explicitly this looks escalation-worthy and to whom it should go.

---

## Self-Improvement

At the end of every run, before ending:
1. Did any step fail or need a workaround?
2. Did the user correct or reject anything meaningful?
3. Did you discover something a future run might need?

Only propose a change if it meaningfully improves the skill. Surface it as a
proposed edit for human approval - never edit the installed copy. Approved
changes go back to this repo via PR.
