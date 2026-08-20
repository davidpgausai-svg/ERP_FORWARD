---
name: peoplesoft-metadata-reader
description: Read and analyze PeopleSoft extract-kit CSVs (Packs 1–5) from the SharePoint extract library — data dictionary, pages/components, navigation, setup tables, security, usage telemetry. Use this whenever the user asks anything about the PeopleSoft environment, mentions PSRECDEFN or extract files, wants an inventory of tables/pages/queries/processes, asks "what's in PeopleSoft", "how big is our footprint", "what do we use", or shares extract CSVs — for ANY pillar: HR, payroll, finance, student, or supply chain.
---

# PeopleSoft Metadata Reader

This is the foundational conversion skill: it turns raw extract CSVs into ranked, human-readable inventories. Read `../../references/extract-library-guide.md` FIRST — it explains the packs, file naming, and the joins everything below depends on. Other conversion skills assume this skill's habits.

## Ground rules

- Work only from the extract library (Packs 1–5). If asked to analyze a file containing identified employee/student/payroll rows, decline per the library guide and flag it.
- Note instance + snapshot date on everything you produce. Verify loaded row counts against `manifest.csv` before concluding anything.
- Load CSVs with Python in the sandbox (pipe-delimited, header row). For big files, sample-inspect first, then process whole.

## The core method: inventory → rank → translate

1. **Inventory** the object type in question from Pack 1/2/3 (records, components, queries, processes, setup tables). Attribute each object to its owning module via `OBJECTOWNERID` — that's how one answer serves finance, HR, student, and supply chain separately.
2. **Rank by reality** using Pack 4 telemetry: runs per month, distinct users, last-used date. Objects without telemetry go in a "no observed use" bucket — with the honest caveat that telemetry history may be shorter than an annual cycle (year-end payroll and fiscal-close objects run rarely but matter enormously). Never label something "dead" from thin history; label it "no observed use in N months of telemetry."
3. **Translate for humans.** Internal names (DERIVED_HR_XYZ) mean nothing to SMEs. Join to descriptions (RECDESCR, DESCR) and build navigation breadcrumbs from PSPRSMDEFN so every component appears as "Workforce Administration > Job Information > Job Data". Deliverables lead with the human name; object names go in appendix columns.

## Questions this skill should answer without being walked through it

- "How many custom tables do we have in FSCM?" → Pack 1 + Pack 5 sweep, by module.
- "What are our most-used components/pages?" → Pack 1 + Pack 4 join, ranked, breadcrumbed.
- "Which setup tables are non-empty and what's in them?" → Pack 3 + row counts, by module.
- "Who uses X?" → access chain (P3d) + telemetry (P4).
- "What would we lose if we retired Y?" → dependencies via P2 (queries reading it, AE steps touching it, pages exposing it).

## Landing the output

Per `../../references/output-conventions.md`: inventories as CSV + a short executive summary; findings in the standard format; DRAFT records to the record layer via MCP when connected (legacy_objects and data-quality findings especially). Always end with the unknowns list — what the extracts could not tell you and which human or additional pack could.

---

## Self-Improvement

At the end of every run, before ending:
1. Did any step fail or need a workaround?
2. Did the user correct or reject anything meaningful?
3. Did you discover something a future run might need?

Only propose a change if it meaningfully improves the skill. Surface it as a
proposed edit for human approval - never edit the installed copy. Approved
changes go back to this repo via PR.
