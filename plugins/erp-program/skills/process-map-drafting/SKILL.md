---
name: process-map-drafting
description: Draft current-state business process maps by combining PeopleSoft extract evidence (approval routes, navigation, security, usage) with workflow documents and SME input. Use this whenever the user asks to map a process, mentions current-state or future-state workflows, swimlanes, "how does X work today", business process documentation, or prepares for design workshops — for any pillar: HR, payroll, finance, student, supply chain.
---

# Process Map Drafting

The economics this skill exploits: SMEs correcting a draft is roughly five times faster than SMEs authoring from a blank page. The extracts let Claude draft the system half of any process at scale; humans then add the half no database knows — the emails, the spreadsheets on Teams, the Wednesday-5pm gate, the *why*. The program has already proven this validate-with-experts motion; this skill industrializes it.

Read `../../references/extract-library-guide.md`. The existing current-state documents (TA workflow, physician onboarding, locums, student vetting) are the house style — match their structure: numbered steps, actor, system, handoffs table, pain points, systems inventory.

## Method

1. **Scope one process at a time** (e.g., "staff requisition to hire", "requisition to PO", "student service-indicator release"). Confirm scope and population with the user — processes differ by population (faculty vs staff vs student worker), and a map that ignores that gets rejected in validation.
2. **Assemble the system evidence**:
   - AWE approval routes (P2 EOAW*): stages, paths, steps, criteria, user lists — this IS the approval half of the process, already sequenced.
   - Navigation + components (P1): which screens the process touches, as breadcrumbs.
   - Security (P3d): which roles/departments can perform each step — your actor candidates per swimlane.
   - Telemetry (P4): volumes and cadence — how often this process actually runs.
   - Setup (P3): condition-bearing config (action reasons, service indicators, requisition types) that branches the flow.
3. **Draft the map** in the house structure: numbered steps with actor / system / action / trigger; a handoffs table (trigger mechanism, SLA if visible, known pain points); a systems inventory. Mark every step with its evidence source — and mark the gaps explicitly: `[HUMAN STEP — VALIDATE]` wherever the system evidence shows a discontinuity (a status changes with no system actor visible; a document appears from nowhere). Those markers are the SME interview agenda.
4. **Run validation as correction.** Produce a validation copy asking SMEs to fix, not compose: "we believe X happens between steps 7 and 8 — what actually happens?" Fold corrections in, record who validated and when.
5. **Link forward.** When a future-state map exists or emerges in design, record current-to-future step links (ELIMINATED / AUTOMATED / MOVED_TO_SELF_SERVICE / UNCHANGED / NEW) — these links auto-seed change-impact records, which is how change management gets its shopping list without a separate discovery effort.

## Landing the output

Per `../../references/output-conventions.md`: the map as a docx (use the docx format skill; black font, no horizontal dividers) matching the house documents; DRAFT process-map and handoff records via MCP when connected; validation status tracked on the record. Never present an unvalidated draft as a finished current-state map — label drafts loudly.

---

## Self-Improvement

At the end of every run, before ending:
1. Did any step fail or need a workaround?
2. Did the user correct or reject anything meaningful?
3. Did you discover something a future run might need?

Only propose a change if it meaningfully improves the skill. Surface it as a
proposed edit for human approval - never edit the installed copy. Approved
changes go back to this repo via PR.
