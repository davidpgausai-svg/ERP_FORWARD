# PIA Navigation Map — pages to packs

What a PeopleSoft page corresponds to in the extract kit, so a screenshot can be read into the same field names, landed in the same record types, and later replaced by the extract without rework. Paths are the classic menu on PeopleTools 8.5x with 9.2 applications. On Fluid, open NavBar > Menu and follow the same folder names, or search the page name. If a path does not match your release, the component behind it is stable across releases even when the folder is not — search PeopleTools > Portal > Structure and Content for the table's component.

## Capture conventions

- **Breadcrumb visible, always.** It is the provenance.
- **Search page, no criteria, results grid.** The header reads "First 1–100 of *M*". *M* is the table's row count for that SETID or business unit, at census confidence. Capture it even when the rows do not matter.
- **Effective-dated pages:** tick "Include History" and say so; otherwise you are seeing current rows only.
- **One SETID or business unit per screenshot**, and note which. Setup pages show a SETID selector or a BU field near the top.
- **Redact user IDs and names** on Process Monitor, Role Members and User Profile pages before the image leaves the program team. Same Internal Restricted rule as P3i / P4.
- **File name:** `<INSTANCE>_SHOT_<area>_<YYYY-MM-DD>_<n>.png`. Beside the images, a `shots_manifest.csv`: `file | nav_path | table | setid_or_bu | include_history | captured_by | captured_at | redacted`. It is the screenshot cousin of `manifest.csv`.

## Do not capture

- Any employee, applicant or student detail page — Job Data, Personal Data, Student Records, Paysheets, pay calculation results. Person data.
- Suppliers > Supplier Information (bank and tax tabs); Banking > Banks and Branches > External Accounts. Account numbers.
- PeopleTools > Utilities > Administration > URLs. May embed credentials in URL strings.
- Sign-on, password and security-token pages; User Profile password tabs.

If a screenshot arrives showing any of these, do not read values from it; say so, and ask for the setup page instead.

## PeopleTools — every instance

| Page (classic path) | What it shows | Table(s) | Pack / kit § | Capture tip |
|---|---|---|---|---|
| PeopleTools > Utilities > Administration > PeopleTools Options | Base language, multi-currency, general options | PSOPTIONS | P0 `00` §0.1 | Whole page |
| Help > About (top-right menu) | Tools release, application release | PSSTATUS, PSRELEASE | P0 | The release strings decide which PeopleBooks apply |
| PeopleTools > Utilities > Administration > TableSet Control | For one business unit: the SETID used per record group | SET_CNTRL_REC, SET_CNTRL_GROUP | P3 `03` §3.0b — first-read | One capture per business unit, Record Group tab. This is the SETID map |
| PeopleTools > Utilities > Administration > TableSet IDs | All SETIDs | SETID_TBL | P3 | Search, no criteria; capture "of *M*" |
| PeopleTools > Utilities > Administration > Record Group | Record groups and their records | REC_GROUP_TBL, REC_GROUP_REC | P3 | Only when TableSet Control raises a question |
| PeopleTools > Security > Permissions & Roles > Roles | Role list; per role: Permission Lists tab, Members tab | PSROLEDEFN, PSROLECLASS, PSROLEUSER | P3i `03i` | Search, no criteria → "of *M*" = role count. Members tab header = users per role. **Members show user IDs — redact** |
| PeopleTools > Security > Permissions & Roles > Permission Lists | Per list: Pages tab (menu → component → page access), Process tab, Query tab, Sign-on Times | PSCLASSDEFN, PSAUTHITEM, PSAUTHPRCS | P3i `03i` §3i.3 | The Pages tab is the access matrix by hand. Capture only for the lists the question is about; the extract gives the rest |
| PeopleTools > Security > User Profiles > User Profiles | Per user: General, ID, Roles | PSOPRDEFN, PSROLEUSER | P3i | **Internal Restricted.** Only for a named investigation; never for inventory |
| PeopleTools > Portal > Structure and Content | The navigation tree, folder by folder | PSPRSMDEFN | P1 `01` §1.5 | Capture only to confirm a breadcrumb; the extract holds the tree |
| PeopleTools > Process Scheduler > Processes | Process definitions and type (SQR, App Engine, nVision, XML Publisher, COBOL) | PSPRCSDEFN | P2 `02` | Search, no criteria → "of *M*". Filter by Process Type for the engine split |
| PeopleTools > Process Scheduler > Jobs | Job definitions and their steps | PSJOBDEFN, PSPRCSJOBITEM | P2 | — |
| PeopleTools > Process Scheduler > Recurrences | Schedules | PSRECURDEFN | P2 | Scheduled versus ad hoc |
| PeopleTools > Process Scheduler > Process Monitor | Run history | PSPRCSRQST | P4 `04` | **Date-window it** (Last *N* days), capture the window and "of *M*", sort by Process Name. Crop or blur the User column. The only screenshot route to usage — and still a sample |
| PeopleTools > Process Scheduler > System Settings | Retention / purge settings | PSPRCSSYSTEM | P0 `00` §0.7 | How long usage history survives |
| Reporting Tools > Query > Query Manager | Query list; owner (public/private); last updated | PSQRYDEFN | P2 `02` | Search, no criteria → "of *M*" — for what *your* permissions can see; say so. Sort by Last Updated |
| Reporting Tools > BI Publisher > Report Definition | BI Publisher report definitions | PSXPRPTDEFN | P2b `02b` | — |
| Reporting Tools > PS/nVision > Define Report Request | nVision report requests | PS_NVS_REPORT | P2b | — |
| Enterprise Components > Approvals > Approvals > Transaction Registry | Which transactions use Approval Framework | PS_EOAW_TXN | P2c `02c` | "of *M*" = registered transactions |
| Enterprise Components > Approvals > Approvals > Approval Process Setup | Per process: stages, paths, steps, criteria | PS_EOAW_PRCS, PS_EOAW_STAGE, PS_EOAW_PATH, PS_EOAW_STEP | P2c | One process at a time; each stage, path and step page |
| Enterprise Components > Approvals > Approvals > User List Definition | Approver user lists | PS_EOAW_USER_LIST | P2c | May show user IDs — redact |
| PeopleTools > Integration Broker > Integration Setup > Nodes | Connected systems | PSNODEDEFN | P2d `02d` | "of *M*" = node count. Every node is a system that talks to PeopleSoft |
| PeopleTools > Integration Broker > Integration Setup > Service Operations | Operations and active flag | PSOPERATION | P2d | Filter Active |
| PeopleTools > Integration Broker > Integration Setup > Routings | Routings per operation | PSROUTINGDEFN | P2d | — |
| PeopleTools > Integration Broker > Service Operations Monitor > Monitoring > Asynchronous Services | Message traffic | PSAPMSG* | P4 / P2d | Date-window; capture counts by operation |

## HCM — Set Up HCM

| Page (classic path) | What it shows | Table(s) | Pack / kit § | Capture tip |
|---|---|---|---|---|
| Set Up HCM > Install > Installation Table | Which HCM products are installed | PS_INSTALLATION, PS_INSTALLATION_HR / _PY / _BN / _TL | P0 `00` §0.2 | Every tab. This is scope |
| Set Up HCM > Foundation Tables > Organization > Business Unit | HR business units | PS_BUS_UNIT_TBL_HR | P3 `03a` | — |
| Set Up HCM > Foundation Tables > Organization > Company | Companies | PS_COMPANY_TBL | P3 `03a` | — |
| Set Up HCM > Foundation Tables > Organization > Departments | Departments — SETID-keyed, effective-dated | PS_DEPT_TBL | P3 `03a` | Search, no criteria, per SETID → "of *M*"; Include History |
| Set Up HCM > Foundation Tables > Organization > Location | Locations | PS_LOCATION_TBL | P3 `03a` | — |
| Set Up HCM > Foundation Tables > Job Attributes > Job Code Table | Job codes | PS_JOBCODE_TBL | P3 `03a` | "of *M*" per SETID |
| Organizational Development > Position Management > Maintain Positions/Budgets > Add/Update Position Info | Positions | PS_POSITION_DATA | P3 `03a` | Detail pages show the incumbent's EMPLID and name — crop to the position fields, or use the search grid |
| Set Up HCM > Product Related > Workforce Administration > Actions, and Action Reasons | Actions and their reasons | PS_ACTION_TBL, PS_ACTN_REASON_TBL | P3 `03a` | The action/reason list is what process maps branch on |
| Set Up HCM > Product Related > Compensation > Base Compensation > Salary Plan, Grades, Steps | Compensation framework | PS_SAL_PLAN_TBL, PS_SAL_GRADE_TBL, PS_SAL_STEP_TBL | P3 `03a` | — |
| Set Up HCM > Product Related > Payroll for North America > Payroll Processing Controls > Pay Group Table | Pay groups | PS_PAYGROUP_TBL | P3 `03b` | — |
| Set Up HCM > Product Related > Payroll for North America > Compensation and Earnings > Earnings Table | Earnings codes | PS_EARNINGS_TBL | P3 `03b` | "of *M*"; Include History |
| Set Up HCM > Product Related > Payroll for North America > Deductions > Deduction Table | Deduction codes | PS_DEDUCTION_TBL | P3 `03b` | — |
| Set Up HCM > Common Definitions > ChartField Configuration > Account Code Table — search the menu for "Account Code Table" if your path differs | Payroll → GL account codes | PS_ACCT_CD_TBL | P3 `03b` §3b.2 — first-read | The HR/Finance contract. Capture the full list |
| Set Up HCM > Product Related > Base Benefits > Plans and Providers > Benefit Plan Table | Benefit plans | PS_BENEF_PLAN_TBL | P3 `03c` | — |
| Set Up HCM > Product Related > Time and Labor > Time Reporting > Time Reporting Codes | TRCs | PS_TL_TRC_TBL | P3 `03c` | — |
| Set Up HCM > Product Related > Global Payroll & Absence Mgmt > Elements > Absence Elements | Absence takes and entitlements | Absence element tables `03c` selects | P3 `03c` | Only if the Installation Table shows Absence Management installed |

## FSCM — Set Up Financials/Supply Chain

| Page (classic path) | What it shows | Table(s) | Pack / kit § | Capture tip |
|---|---|---|---|---|
| Set Up Financials/Supply Chain > Install > Installation Options | Installed FSCM products and options | PS_INSTALLATION_FS and per-product | P0 `00` §0.2 | Every tab |
| Set Up Financials/Supply Chain > Business Unit Related > General Ledger > General Ledger Definition | GL business units, ledger groups | PS_BUS_UNIT_TBL_GL, PS_BUS_UNIT_LED | P3 `03d` | Definition and Ledgers For A Unit tabs |
| Set Up Financials/Supply Chain > Common Definitions > Design ChartFields > Define Values > ChartField Values | Account, Department, Fund, Program, Class, Operating Unit, Project… | PS_GL_ACCOUNT_TBL, PS_DEPT_TBL (FSCM), PS_FUND_TBL, PS_PROGRAM_TBL, PS_CLASS_CF_TBL, PS_OPER_UNIT_TBL, PS_PROJECT | P3 `03d` | One list page per chartfield, no criteria → "of *M*" per SETID. That is the chart-of-accounts size |
| Set Up Financials/Supply Chain > Common Definitions > Design ChartFields > Configure > Standard Configuration | Which chartfields are active, and their labels | ChartField configuration | P3 `03d` | One page |
| General Ledger > Ledgers > Ledger Templates; Detail Ledgers; Ledger Groups | Ledger structure | PS_LEDGER_TMPLT, PS_LED_DEFN_TBL, PS_LED_GRP_TBL | P3 `03d` | — |
| Set Up Financials/Supply Chain > Common Definitions > Calendars/Schedules > Detail Calendar | Accounting periods | PS_CAL_DETP_TBL | P3 `03d` | — |
| Set Up Financials/Supply Chain > Common Definitions > Journals > Sources | Journal sources | PS_SOURCE_TBL | P3 `03d` — first-read for integration-discovery | Every source is a feeder system. Capture the full list |
| Commitment Control > Define Control Budgets > Budget Definitions | Control budget profile: ledger group, ruleset, keys, tolerance | PS_KK_BUDGET_TYPE and the other `PS_KK_%` definition tables `03g` selects | P3 `03g` §3g.2 — first-read | Every tab, per budget definition |
| Set Up Financials/Supply Chain > Common Definitions > Design ChartFields > Combination Editing > Combination Rule; Combination Group | Combination edit rules | PS_COMBO_RULE_TBL, PS_COMBO_GROUP_TBL | P3 `03g` | — |
| Set Up Financials/Supply Chain > Business Unit Related > Purchasing / Payables / Receivables / Billing > … Definition | Per-product business unit options | PS_BUS_UNIT_TBL_PM, _AP, _AR, _BI | P3 `03e` | Definition pages only |
| Set Up Financials/Supply Chain > Business Unit Related > Asset Management / Project Costing > … Definition | AM and PC business unit options | PS_BUS_UNIT_TBL_AM, _PC | P3 `03f` | — |
| Set Up Financials/Supply Chain > Product Related > Asset Management > Profiles > Asset Profiles | Asset profiles | PS_PROFILE_TBL | P3 `03f` | — |
| Set Up Financials/Supply Chain > Product Related > Grants > Facilities and Administration — search the menu for "F&A" if your path differs | F&A rate setup | Grants F&A rate tables `03f` selects | P3 `03f` | — |
| Set Up Financials/Supply Chain > Product Related > Expenses > Management > Expense Types | Expense types | PS_EX_TYPE_TBL | P3 `03f` | — |

## Campus Solutions — Set Up SACR

| Page (classic path) | What it shows | Table(s) | Pack / kit § | Capture tip |
|---|---|---|---|---|
| Set Up SACR > Foundation Tables > Academic Structure > Academic Institution Table; Academic Organization Table | Institutions; academic organizations | PS_INSTITUTION_TBL, PS_ACAD_ORG_TBL | P3 `03h` | Academic org ↔ HR department is a first-read crosswalk |
| Set Up SACR > Foundation Tables > Term Setup > Term/Session Table | Terms and sessions | PS_TERM_TBL | P3 `03h` | — |
| Set Up SACR > Product Related > Student Financials > Item Types > Item Types (GL Interface tab) | Student Financials item types → GL | PS_ITEM_TYPE_TBL | P3 `03h` | The SF → GL crosswalk. Capture the GL Interface tab |
| Set Up SACR > Common Definitions > Service Indicators > Service Indicator Table | Service indicators | PS_SRVC_IND_CD_TBL | P3 `03h` | — |

## Not in the web pages — Application Designer (Windows client)

| Where | What it produces | Pack | Note |
|---|---|---|---|
| Tools > Compare and Report, against DEMO, by object type | The authoritative customization report | P5 `_P5_APPDESIGNER_COMPARE.csv` | App Admin produces it. No screenshot substitute — the P5 SQL sweep is the approximation until this lands |
| Project definitions | Migration history — what was deliberately moved, and when | P5 PSPROJECTDEFN / PSPROJECTITEM | The SQL extract covers this |

## Reading a screenshot into a record

Whatever the page, the row you produce carries: `source=SCREENSHOT`, `nav_path`, `table`, `setid_or_bu`, `captured_at`, `captured_by`, `include_history`, the value fields named as the table names them, and `row_count_on_page` when a search header was visible. Land it per `../../../references/output-conventions.md`. When the extract for the same table arrives, the extract row supersedes the screenshot row; keep the screenshot as the citation that prompted the question.
