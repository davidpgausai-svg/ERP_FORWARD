[README.md](https://github.com/user-attachments/files/31270721/README.md)
# erp-forward — Cowork Plugin

ERP FORWARD program skills. Install by adding this repo as a plugin marketplace in Claude (Cowork / Claude Code), then installing the `erp-program` plugin. Enterprise admins can deploy it workspace-wide.

## Skills

Program operations:
- `start-here` — orientation: what these skills do, which one to reach for, and how to ask
- `status-reporting` — workstream/program status and steering packets
- `raid-capture` — risks, assumptions, issues, dependencies as records
- `decision-drafting` — decision records with options, rationale, standard-vs-custom flag
- `change-management` — change impacts, stakeholder analysis, communications, readiness, Change Network, and training curriculum
- `governance-navigator` — chain of command, escalation paths, and who owns/decides what across the program's committees, workstreams, and pillar leads
- `source-to-import-workbooks` — turn DOCX/PDF/Visio discovery documents into stage-ready Import Review workbooks plus a review pack of extraction evidence
- `process-and-decision-modeling` — draft future-state BPMN 2.0 process maps and DMN 1.3 policy decision tables against the record layer, with conflict checks before submission
- `erp-module-build-guide` — produce a stage-by-stage ERP module build guide (Word docx, optionally with an editable Visio swimlane diagram) that tells someone in front of a blank tenant exactly which tasks to run and in what order

Conversion discovery (works from the SharePoint extract library, Packs 1–5):
- `peoplesoft-metadata-reader` — foundational: inventories, usage ranking, human translation
- `snapshot-diff` — config drift between dated snapshots
- `customization-analysis` — mods/bolt-ons → recovered requirements → disposition drafts
- `security-access-analysis` — who-can-do-what, role hygiene, SoD candidates, org-design input
- `integration-discovery` — what talks to PeopleSoft; what breaks at cutover
- `report-rationalization` — query/report estate → keep/replace/retire drafts
- `process-map-drafting` — current-state maps from system evidence + SME correction

Shared references (`plugins/erp-program/references/`):
- `extract-library-guide.md` — packs, file naming, the joins everything uses
- `output-conventions.md` — where outputs land, standard finding format, honesty rules

## House rules baked into every skill

Nothing canonical stays in chat; outputs land in the record layer (DRAFT, via MCP, schema-first) or as structured files in the extract library. Approvals are human-only. No identified employee/student/payroll data — the extract library is metadata, config, and telemetry only. Every claim cites its source file and snapshot date. Changes to skills come through pull requests.
