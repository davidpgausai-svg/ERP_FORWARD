---
name: customization-analysis
description: Analyze PeopleSoft customizations and custom code from Pack 5 and Pack 2 extracts — modified vs vanilla objects, custom bolt-ons, PeopleCode inventory — and draft disposition recommendations for the new ERP. Use this whenever the user mentions customizations, mods, bolt-ons, custom code, "what did we change", technical debt, "will this work in Workday/Oracle", or asks what hidden requirements the legacy system contains.
---

# Customization Analysis

Every customization is a fossilized business requirement — someone once needed something the vanilla system didn't do. In a cloud ERP you cannot port the customization; you must recover the requirement and decide its future. This skill mines Pack 5 (what changed), Pack 2 (the logic), and Pack 4 (whether it's still alive) into disposition drafts a functional owner can approve.

Read `../../references/extract-library-guide.md` first. Follow the peoplesoft-metadata-reader habits (rank by usage, translate names, cite snapshot).

## Method

1. **Build the customization universe** from Pack 5: LASTUPDOPRID sweep (with the patch-noise caveat — admin-applied bundles stamp non-PPLSOFT ids), site-prefix objects (confirm the institution's prefix convention with the user), and PSPROJECTITEM migration history (which shows what was deliberately moved, and when).
2. **Cluster into functional units, not object counts.** A bolt-on is one thing to decide about even if it is 40 records, 12 pages, and 9 AE programs. Cluster by name prefix, project membership, and cross-references (pages exposing records, queries reading them). Name each cluster in business language, using descriptions and navigation breadcrumbs.
3. **Rate liveness** from Pack 4: telemetry-active, no-observed-use (with history-window caveat), or structurally dead (nothing references it).
4. **Recover the requirement.** For each live cluster, write the requirement it embodies as one or two plain sentences — from descriptions, SQL text (P2), and field names. Where the intent isn't recoverable from extracts, say so; that cluster goes on the SME interview list rather than getting an invented rationale.
5. **Draft a disposition** per cluster: RETIRE (dead or superseded), TARGET_STANDARD (vanilla target covers it), TARGET_CONFIGURED, PROCESS_CHANGE (stop doing it that way), TARGET_GAP (real gap — becomes a requirement), or REPORTING_ONLY. Include confidence and the reason. These are proposals; a human disposition decision is required for every cluster, and payroll/union-touching clusters warrant a policy check before any RETIRE proposal.

## Deliverable

# Customization inventory — [instance], snapshot [date]
## Headline numbers (clusters by disposition, by module, live vs dead)
## Cluster table (name, business purpose, size, liveness, proposed disposition, confidence)
## Requirements recovered (the TARGET_GAP list — this feeds fit-gap)
## SME interview list (clusters whose intent extracts can't reveal)
## Appendix CSVs

## Landing the output

Per `../../references/output-conventions.md`: DRAFT legacy_object updates and requirement records via MCP when connected; dispositions route to functional owners for approval — never mark them decided.
