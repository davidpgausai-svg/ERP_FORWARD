# Learning Paths — ERP FORWARD Skills

**How to use this file.** It holds the *teaching* — who should learn what, in what order, and how to phrase a request well. It does NOT hold the authoritative catalog: the live available-skills list in the session does. Skills are grouped into families below, so a newly added skill usually slots into an existing family and this file stays useful without edits. Last reviewed: 2026-09.

## Families (stable groupings)

**Program operations** — running the program itself: status reporting and steering packets, capturing risks/issues/assumptions/dependencies, drafting decisions with options and approval routing, navigating governance and escalation.

**Discovery and analysis** — understanding the legacy estate from PeopleSoft extracts: reading metadata and inventories, diffing dated snapshots for configuration drift, analyzing customizations, security and access, integrations, and the reporting estate.

**Process and design** — drafting current-state process maps from system evidence plus SME correction, and the design work that follows from them.

**People and adoption** — change impacts, stakeholder analysis, communications, readiness, the Change Network, and training.

**Orientation** — this skill; the way in.

As of the last review, the program plugin carried skills across all five families, including: start-here, status-reporting, raid-capture, decision-drafting, governance-navigator, peoplesoft-metadata-reader, snapshot-diff, customization-analysis, security-access-analysis, integration-discovery, report-rationalization, process-map-drafting, process-and-decision-modeling, source-to-import-workbooks, erp-module-build-guide, and change-management. Treat this as illustrative history, not a checklist — always enumerate live.

**Discovery without a DBA.** The metadata-reader skill has three entry modes — extract CSVs, PS Query downloads, and screenshots of PeopleSoft pages — and a runbook for producing the extracts. A functional analyst with only page access can start on day one; the skill says what a screenshot can and cannot prove, and what to capture next.

## Role-based starting points

**Everyone, first week.** Learn two things: how to ask (describe the task, don't type commands), and where the chain of command sits when you're stuck. Those two unblock everything else.

**Workstream and pillar leads.** Status reporting (your weekly rhythm and steering packets), decision drafting (so your escalations move in one meeting instead of three), RAID capture (so risks land with owners rather than in meeting notes). Then governance navigation for the moments a question crosses into another workstream.

**Functional analysts (HR, Finance, Student, Supply Chain).** Process mapping first — it's where your subject expertise converts fastest into program artifacts. Then the discovery skills that touch your area: what's configured today, who has access to it, what reports depend on it. Then decision drafting for the gaps you surface.

**Data and conversion analysts.** Metadata reading first (the foundation the others assume), then snapshot diffing, then whichever analysis matches your assignment — customizations, security, integrations, or reports. RAID capture throughout: conversion work generates risks constantly and they must land as records.

**Technical team.** Integration discovery and security/access analysis, plus metadata reading for the estate view. Snapshot diffing becomes important once design is signed off and drift starts to matter.

**Change management and training.** The change-management skill is the hub; process mapping supplies the current-to-future comparison that generates change impacts, so those two chain naturally.

**PMO.** Status reporting, decision drafting, governance navigation, and RAID — the program's operating rhythm. Add readiness and reporting outputs as the record layer comes online.

## How to ask well

Weak prompts get generic answers because they omit the three things that steer the work: what you have, what you're doing, and what you need back.

- Weak: "Can you help with security?"
  Strong: "I've got the security extract (`HCM_P3I_ACCESS_MATRIX.csv`) from the August HCM snapshot. I need to know which departments actually process hires, to inform supervisory-org design."
- Weak: "Can you look at PeopleSoft for me?"
  Strong: "I don't have database access, but I can open Set Up HCM. Here are screenshots of our Department table and Action Reasons with the breadcrumbs showing — tell me what you can confirm from these, and what I should capture or ask the DBA for next."
- Weak: "Write a status report."
  Strong: "Draft this week's Finance workstream status — we closed the chart-of-accounts mapping review, the vendor extract is still late, and I need the tenant-refresh decision on the steering agenda."
- Weak: "What do I do about this risk?"
  Strong: "Our conversion test slipped two weeks because the extract was late. Log it as a risk with the data lead as owner, and tell me whether it needs escalating."

Three habits worth teaching explicitly: name the file or snapshot you're working from; say who the output is for; say what decision it needs to support.

## Chains that come up constantly

- **Extract lands → analysis → risk → decision.** Read the new snapshot, produce the inventory or findings, capture what's material as a risk, draft the decision it forces.
- **Process map → gaps → decisions → change impacts.** Draft current state, surface where the target differs, route the design decisions, feed the impacts into change and training.
- **Stuck → escalate → decide.** Get the chain of command, frame the blocker as a decision with options, route it to the accountable tier.
- **Week's end → status → steering.** Roll workstream activity into status, promote the unresolved items into decisions the committee can act on.

## For maintainers: adding a skill to the library

The teaching side of the loop is deliberately light, because the orientation skill discovers new skills automatically from the live list. When you add a skill:

1. Write a strong `description` — it is what makes the skill discoverable and therefore teachable. Include the plain-language phrases people actually use, not just formal terms.
2. Add a line to the relevant family above only if the skill introduces a genuinely new capability shape. Most additions need no edit here.
3. If it belongs in a role's starting sequence, add it there — that's the judgment a machine can't infer.
4. Update the "last reviewed" date when you touch this file.

Nothing else is required. If this file is out of date, orientation still works from the live catalog; the cost of staleness is lost nuance, not lost skills.
