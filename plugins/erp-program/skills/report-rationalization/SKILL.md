---
name: report-rationalization
description: Rationalize the PeopleSoft reporting estate from Pack 2 and Pack 4 extracts — queries, SQRs, nVision, BI Publisher, scheduled reports — into keep/replace/retire dispositions for the new ERP. Use this whenever the user mentions reports, queries, nVision, "how many reports do we have", report cleanup, reporting strategy, or worries about "where did my report go" tickets after go-live.
---

# Report Rationalization

PeopleSoft shops accumulate thousands of queries and reports over decades; institutions that skip rationalization drown in "where did my report go" tickets during hypercare. The good news: this is the most telemetry-friendly analysis in the program — usage data does most of the work, and the long tail mostly retires itself.

Read `../../references/extract-library-guide.md` first; follow metadata-reader habits.

## Method

1. **Inventory the estate** from P2: queries (PSQRYDEFN — note public vs private and owner), scheduled reports/SQRs/BI Publisher (PSPRCSDEFN), nVision layouts where extracted. Attribute to module via the records each query reads (PSQRYRECORD → PSRECDEFN.OBJECTOWNERID).
2. **Rank by reality** from P4: runs, distinct users, last run. Expect a power law — typically a small fraction of reports carry nearly all usage. State the actual distribution; it's the headline that makes executives fund this work correctly.
3. **Detect duplication**: queries reading the same records with similar fields are consolidation candidates; dozens of private variants of one public query are a training story, not twelve rebuild projects.
4. **Flag the sensitive tail**: queries reading payroll/HR/student records (join to record classifications) get review-before-disposition regardless of usage — a rarely-run query can still be a compliance report.
5. **Draft dispositions**: RETIRE (no observed use, with the history-window caveat — annual/fiscal-close reports run once a year); REPLACE_TARGET_STANDARD (vanilla target report covers it); REBUILD_TARGET_CUSTOM (real need, no standard equivalent — becomes a build item with an owner); CONSOLIDATE_INTO (name the survivor); KEEP_LEGACY_ARCHIVE (historical reference only). Every active report (used in the last 12 months) must end with a disposition and a named owner suggestion — an unresolved active report is a readiness blocker by program rule.

## Deliverable

# Report rationalization — [instance], snapshot [date]
## Headline (estate size, usage distribution, dispositions summary)
## The vital few (top reports by usage, each with disposition and owner suggestion)
## Consolidation clusters
## Sensitive-report review list
## The long tail (counts by disposition; detail in appendix CSV)
## Unknowns (telemetry gaps, unattributable reports)

## Landing the output

Per `../../references/output-conventions.md`: DRAFT legacy_report records with dispositions via MCP when connected; dispositions are proposals until functional owners approve them.

---

## Self-Improvement

At the end of every run, before ending:
1. Did any step fail or need a workaround?
2. Did the user correct or reject anything meaningful?
3. Did you discover something a future run might need?

Only propose a change if it meaningfully improves the skill. Surface it as a
proposed edit for human approval - never edit the installed copy. Approved
changes go back to this repo via PR.
