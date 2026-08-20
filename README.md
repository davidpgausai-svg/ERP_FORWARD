[README.md](https://github.com/user-attachments/files/31270721/README.md)
# erp-forward — Cowork Plugin

ERP FORWARD program skills. Install by adding this repo as a plugin marketplace in Claude (Cowork / Claude Code), then installing the `erp-program` plugin. Enterprise admins can deploy it workspace-wide.

## Skills

Program operations:
- `status-reporting` — workstream/program status and steering packets
- `raid-capture` — risks, assumptions, issues, dependencies as records
- `decision-drafting` — decision records with options, rationale, standard-vs-custom flag

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
