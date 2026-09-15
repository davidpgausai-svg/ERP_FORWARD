# Extract Runbook — producing PeopleSoft extracts without a consultant

The kit lives at `../../../extract-kit/`. Its `README.md` is the full operating manual; this runbook is the triage that gets a program member to the right part of it, plus the two paths the README does not cover — Query Manager, and page access.

## Step 0: which access do you actually have?

Ask in this order. Stop at the first yes.

1. **Can you — or a DBA who will run scripts for you — connect to the HCM, FSCM or CS database with a SQL tool?** → Database path. This is the census.
2. **Can you open Reporting Tools > Query > Query Manager and create a new query?** → PS Query path. Most of the raw tables; none of the derived analyses; usually no telemetry.
3. **Can you navigate the PeopleSoft pages?** → Page-access path: screenshots, per `pia-navigation-map.md`. Start here today, and ask for 1 or 2 in parallel.

Whatever the answer, do the "today" list at the bottom now.

## Database path

**Who.** Anyone with read access to each application database. A read-only reporting replica is preferred — note its lag; a two-day-old replica is fine for metadata and misleading for usage telemetry. Every script in the kit is a pure `SELECT`.

**Run order** (kit README § Run order), once per instance:

| # | Script | Why here |
|---|---|---|
| 1 | `00_discovery.sql` | Platform, releases, installed products, object counts, telemetry availability, tableset check, custom-prefix detection. **Read the output before going further** — it settles scope |
| 2 | `04_pack4_usage.sql` | Out of numeric order on purpose: `PSPRCSRQST` is purged on a schedule; everything else can be re-extracted next month |
| 3 | `06_manifest_and_qa.sql` §6.1–6.2 | Run header and expected row counts, recorded *before* extraction, so a truncated file can be told from a small table |
| 4 | `01_pack1_structure.sql` | Records, fields, lineage, pages, components, navigation, translates |
| 5–8 | `02`, `02b`, `02c`, `02d` | Logic, reporting, approvals, integrations |
| 9 | `03_pack3_setup_generator.sql` | Run it, then **run its generated `EXTRACT_STMT` output as a script** |
| 10 | Anchors for the instance | HCM: `03a` `03b` `03c` · FSCM: `03d` `03e` `03f` `03g` · CS: `03h` · all instances: `03i`. Each starts with an existence guard that generates statements only for the tables actually present |
| 11 | `05_pack5_customization.sql` | **Run §5.0 first** and set the patch-OPRID list, or every count is patch noise |
| 12 | `06_manifest_and_qa.sql` §6.3–6.6 | Manifest rows, pre-landing checks, completeness scorecard → `_P0_COMPLETENESS.csv` |

**Tool settings that matter** (kit README § Extract mechanics):

- SQL*Plus truncates LONG columns at 80 characters by default, and `PSSQLTEXTDEFN.SQLTEXT` / `PSPCMPROG.PROGTXT` are LONG on many Oracle installs. Before any Pack 2 run: `SET LONG 2000000` and `SET LONGCHUNKSIZE 2000000`, or use SQLcl. `00` §0.4 probes the datatypes so you know in advance.
- Output: pipe-delimited, UTF-8, header row, with any field containing `|`, `"` or a newline quoted. SQLcl: `SET SQLFORMAT delimited` with `|`. SSMS, DBeaver, Toad: export → CSV → delimiter `|`, quote all text. If the tool cannot quote properly, write Parquet instead.
- Oracle stops on a missing table (ORA-00942). Table availability varies by release and licence — that is what the existence guards are for. Note the table, comment the statement, continue.
- A rejected column in an explicit column list is usually a release difference, not a missing table. List the real columns: `SELECT FIELDNAME, FIELDNUM FROM PSRECFIELDDB WHERE RECNAME = '<RECORD>' ORDER BY FIELDNUM;`
- SQL Server and DB2 variants are inline at each point they differ. The three that recur: `BITAND(x,n)=n` → `(x & n)=n`; `TRUNC(d,'MM')` → `DATEFROMPARTS(YEAR(d),MONTH(d),1)`; `ALL_TABLES` → `INFORMATION_SCHEMA.TABLES`. Drop `FROM DUAL`.
- Large tables — `PSPNLFIELD`, `PSAUTHITEM`, `PSTREENODE`, `PSTREELEAF`, `PSPRCSRQST`: `00` §0.3 counts them first; `01` §1.4 slices `PSPNLFIELD` into three; `03i` §3i.7 measures each tree before extracting. Never `SELECT *` a tree table unqualified.

**File naming:** `<INSTANCE>_<PACK>_<OBJECT>.csv` — `HCM_P1_PSRECDEFN.csv`, `FSCM_P3_GL_ACCOUNT_TBL.csv`; slices take `_partN`. One dated folder per instance per run. `manifest.csv` from `extract_manifest_template.csv`, one row per file.

## PS Query path

**Who.** A functional user with Query Manager and — this is the gate — a permission list that grants the **PeopleTools** query access group, where the `PS*` metadata records live. If `PSRECDEFN` does not appear when you add a record to a new query, ask Security for that access group. It is read-only and routinely granted to analysts.

**What ports.** Any kit section that is a plain `SELECT * FROM <one table>`: most of `01`; the raw tables in `02`, `02b`, `02c`, `02d`; every `SELECT *` the `03a`–`03i` anchors generate; `PSROLEDEFN`, `PSCLASSDEFN`, `PSAUTHITEM`, `PSROLECLASS` from `03i`; `PSPROJECTDEFN` and `PSPROJECTITEM` from `05`. Build the query with all fields and no criteria, and download.

**What does not port** — record it in the manifest rather than approximating:

- `00` discovery probes (`ALL_TABLES`, `SYS_CONTEXT`, the datatype probe). Ask a DBA for `00` alone; it is ten minutes.
- The `03` setup generator and the `06` manifest generator (`BITAND`, `EXISTS`, string assembly). The anchors give you the tables the program asks about first; the complete generated list needs the database path.
- `01` §1.5b navigation paths (`CONNECT BY`). Download `PSPRSMDEFN` raw; the skill builds the breadcrumbs.
- `04` telemetry aggregates. `PSPRCSRQST` *is* queryable if the access group includes it: build a query on `PRCSNAME`, `RUNSTATUS`, `RQSTDTTM` with a date criterion, and aggregate in the sandbox. Prefer the pseudonymised form — leave `OPRID` out and add a count.
- The derived files (`_P2C_APPROVAL_ROUTES`, `_P2D_INTEGRATION_INVENTORY`, `_P3I_ACCESS_MATRIX`). Download the underlying tables; the skill rebuilds the joins.

**Mechanics that bite:**

- PS Query adds an effective-date criterion automatically on any effective-dated record. The kit takes full history. Delete the auto criterion, or write `current rows only` in the manifest `notes`.
- Query Viewer → Download to Excel caps at Excel's row limit and slows past a couple of hundred thousand rows. For `PSPNLFIELD`, `PSAUTHITEM`, `PSPRCSRQST`: slice with a criterion (the kit's `PNLNAME < 'H'` pattern), or use Schedule Query to a file.
- Output is comma-separated or Excel. Acceptable — put `comma` (or `xlsx`) in the manifest `delimiter` column and the skill loads it correctly. Do not re-save through Excel; it strips leading zeros from codes.
- You only see the queries your permissions allow. A `PSQRYDEFN` download from Query Manager is *your* view, not the estate — note it.

## Page-access path

`pia-navigation-map.md`. Start with the first-reads the library guide names — TableSet Control, Account Code Table, Budget Definitions, the Permission Lists behind the question, Process Monitor over the last 90 days, the Installation Table — because those change the question before an extract ever lands.

## Ask the App Admin for these now, in parallel

They cannot be got with SQL or Query, and they take days to turn around:

1. App Designer **Compare and Report** against DEMO, by object type → `<INSTANCE>_P5_APPDESIGNER_COMPARE.csv`. The authoritative customization list.
2. **SQR filesystem listing** — `ls -lR $PS_HOME/sqr $PS_CUST_HOME/sqr` with sizes and mtimes → `<INSTANCE>_P2B_SQR_FILELIST.txt`.
3. **PeopleCode project export** — a project of all PeopleCode objects, then Copy Project to File. Source is tokenised in the database; the CSV cannot carry it.

## Do these today, whichever path you are on

- **Turn on Performance Monitor.** Page-level usage cannot be backfilled. Sixty days of it before design workshops is worth more than the interview schedule.
- **Extend `PSPRCSRQST` retention** (PeopleTools > Process Scheduler > System Settings). Process history is the best evidence of what runs, and it is being purged right now.
- **Turn on query statistics logging** if `PSQRYEXECLOG` is empty.

## Sensitivity and landing

- P3i and P4 carry user IDs. Land them in a restricted path; never email any pack. Prefer `04` §4.1b (pseudonymised) unless names are the question.
- Before landing, run `06` §6.5 — person keys in setup tables (must be empty), credentials in `PSURLDEFN`, password columns — and keep the output. That is the evidence.
- `PS_BANK_ACCT_DEFN` / `PS_SRC_BANK`: list the columns first (`03e` §3e.2), exclude account numbers and IBANs, or skip the tables.
- Land in the program's agreed location — the library guide is location-neutral; the folder structure is not. Bring back to Claude: the dated folder, `manifest.csv`, `_P0_RUN_HEADER.csv`, `_P0_COMPLETENESS.csv`. That is enough to start Mode A.
