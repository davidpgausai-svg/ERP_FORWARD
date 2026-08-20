# ERP FORWARD — PeopleSoft Enterprise Extract Kit v1

Purpose: mass-export the PeopleSoft environment — structure, logic, configuration, usage, and customizations — as CSV files that land in Databricks for Claude-assisted discovery. Covers the ENTIRE enterprise: HCM (HR/Payroll/Benefits/Time), FSCM (GL/AP/AR/Purchasing/Projects/Grants/Assets/Inventory), and Campus Solutions (student), plus Interaction Hub if present.

## The key design fact

PeopleSoft applications are all built on the same PeopleTools layer. The application definition — every table, page, component, menu, approval route, program, query, and security grant — lives in `PS*` metadata tables inside each application database. Therefore:

- **Packs 1, 2, 4, 5 are pillar-agnostic.** The identical scripts run unchanged against HCM, FSCM, and Campus Solutions databases. Run the kit once per database instance.
- **Pack 3 (functional setup) generates itself.** Instead of hardcoding hundreds of setup-table names per pillar, script 03 derives the complete setup-table inventory from the metadata (records keyed by SETID or BUSINESS_UNIT), then emits the extract statements. Anchor lists for the highest-value known tables are included per pillar, each guarded by an existence check against your PSRECDEFN.

## How to run

1. Identify your instances (typically separate databases): HCM, FSCM, CS. Also locate the delivered DEMO database for each if retained — it enables formal customization compare later.
2. Run against a READ-ONLY reporting replica where available. All scripts are pure SELECTs.
3. Run `00_discovery.sql` first per instance; review, then run packs in order.
4. Export each result set to CSV named `<instance>_<pack>_<object>.csv`, e.g. `HCM_P1_PSRECDEFN.csv`. UTF-8, header row, pipe or comma delimited (pipe preferred — PeopleSoft descriptions contain commas).
5. Complete `extract_manifest_template.csv` — one row per file with row count and run timestamp. The manifest is required for intake to Databricks.
6. Land everything in the agreed Databricks location. Do not email files.

## Sensitivity guide

| Pack | Contents | Sensitivity |
|---|---|---|
| 1 Structure | Table/page/menu/navigation metadata | None — no business data |
| 2 Logic & process | Code, SQL, process & approval definitions | Low — logic may reveal business rules; no person data |
| 3 Setup | Configuration values (departments, job codes, chartfields, terms) | Low — organizational reference data; no person-level rows |
| 3d Security | Roles, permissions, user role assignments, trees | Moderate — includes user IDs; treat as INTERNAL |
| 4 Usage | Process/query/login telemetry (aggregated by default) | Moderate — includes user IDs; aggregates preferred |
| 5 Customization | Metadata rows changed by non-Oracle operators | None — metadata only |

No pack extracts employee, payroll, student, or supplier transactional rows. Master/transactional data conversion is a separate, later exercise with its own governance.

## Practical cautions

- `PSPRCSRQST` (process history) is routinely purged — extract it NOW and consider extending retention; it is the single best "what actually runs" source.
- Query execution logging (`PSQRYEXECLOG`) and Performance Monitor (`PSPMTRANSHIST`) may not be enabled. If absent, enable prospectively — 60 days of telemetry is worth having before design workshops.
- PeopleCode source in `PSPCMPROG` is stored tokenized. The reliable export path is Application Designer: build a project of all PeopleCode objects and use Copy Project to File; open-source decoders are an alternative. Script 02 still extracts the PeopleCode *inventory* (which objects have code, size, last update) via SQL.
- Oracle syntax is used (BITAND, TRUNC, SYSDATE). SQL Server equivalents noted inline where they differ.
- Some anchor table names vary by release/module licensing. Every anchor list begins with an existence check — run it, extract what exists, note what doesn't.

## File list

- `00_discovery.sql` — instance identification, versions, object counts, table-family discovery
- `01_pack1_structure.sql` — records, fields, pages, components, menus, portal navigation, translate values
- `02_pack2_logic_process.sql` — PeopleCode inventory, SQL objects, App Engine, processes/jobs, queries, AWE approvals, legacy workflow, Integration Broker
- `03_pack3_setup_generator.sql` — self-generating setup-table inventory + extract statement generator
- `03a_anchors_hcm.sql` / `03b_anchors_fscm.sql` / `03c_anchors_campus.sql` — per-pillar anchor tables
- `03d_security_trees.sql` — roles, permission lists, page access, user assignments, trees, dept security
- `04_pack4_usage.sql` — process/query/login/IB telemetry, aggregated
- `05_pack5_customization.sql` — non-PPLSOFT sweep across all object types, project history, DEMO-compare notes
- `extract_manifest_template.csv`
