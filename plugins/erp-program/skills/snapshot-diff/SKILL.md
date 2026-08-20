---
name: snapshot-diff
description: Compare two dated PeopleSoft extract snapshots and report what changed — configuration drift, new/modified/deleted objects, security changes, usage shifts. Use this whenever the user asks "what changed", mentions drift, compares extract dates, asks whether config is stable before a design decision or mock conversion, or when a new snapshot lands and a delta report would be useful — offer it proactively when a fresh snapshot is mentioned.
---

# Snapshot Diff

The extract library's dated folders make change itself observable. That matters for two reasons: design decisions assume a stable current state (drift under a signed-off design is a silent defect), and mock conversions must name exactly which snapshot they converted. This skill turns "compare two folders of CSVs" into a governed drift report.

Read `../../references/extract-library-guide.md` for pack contents and joins.

## Method

1. Confirm the two snapshot dates and instance with the user (default: latest vs previous). Check both `manifest.csv` files — if kit versions differ, say so up front, because schema changes in the kit can masquerade as drift.
2. Diff by key, not by row order. Every metadata table has a natural key (RECNAME; PNLGRPNAME; ROLENAME+CLASSID; RECNAME+FIELDNAME...). Classify each key as ADDED, REMOVED, or MODIFIED (compare non-volatile columns; ignore pure timestamp churn). Use Python; write the diff logic once per table family and reuse.
3. Prioritize what humans see. A full diff of 40k objects is noise. Lead with: security changes (roles, permission lists, user assignments — always material), setup-table changes in modules under active design, customization-flagged objects that changed (LASTUPDOPRID/LASTUPDDTTM movement), and telemetry shifts (a process that stopped running is a finding). Everything else goes in appendix CSVs.
4. Interpret, don't just list. "PS_EARNINGS_TBL: 3 rows added" is data; "three new earnings codes appeared after the design workshop signed off the earnings mapping — mapping rules may be stale" is a finding. Connect drift to in-flight program work whenever you can see the connection; ask the user about program context when you can't.

## Report structure

# Drift report — [instance], [date A] → [date B]
## Headline (3 bullets max: the changes that matter and why)
## Security changes
## Configuration changes by module
## Customization activity
## Usage shifts
## Appendix: full diff CSVs (paths)
## Unknowns (kit-version caveats, tables not comparable, telemetry gaps)

## Landing the output

Per `../../references/output-conventions.md`. Material drift affecting signed-off designs or approved mappings deserves a RAID item — invoke the raid-capture skill's format and offer to log it. When the record layer is connected, attach the drift report as evidence to affected records.
