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

For each item capture: title (specific — "Vendor extract delayed 3 weeks", never "data concerns"); description with the observable facts and the source (meeting, document, date); `category` (RISK, ASSUMPTION, ISSUE or DEPENDENCY); `severity` (LOW, MEDIUM, HIGH or CRITICAL); `likelihood` for risks (LOW, MEDIUM or HIGH, with a reason); `impactDescription` (what breaks, in program terms: dates, payroll, go-live scope); `mitigation` or next action; proposed owner (role if no name available). Cite the source — an unattributed risk gets deleted in the next log scrub. Confirm the fields with `schema_get` for `raid_item`.

Check for duplicates first: search existing RAID items (`record_search` with type `raid_item`, or the current RAID log file) before creating. If a similar item exists, propose updating it instead — duplicate risks fragment ownership.

## Landing the output

Per `../../references/output-conventions.md`: write raid_item records as DRAFT via MCP when connected (`schema_get` first), otherwise append to the RAID log file/CSV in the standard finding format. Present the drafts to the user compactly for confirmation, then remind them that they submit each one for review in Keystone. CRITICAL items (payroll, go-live date, legal/union exposure): tell the user explicitly this looks escalation-worthy and to whom it should go (`governance_structure_get`).

---

## Self-Improvement

At the end of every run, before ending:
1. Did any step fail or need a workaround?
2. Did the user correct or reject anything meaningful?
3. Did you discover something a future run might need?

Only propose a change if it meaningfully improves the skill. Surface it as a
proposed edit for human approval - never edit the installed copy. Approved
changes go back to this repo via PR.
