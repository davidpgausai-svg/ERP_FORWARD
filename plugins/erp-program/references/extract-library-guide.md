# Extract Library Guide

The SharePoint extract library is the program's file-based integration layer. A DBA-owned scheduled job runs the extract kit (versioned in the erp-forward repo under `extract-kit/`) against each PeopleSoft instance and lands dated snapshot folders:

```
/extracts/<INSTANCE>/<YYYY-MM-DD>/
  <INSTANCE>_P1_PSRECDEFN.csv
  <INSTANCE>_P1_PSPRSMDEFN.csv
  ...
  manifest.csv        <- one row per file: row count, extract timestamp, kit version
```

Instances: HCM, FSCM, CS (Campus Solutions). Files are pipe-delimited CSVs with header rows.

## What each pack contains

| Pack | Files prefixed | Contents | Use it for |
|---|---|---|---|
| P1 | `_P1_` | PSRECDEFN (records), PSRECFIELDDB (fields; key flag = BITAND(USEEDIT,1)), PSDBFIELD, PSPNLDEFN/PSPNLFIELD (pages), PSPNLGRPDEFN (components), PSMENUITEM, PSPRSMDEFN (portal navigation), PSXLATITEM (dropdown values) | What the system is: data dictionary, screens, navigation |
| P2 | `_P2_` | PeopleCode inventory (PSPCMPROG rows, no source), PSSQLDEFN/PSSQLTEXTDEFN (SQL text, reassemble on SQLID+SEQNUM), App Engine (PSAEAPPLDEFN/SECT/STEP/STMT), PSPRCSDEFN/PSJOBDEFN (processes), PSQRYDEFN + PSQRYRECORD/FIELD/CRITERIA (queries), EOAW* (approval routes), PSNODEDEFN/PSMSGDEFN + PSIB* (integrations) | What the system does: logic, batch, approvals, interfaces |
| P3 | `_P3_` | SETID/BUSINESS_UNIT-keyed setup tables, generated per instance; OBJECTOWNERID groups by module (HR, PY, GL, AP, PO, SR, SF...) | What the system is configured to do |
| P3d | `_P3D_` | PSROLEDEFN, PSCLASSDEFN, PSAUTHITEM (access matrix), PSROLECLASS, PSROLEUSER, PSOPRDEFN (trimmed), PSTREE* (org/chartfield/security trees), dept security | Who can do what; org & reporting structures |
| P4 | `_P4_` | Aggregated telemetry: process runs by month/user, dead processes, query usage, monthly active users, IB traffic aggregates | What is actually used — the ranking signal |
| P5 | `_P5_` | Non-PPLSOFT customization sweep by object type, site-prefix custom objects, query inventory, PSPROJECTDEFN/ITEM migration history | What the institution changed |

## Joins you will use constantly

- Record → fields: `PSRECDEFN.RECNAME = PSRECFIELDDB.RECNAME`; key fields where `BITAND(USEEDIT,1)=1`.
- Component → pages: PSPNLGRPDEFN → PSPNLFIELD/PSPNLDEFN; component is the user-facing unit.
- Navigation: PSPRSMDEFN is hierarchical via `PORTAL_OBJNAME`/`PORTAL_PRNTOBJNAME`; build breadcrumb paths before presenting anything to humans — nobody recognizes internal object names.
- Access matrix: PSROLEUSER (user→role) → PSROLECLASS (role→permission list) → PSAUTHITEM (permission list→menu/component). This chain answers "who can do X" and "what can Y do".
- Usage ranking: join any object inventory to P4 aggregates; objects with no telemetry rows are candidates for the "dead" pile — but check whether telemetry history is long enough to judge (year-end processes run once a year).
- Module attribution: `OBJECTOWNERID` on PSRECDEFN maps objects to owning product — this is how one analysis serves finance, student, HR, payroll, and supply chain separately.

## Rules that keep the simple path safe

- The library contains Packs 1–5 only: metadata, configuration, telemetry. If a file appears to contain identified employee, student, supplier-bank, or payroll rows, stop, do not analyze it, and flag it to the program lead — it should not be in this library.
- Always record which snapshot date and instance an analysis used. Findings without provenance can't be trusted or reproduced.
- Check `manifest.csv` row counts against what you loaded before drawing conclusions; a truncated file silently skews everything downstream.
