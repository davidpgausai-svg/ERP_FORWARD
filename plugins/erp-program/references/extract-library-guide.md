# Extract Library Guide

The extract library is wherever the program lands PeopleSoft extract-kit output — a shared drive, Google Drive, Databricks, a folder on the analyst's laptop. Location is a program choice; **structure is not**. Every skill in this plugin assumes the layout below, and the kit's own README (`../extract-kit/README.md`) is the operating manual for producing it.

```
<library>/<INSTANCE>/<YYYY-MM-DD>/
  <INSTANCE>_P0_RUN_HEADER.csv        <- land first
  <INSTANCE>_P0_EXPECTED_COUNTS.csv
  <INSTANCE>_P1_PSRECDEFN.csv
  ...
  <INSTANCE>_P0_COMPLETENESS.csv      <- land last
  manifest.csv                         <- one row per file (schema below)
```

Instances: `HCM`, `FSCM`, `CS`. One dated folder per extract run per instance. Files are pipe-delimited, UTF-8, header row, RFC 4180 quoting with `|` as the separator — unless the manifest's `delimiter` column says otherwise. PS Query downloads are comma/Excel; that is acceptable when it is recorded.

## Three ways evidence arrives

| Source | Coverage | Confidence | Provenance you must record |
|---|---|---|---|
| Extract kit, run by someone with database read access | Census — every row of every table the kit selects | HIGH | instance, snapshot date, kit version, manifest row |
| PS Query downloads by a functional user with Query Manager | Census for the tables they could query; usually no telemetry, no generated lists | HIGH for what is there; state what is missing | instance, date, query name, criteria used, whether effective-date history was included |
| Screenshots of PeopleSoft pages (PIA) by anyone who can navigate | Sample — never a census, except the "N of M" count on a search-results header | MEDIUM at best | navigation path, capture date, who captured it, which SETID/BU was on screen |

All three feed the same analysis method. What changes is what you are allowed to claim. A screenshot set is evidence about specific objects; it is not an inventory, and no skill may present it as one. `../skills/peoplesoft-metadata-reader/references/pia-navigation-map.md` maps pages onto packs and tables.

## Packs (kit v2)

| Pack | File prefix | Kit file(s) | Contents | Use it for |
|---|---|---|---|---|
| P0 | `_P0_` | `00`, `06` | Run header (instance, tools release, app release, extracted-by, run time); expected row counts; completeness scorecard | Provenance, and the go/no-go for analysis |
| P1 | `_P1_` | `01` | PSRECDEFN (records); PSRECFIELD (as-designed fields, carries `EDITTABLE` lineage); PSRECFIELDDB (physical columns); PSDBFIELD, PSDBFLDLABL; PSPNLDEFN + PSPNLFIELD (pages; PSPNLFIELD sliced `_part1..3`); PSPNLGRPDEFN + PSPNLGROUP (components and their pages); PSMENUDEFN/ITEM; PSPRSMDEFN + PSPRSMPERM (portal navigation); PSXLATITEM (full history); PSINDEXDEFN/PSKEYDEFN; lineage edge list; subrecord map; effective-dating profile | What the system *is* |
| P2 | `_P2_` | `02` | PeopleCode inventory (PSPCMPROG rows, no source); SQL objects (PSSQLDEFN + PSSQLTEXTDEFN — reassemble on SQLID+SEQNUM); App Engine (PSAEAPPLDEFN/SECT/STEP/STMT); Process Scheduler (PSPRCSDEFN, PSJOBDEFN, PSPRCSJOBITEM, PSRECURDEFN); PS Query (PSQRYDEFN + RECORD/FIELD/CRITERIA); legacy workflow; message catalogue | What the system *does* |
| P2b | `_P2B_` | `02b` | BI Publisher, nVision, SQR registry, Crystal, output distribution, estate rollup by engine; plus the manual SQR filesystem listing `_P2B_SQR_FILELIST.txt` | The reporting estate |
| P2c | `_P2C_` | `02c` | AWE: transactions, processes, stages, paths, steps, criteria, user lists, notifications, delegation, live volumes, dead routes; derived `_P2C_APPROVAL_ROUTES.csv` | Approvals — the already-sequenced half of every process map |
| P2d | `_P2D_` | `02d` | Integration Broker nodes, services, operations, routings, handlers, queues; file layouts; URL definitions; journal sources; traffic aggregates; derived `_P2D_INTEGRATION_INVENTORY.csv` | What talks to PeopleSoft |
| P3 | `_P3_` | `03`, `03a`–`03h` | `_P3_SETUP_INVENTORY.csv` (the generator's list) and one `_P3_<RECNAME>.csv` per SETID/BU-keyed setup table; tableset control (`SET_CNTRL_REC`, `SET_CNTRL_GROUP`, `REC_GROUP_TBL`, `SETID_TBL`); anchors per pillar — HCM core (`03a`), Payroll NA (`03b`), Benefits/Absence/T&L (`03c`), GL/chartfields/ledgers/BUs (`03d`), P2P/AR/Billing (`03e`), AM/PC/Grants/Expenses (`03f`), Commitment Control + combo edits (`03g`), Campus (`03h`) | What the system is *configured* to do |
| P3i | `_P3I_` | `03i` | PSROLEDEFN, PSCLASSDEFN, PSAUTHITEM, PSROLECLASS, PSROLEUSER, PSOPRDEFN (trimmed); batch/process security; row-level security; PSTREE* with volume guards; account hygiene; derived `_P3I_ACCESS_MATRIX.csv` | Who can do what; org, chartfield and security trees |
| P4 | `_P4_` | `04` | Capture window; process usage by month/user with durations and failure rates; batch-window profile; dead processes; query and login usage; page telemetry (Performance Monitor, where on); usage × customization quadrants; pseudonymised variant (§4.1b) | What is *actually used* — the ranking signal |
| P5 | `_P5_` | `05` | Patch-noise control (§5.0 — set the patch-OPRID list first); non-PPLSOFT sweep by object type; custom fields on delivered records; site-prefix custom objects; recency and clustering; PSPROJECTDEFN/ITEM migration history; plus the manual App Designer compare `_P5_APPDESIGNER_COMPARE.csv` | What the institution *changed* |
| P6 | — | `06` | Manifest row generator, sensitivity classification, pre-landing checks (person keys, credentials in URLs, password columns) | The controls that make the rest trustworthy |

**Pack names changed between kit v1 and v2.** Security and trees were `P3d`; they are now **`P3i`** (`03d` is FSCM core). If a colleague or an older note says `_P3D_`, they mean `_P3I_`. `P0`, `P2b`–`P2d` and `P6` did not exist in v1.

## Three deliverables that are not SQL

The kit asks the App Admin for these because no query produces them. Treat their absence as a known gap, not a surprise:

1. **App Designer compare against DEMO** → `_P5_APPDESIGNER_COMPARE.csv`. The authoritative customization report; the P5 SQL sweep is the approximation.
2. **SQR filesystem listing** → `_P2B_SQR_FILELIST.txt`. The registry (`PSPRCSDEFN`) lists what is *scheduled*; the filesystem lists what *exists*.
3. **PeopleCode project export** (Copy Project to File). PeopleCode is tokenised in the database; P2 holds the inventory, not the source.

## Read these first, every time

The kit's README singles these out because they routinely change what the program thinks it knows. Open them before any ranking or inventory:

- `_P0_COMPLETENESS.csv` — nine machine checks. **Gate your analysis on it** (table below).
- `_P3_SET_CNTRL_REC.csv` (kit §3.0b) — business unit → record group → SETID. Without it every SETID-keyed file is uninterpretable.
- `_P3_ACCT_CD_TBL.csv` (§3b.2, HCM) — payroll → GL chartfield mapping. The HR/Finance contract, usually undocumented.
- Control budget profile (§3g.2, FSCM) — what is budget-checked, at what chartfield level, with what tolerance.
- `_P3I_ACCESS_MATRIX.csv` (§3i.3) — role → permission list → component. Answers most who-does-what questions without an interview.
- Usage × customization (§4.7) — four quadrants: used + customised (migrate the requirement), used + delivered (lowest risk), unused + customised (retire, don't rebuild), unused + delivered (scope reduction).

## Gate on the completeness scorecard

| Scorecard line | If FAIL / CHECK | Then |
|---|---|---|
| Process history retained (P4) | FAIL | Do **not** rank by usage. Say "no usable telemetry; ranking deferred until PSPRCSRQST retention is extended." |
| Query execution logging enabled | FAIL | Report usage cannot be measured; inventory only. |
| Performance Monitor enabled | FAIL | Page-level usage unavailable; component ranking falls back to process and query signals only. Tell the user to turn it on today — it cannot be backfilled. |
| SET_CNTRL_REC populated (P3) | FAIL | Do not interpret any SETID-keyed setup table. Request the tableset extract first. |
| EDITTABLE relationships found (P1) | FAIL | PSRECFIELD was not extracted; lineage and the improved P3 generator are unavailable. Fall back to PSRECFIELDDB and say so. |
| AWE transactions / Service operations | CHECK | May legitimately be unused; confirm with the App Admin before calling approvals or integrations "absent." |
| App Designer compare obtained | MANUAL | Until it lands, every customization count is an approximation from `LASTUPDOPRID`. Label it. |

One check the scorecard cannot make: **LONG truncation.** If the widest `SQLTEXT` in `_P2_PSSQLTEXTDEFN.csv` is ≤ 80 characters, the extract was truncated by SQL*Plus defaults (kit README § Extract mechanics). Do not analyze SQL text; flag it.

## Decodes you will need constantly

- `PSRECDEFN.RECTYPE`: 0 = SQL table, 1 = SQL view, 2 = derived/work, 3 = subrecord, 5 = dynamic view, 6 = query view, 7 = temporary table. Only RECTYPE 0 is a physical table with data.
- `PSRECDEFN.OBJECTOWNERID` → owning product; decode via `PSOBJGROUP` (P0). This is how one analysis serves HR, payroll, finance, student and supply chain separately.
- `PSRECFIELDDB.USEEDIT` bits: 1 key · 2 duplicate-order key · 4 alternate search · 16 required · 256 descending · 1024 / 2048 / 4096 audit add / change / delete. Key fields: `BITAND(USEEDIT,1)=1` (Oracle) or `(USEEDIT & 1)=1` (SQL Server). Kit §1.2b emits these pre-decoded as `IS_KEY`, `IS_REQUIRED`, and so on.
- `PSRECFIELD` vs `PSRECFIELDDB`: as-designed (subrecord references intact; carries `EDITTABLE` and `DEFRECNAME`) versus physical (subrecords expanded to columns). Lineage comes from PSRECFIELD; column lists from PSRECFIELDDB. They are not interchangeable.
- `PSRECFIELD.EDITTABLE` = the prompt table a field validates against. This is PeopleSoft's foreign-key graph; kit §1.3 emits it as an edge list.
- Physical table name: `RECTYPE=0 AND SQLTABLENAME=' '` → `PS_<RECNAME>`; otherwise `SQLTABLENAME`.
- Effective dating: a record with an `EFFDT` field carries history; ask "as of when?" before counting rows. PS Query adds a current-effective-date criterion automatically — the kit takes full history.

## Joins you will use constantly

- Record → fields: `PSRECDEFN.RECNAME = PSRECFIELDDB.RECNAME`.
- Component → pages: `PSPNLGRPDEFN` → `PSPNLGROUP` → `PSPNLDEFN`. The component is the user-facing unit.
- Navigation: `PSPRSMDEFN` is hierarchical on `PORTAL_OBJNAME` / `PORTAL_PRNTOBJNAME` within a `PORTAL_NAME`. Build breadcrumb paths (`PORTAL_LABEL` joined with " > ") before showing anything to a human; kit §1.5b does this per portal.
- Access chain: `PSROLEUSER` (user → role) → `PSROLECLASS` (role → permission list) → `PSAUTHITEM` (permission list → menu/component). `_P3I_ACCESS_MATRIX.csv` is this join, pre-built.
- SETID resolution: `BUSINESS_UNIT` → `SET_CNTRL_REC` (by `REC_GROUP_ID`) → `SETID`. Never assume `SETID = BUSINESS_UNIT`.
- Usage ranking: join any inventory to P4 aggregates on process name, query name or component. No telemetry row ≠ dead — check the capture window in `_P4_` first; year-end payroll and fiscal-close objects run once a year.
- Module attribution: `OBJECTOWNERID` on `PSRECDEFN` and `PSPNLGRPDEFN`; for queries, via the records they read (`PSQRYRECORD` → `PSRECDEFN`).

## Manifest

`manifest.csv` is the control, not a formality. One row per landed file (template: `../extract-kit/extract_manifest_template.csv`):

`file_name | instance | pack | source_object | row_count_expected | row_count_actual | classification | contains_user_ids | extract_window_start | extract_window_end | extracted_at | extracted_by | delimiter | encoding | truncated_flag | notes`

Before concluding anything: `row_count_actual` versus the rows you loaded versus `row_count_expected` (from `_P0_EXPECTED_COUNTS.csv`). A mismatch is a failed extract, not a small table. `truncated_flag = Y` or `delimiter ≠ pipe` changes how you load the file — read it.

## Rules that keep the simple path safe

- The library holds metadata, configuration and aggregated telemetry — Packs 0–6. **No pack extracts employee, student, supplier, customer or payroll transactional rows.** If a file appears to contain identified person rows, stop, do not analyze it, and flag it to the program lead. Kit §3.6 and §6.5(a) exist to prevent this; a file that got through is an incident, not a data source.
- P3i and P4 carry user IDs — **Internal Restricted**. They belong in a restricted-ACL path and are never emailed. The pseudonymised P4 form (§4.1b) is sufficient for almost all discovery analysis; prefer it when the question does not need names.
- `PSURLDEFN` may carry embedded credentials (§6.5(b)); `PS_BANK_ACCT_DEFN` / `PS_SRC_BANK` carry account numbers (§3e.2). Both are flagged in the kit. If either lands unredacted, do not use it; flag it.
- Always record instance + snapshot date + kit version on everything you produce. Findings without provenance cannot be trusted or reproduced.
- When reading vendor documentation to interpret a table or page, match the release first — `TOOLSREL` from `_P0_RUN_HEADER.csv`, application release from `PSRELEASE`. Sources are listed in `peoplesoft-reference-sources.md`.
