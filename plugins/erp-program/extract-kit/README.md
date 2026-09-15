# PeopleSoft Extract Kit — Operating Instructions

Mass-export the PeopleSoft environment — structure, logic, configuration, usage
and customizations — as CSV files landing in Databricks for discovery analysis.

**Scope:** finance, HR and payroll. North American Payroll. All FSCM modules.
Campus Solutions at anchor level (the student-financials→GL and academic-org→HR
crosswalks belong to the finance and HR picture).

**Everything in this kit is a pure `SELECT`.** Nothing writes, updates or locks.

---

## Before you start

**You need:** read access to each application database — HCM, FSCM, CS. A
read-only reporting replica is preferred; if you use one, note its lag, because
a two-day-old replica is fine for metadata and misleading for usage telemetry.

**You'll also need three things the App Admin has to produce, because they can't
be got with SQL.** Request them now, in parallel with the extract:

1. **App Designer compare against DEMO** — Tools → Compare and Report, by object
   type. This is the authoritative customization report. Save as
   `<instance>_P5_APPDESIGNER_COMPARE.csv`.
2. **SQR filesystem listing** — `ls -lR $PS_HOME/sqr $PS_CUST_HOME/sqr` with
   sizes and mtimes, plus a tarball of anything matching your custom prefixes.
   Save as `<instance>_P2B_SQR_FILELIST.txt`.
3. **PeopleCode project export** — build a project of all PeopleCode objects,
   then Copy Project to File. PeopleCode source is tokenised in the database and
   does not export usefully as CSV.

**Do two things this week, regardless of when the extract runs:**

- **Turn on Performance Monitor.** Page-level telemetry cannot be collected
  retrospectively. Sixty days of it before design workshops is worth more than
  any interview schedule.
- **Extend `PSPRCSRQST` retention.** Process history is the best evidence of
  what actually runs, and it is being purged on a schedule right now.

---

## Run order

Run this sequence **once per instance**. Pack 4 comes early on purpose:
everything else can be re-extracted next month; purged process history cannot.

| # | Script | What it does |
|---|---|---|
| 1 | `00_discovery.sql` | Platform, releases, licensed modules, object counts, telemetry availability. **Read the output before going further** — it tells you what exists and settles most scope questions. |
| 2 | `04_pack4_usage.sql` | Process, query and login telemetry. Run this second, out of numeric order. |
| 3 | `06_manifest_and_qa.sql` §6.1–6.2 | Run header and expected row counts, recorded *before* extraction. |
| 4 | `01_pack1_structure.sql` | Records, fields, lineage, pages, components, menus, navigation, translate values. |
| 5 | `02_pack2_logic_process.sql` | PeopleCode inventory, SQL objects, App Engine, Process Scheduler, PS Query. |
| 6 | `02b_pack2_reporting_estate.sql` | nVision, BI Publisher, SQR registry, Crystal, output distribution. |
| 7 | `02c_pack2_approvals_workflow.sql` | Approval routes, criteria, approver lists, delegation. |
| 8 | `02d_pack2_integration.sql` | Integration Broker, file layouts, journal sources, traffic. |
| 9 | `03_pack3_setup_generator.sql` | Tableset controls, then the setup-table inventory. **Run it, then run its generated output as a script.** |
| 10 | Anchors for this instance | HCM: `03a`, `03b`, `03c`. FSCM: `03d`, `03e`, `03f`, `03g`. CS: `03h`. All instances: `03i`. |
| 11 | `05_pack5_customization.sql` | **Run §5.0 first** and set your patch-OPRID list before running the rest. |
| 12 | `06_manifest_and_qa.sql` §6.3–6.6 | Manifest rows, pre-landing checks, completeness scorecard. |

### How the anchor files work

Each `03a`–`03h` file starts with one query that checks which anchor tables exist
on your instance and **generates the extract statement for each one it finds**.
Run that query, then run the `EXTRACT_STMT` column as a script. Tables reported
`ABSENT` produce a comment line, so you can run the whole output safely.

The `03` generator is authoritative for the complete setup list. The anchors are
the tables the programme will ask about first. `03` §3.9 reconciles the two — if
an anchor doesn't appear in the generator output, report it rather than assuming
the generator was complete.

---

## Extract mechanics

**File naming.** `<instance>_<pack>_<object>.csv` — e.g. `HCM_P1_PSRECDEFN.csv`,
`FSCM_P3_GL_ACCOUNT_TBL.csv`. Sliced files take `_partN`.

**Format.** Pipe-delimited (`|`), UTF-8, header row. PeopleSoft descriptions
contain commas, and some contain pipes and embedded newlines — so use a writer
that quotes any field containing the delimiter, a quote or a newline (RFC 4180
quoting with `|` as separator). If your tooling can't do that, write Parquet
instead; Databricks prefers it and the problem disappears.

**LONG columns — check this before you trust the output.** `PSSQLTEXTDEFN.SQLTEXT`
and `PSPCMPROG.PROGTXT` are LONG or LONG RAW on many releases, and SQL\*Plus
truncates LONG at 80 characters by default. The result looks like a complete set
of files containing one-line stubs of every view and SQL object in the estate.
`00_discovery.sql` §0.4 probes the datatypes. If they come back LONG:

```
SET LONG 2000000
SET LONGCHUNKSIZE 2000000
```

or use SQLcl rather than SQL\*Plus. Once extracted, eyeball the widest values in
`PSSQLTEXTDEFN` — if none exceeds 80 characters, it's truncated, not small.

**Large tables.** `PSPNLFIELD`, `PSAUTHITEM`, `PSTREENODE`, `PSTREELEAF` and
`PSPRCSRQST` are the repeat offenders and run to millions of rows. `00` §0.3
counts them first. `01` §1.4 slices `PSPNLFIELD` into three; `03i` §3i.7 measures
each tree before extracting and pulls current-effective trees by name — do not
run an unqualified `SELECT *` on the tree tables.

**Platform.** Scripts are written for Oracle, with SQL Server and DB2 variants
inline at each point they differ. The three that recur:

| Oracle | SQL Server |
|---|---|
| `BITAND(x,n) = n` | `(x & n) = n` |
| `TRUNC(d,'MM')` | `DATEFROMPARTS(YEAR(d),MONTH(d),1)` |
| `ALL_TABLES` | `INFORMATION_SCHEMA.TABLES` + `TABLE_TYPE='BASE TABLE'` |

Anchor files also use `FROM DUAL` in their `WITH` clauses — drop it on SQL Server.

**Missing tables.** On Oracle a missing table raises ORA-00942 and stops the
script. Table availability varies by release and licensing, which is what the
existence guards are for. If a script stops, note the table, comment the
statement, and continue.

**Column names drift between releases.** Where a script selects an explicit
column list (approval routes, budget definitions, F&A rates), a rejected column
usually means a release difference, not a missing table. List the real columns
and adjust:

```sql
SELECT FIELDNAME, FIELDNUM FROM PSRECFIELDDB
 WHERE RECNAME = '<RECORD>' ORDER BY FIELDNUM;
```

---

## Manifest

Every landed file gets one row in `extract_manifest_template.csv`. The manifest
is required for Databricks intake — it's what lets the intake team tell a
truncated extract from a small table.

`06_manifest_and_qa.sql` does most of the work: §6.1 emits the run header, §6.2
the expected row counts, §6.3 generates ready-to-paste manifest rows for every
Pack 3 table. Fill in actual row counts after extraction and reconcile against
§6.2.

Finish with §6.6, the completeness scorecard — nine machine-checked assertions.
Land it as `<instance>_P0_COMPLETENESS.csv` and put it in front of the programme
before any analysis starts, and again every time the extract is refreshed.

---

## Sensitivity

| Pack | Contents | Classification |
|---|---|---|
| 0 Discovery | Versions, counts, telemetry availability | Internal |
| 1 Structure | Table/page/menu metadata, lineage | Internal — no business data |
| 2 Logic & process | Code inventory, SQL, App Engine, processes, queries | Internal — logic reveals business rules |
| 2b Reporting | Report and layout definitions | Internal |
| 2c Approvals | Routes, criteria, approver user lists | Internal — contains user IDs |
| 2d Integration | Nodes, operations, routings, file layouts | Internal — check `PSURLDEFN` for embedded credentials |
| 3 Setup | Configuration values | Internal — organisational reference data |
| 3i Security | Roles, permissions, assignments, trees | **Internal Restricted** — user IDs |
| 4 Usage | Process/query/login telemetry | **Internal Restricted** — user IDs |
| 5 Customization | Metadata changed by non-Oracle operators | Internal — metadata only |
| 6 Manifest & QA | Counts, classifications, checks | Internal |

**No pack extracts employee, payroll, student, supplier or customer transactional
rows.** Where transaction tables appear, they appear only in `GROUP BY` aggregates
for sizing — no identifiers, no per-person amounts. `03` §3.6 excludes
person-keyed records from the generator and `06` §6.5 re-checks before landing.
Run both and keep the output; that's your evidence, not the assertion.

If your data-protection review would rather not land raw operator IDs, `04` §4.1b
is a pseudonymised form of the usage extract using distinct-operator counts. It's
sufficient for almost all discovery analysis.

**Two tables need a judgement call before export**, and both are flagged in place:

- `PS_BANK_ACCT_DEFN` / `PS_SRC_BANK` — list the columns first (`03e` §3e.2),
  exclude account numbers and IBANs, or skip the tables. Bank account setup is
  rarely needed for discovery and always needed for an incident report if it leaks.
- `PSURLDEFN` — can carry credentials embedded in URL strings. `06` §6.5(b)
  scans for them. Redact before landing.

**Do not email files.** Land everything in the agreed Databricks location, with
Pack 3i and Pack 4 in a restricted-ACL path.

---

## File list

| File | Contents |
|---|---|
| `00_discovery.sql` | Platform, releases, licensed modules, object counts, datatype probe, table-family discovery, tableset check, telemetry availability, custom-prefix detection |
| `01_pack1_structure.sql` | Records, fields, lineage edge list, subrecord map, pages, components, menus, portal navigation, translate values, effective-dating profile, indexes |
| `02_pack2_logic_process.sql` | PeopleCode inventory, SQL objects, App Engine, Process Scheduler with jobs/steps/recurrences, full PS Query object set, legacy workflow, message catalogue |
| `02b_pack2_reporting_estate.sql` | BI Publisher, nVision, SQR, Crystal, output distribution, estate rollup by engine |
| `02c_pack2_approvals_workflow.sql` | Approval transactions, processes, stages, paths, steps, criteria, user lists, notifications, delegation, live volumes, dead routes |
| `02d_pack2_integration.sql` | IB nodes, services, operations, routings, handlers, queues, file layouts, URL definitions, journal sources, traffic aggregates, silent integrations |
| `03_pack3_setup_generator.sql` | Tableset controls, four-strategy setup detection, unified inventory, person-key exclusion, count and extract generators, anchor reconciliation |
| `03a_anchors_hcm_core.sql` | HR org structure, jobs, positions, compensation framework, action/reason usage |
| `03b_anchors_payroll_na.sql` | Pay structure, earnings, deductions, garnishments, tax setup, retro pay, payroll→GL account codes, dormant-code analysis, payroll batch estate |
| `03c_anchors_benefits_time.sql` | Benefits, BenAdmin, absence, Time & Labor rules and TRC usage |
| `03d_anchors_fscm_core.sql` | GL chartfields, ledgers, calendars, business units, journal sources, chartfield configured-vs-used profile |
| `03e_anchors_fscm_p2p_ar_bi.sql` | Purchasing, Payables, Receivables, Billing, Cash, Inventory reference; explicit out-of-scope list with sizing aggregates |
| `03f_anchors_fscm_am_pc_gm_ex.sql` | Asset Management, Project Costing, Grants (incl. F&A rates), Travel & Expenses |
| `03g_anchors_fscm_kk_comboedit.sql` | Commitment Control budgets and source transactions, combination edits, journal generator |
| `03h_anchors_campus.sql` | CS anchors, student-financials→GL crosswalk, academic-org↔HR-department crosswalk, term calendar |
| `03i_security_trees.sql` | Roles, permission lists, access matrix, batch/process security, row-level security, trees with volume guards, account hygiene |
| `04_pack4_usage.sql` | Capture window, process usage with durations and failure rates, batch window profile, dead processes, query and login usage, page telemetry, usage × customization |
| `05_pack5_customization.sql` | Patch-noise control, customization summary and detail, custom fields on delivered records, custom-built objects, recency and clustering, project history |
| `06_manifest_and_qa.sql` | Run header, expected counts, manifest generator, classification, pre-landing checks, completeness scorecard |
| `extract_manifest_template.csv` | Manifest with classification, capture window, delimiter, encoding and truncation columns |

---

## Notes on a few outputs worth reading yourself

Most of the kit is bulk extraction for downstream analysis. These few results are
worth a human look on the day they're produced, because they routinely change
what the programme thinks it knows:

- **`03` §3.0b** — the business-unit → record-group → SETID map. Without it,
  every SETID-keyed file is uninterpretable.
- **`03b` §3b.2** — `ACCT_CD_TBL`, the payroll-to-GL chartfield mapping. It's the
  contract between HR and Finance and it's usually undocumented.
- **`03g` §3g.2** — the control budget profile: what's budget-checked, at what
  chartfield level, with what tolerance.
- **`03i` §3i.3** — the role → permission list → component access matrix. It
  answers most who-does-what questions without an interview.
- **`04` §4.7** — usage crossed with customization. Four quadrants: used +
  customised (migrate the requirement), used + delivered (lowest risk), unused +
  customised (retire, don't rebuild), unused + delivered (scope reduction).
- **`06` §6.6** — the completeness scorecard. Read it before anyone starts
  analysing the extract.
