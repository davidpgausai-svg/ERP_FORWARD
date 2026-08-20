---
name: status-reporting
description: Produce ERP program status reports — workstream status, program rollups, and steering-committee packets. Use this whenever the user asks for a status report, weekly update, steering packet, "where are we", executive summary of program progress, or wants to summarize what happened this week/month on the ERP program, even if they don't say the word "status".
---

# Status Reporting

A status report exists to force three honest sentences per workstream: what moved, what's stuck, and what decision is needed. Everything else is decoration. Leaders skim; the report must survive skimming.

## Gather before writing

1. If the ERP Record Layer MCP connector is available, pull: open RAID items by workstream, milestones vs baseline, pending approvals, current readiness score and blockers, decisions awaiting sign-off. This is the factual spine — do not ask the user for facts the record layer already holds.
2. Ask the user only for what records can't tell you: anything notable that happened outside the system, and the reporting period if unclear.
3. If the record layer is not connected, ask for the prior report and this period's notes, and work from those.

## Report structure

Use this exact template:

# [Program/Workstream] Status — [period]
## Overall: [GREEN / AMBER / RED] — one sentence why
## Progress this period
(3–6 bullets, each a completed or advanced thing, with evidence)
## Coming next period
(2–4 bullets)
## Risks and issues requiring attention
(top items only, each with owner and ask)
## Decisions needed
(each: the question, options, recommended option, who must decide, by when)

Rules that matter: a non-green status without a written reason is banned — the rationale is the entire value of the color. "Decisions needed" is the most-read section; if it's empty two periods running, say so and question whether escalation is working. Never pad progress — three real bullets beat six soft ones, and executives can smell filler.

## Steering packet variant

When the ask is a steering-committee packet, extend the report with: agenda, readiness snapshot (score, component breakdown, named blockers with owners), and one page per decision needed (background, options with pros/cons, recommendation, financial/payroll/union impact if any). Follow `../../references/output-conventions.md` for delivery; produce pptx or docx only when asked, using the corresponding format skill.

## Landing the output

Per `../../references/output-conventions.md`: save the report as a file and, when connected, write a status_report record (DRAFT) to the record layer with the same content, then tell the user it's ready for review.
